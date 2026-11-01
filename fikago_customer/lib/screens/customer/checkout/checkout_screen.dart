// ============================================================
// FIKAGO - CHECKOUT SCREEN (Professional & Multi-Language)
// ============================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/order_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/location_service.dart';
import '../../../utils/phone_number.dart';
import '../orders/order_ticket_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final int cartId;

  const CheckoutScreen({super.key, required this.cartId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedPayment = 'mpesa'; // mpesa, tigopesa, airtel, cash
  bool _isLoading = false;
  bool _isFindingLocation = false;
  CustomerLocation? _customerLocation;
  bool _manualAddressEdited = false;

  @override
  void initState() {
    super.initState();
    // Weka namba ya simu ya mtumiaji kama ipo
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?['full_name']?.toString() ?? '';
    if (user != null && user['phone_number'] != null) {
      _phoneController.text = nationalTzPhoneDigits(
        user['phone_number'].toString(),
      );
    }
    _loadCustomerLocation();
  }

  Future<void> _loadCustomerLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted || location == null || _manualAddressEdited) return;
      setState(() {
        _customerLocation = location;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = _addressForLocation(location);
        }
      });
      await _quoteForLocation(location);
    } catch (_) {
      // Keep the delivery address editable when location access is unavailable.
    }
  }

  String _addressForLocation(CustomerLocation location) {
    final address = location.address.trim();
    final city = location.city.trim();
    final parts = [
      if (address.isNotEmpty) address,
      if (city.isNotEmpty &&
          !address.toLowerCase().contains(city.toLowerCase()))
        city,
    ];
    return parts.isEmpty
        ? 'GPS pin (${location.latitude}, ${location.longitude})'
        : parts.join(', ');
  }

  Future<void> _useCurrentLocation() async {
    final addressBeforeLookup = _addressController.text;
    setState(() => _isFindingLocation = true);
    final location = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isFindingLocation = false);
    if (_addressController.text != addressBeforeLookup) return;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized(
            'Imeshindikana kupata eneo. Washa GPS na ruhusu FikaGo kutumia location.',
            'Could not get your location. Turn on GPS and allow FikaGo to access it.',
          )),
          action: SnackBarAction(
            label: context.localized('Mipangilio', 'Settings'),
            onPressed: () => LocationService.openRelevantSettings(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _customerLocation = location;
      _addressController.text = _addressForLocation(location);
      _manualAddressEdited = false;
    });
    await _quoteForLocation(location);
  }

  Future<void> _quoteForLocation(CustomerLocation location) async {
    await context.read<CartProvider>().quoteForLocation(
          cartId: widget.cartId,
          latitude: location.latitude,
          longitude: location.longitude,
        );
  }

  Future<void> _showLocationSearch() async {
    var nearbyLocation = _customerLocation;
    nearbyLocation ??= await LocationService.getCurrentLocation();
    if (!mounted) return;

    final searchController = TextEditingController();
    List<LocationSearchResult> results = [];
    var searching = false;
    String? searchError;
    Timer? searchDebounce;
    var searchRequestId = 0;

    Future<void> searchLocations(
        BuildContext sheetContext, StateSetter setSheetState) async {
      final query = searchController.text.trim();
      if (query.length < 2) {
        setSheetState(() {
          searchError = context.localized(
            'Andika angalau herufi mbili kutafuta eneo.',
            'Enter at least two characters to search.',
          );
        });
        return;
      }
      final requestId = ++searchRequestId;
      setSheetState(() {
        searching = true;
        searchError = null;
        results = [];
      });
      try {
        final found = await LocationService.search(
          query,
          near: nearbyLocation,
        );
        if (!sheetContext.mounted || requestId != searchRequestId) return;
        setSheetState(() {
          results = found;
          searching = false;
          if (found.isEmpty) {
            searchError = context.localized(
              'Hakuna eneo lililopatikana. Jaribu jina jingine au andika anwani mwenyewe.',
              'No locations found. Try another search or type the address manually.',
            );
          }
        });
      } catch (_) {
        if (!sheetContext.mounted || requestId != searchRequestId) return;
        setSheetState(() {
          searching = false;
          searchError = context.localized(
            'Utafutaji wa eneo haupatikani sasa. Andika anwani mwenyewe au jaribu tena.',
            'Location search is unavailable right now. Type the address manually or try again.',
          );
        });
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText:
                      context.localized('Tafuta eneo', 'Search location'),
                  suffixIcon: IconButton(
                    icon: searching
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Icon(Icons.search),
                    onPressed: searching
                        ? null
                        : () => searchLocations(context, setSheetState),
                  ),
                ),
                onChanged: (_) {
                  setSheetState(() {});
                  searchDebounce?.cancel();
                  if (searchController.text.trim().length < 2) {
                    searchRequestId++;
                    setSheetState(() {
                      results = [];
                      searchError = null;
                      searching = false;
                    });
                    return;
                  }
                  searchDebounce = Timer(const Duration(milliseconds: 450),
                      () => searchLocations(context, setSheetState));
                },
                onSubmitted: (_) => searchLocations(context, setSheetState),
              ),
              if (nearbyLocation != null &&
                  searchController.text.trim().isEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.my_location,
                      color: FikaGoColors.forestGreen),
                  title: Text(context.localized(
                      'Eneo ulipo sasa', 'Your current location')),
                  subtitle: Text(
                    _addressForLocation(nearbyLocation!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _customerLocation = nearbyLocation;
                      _addressController.text =
                          _addressForLocation(nearbyLocation!);
                      _manualAddressEdited = false;
                    });
                    _quoteForLocation(nearbyLocation!);
                    Navigator.pop(sheetContext);
                  },
                ),
              if (searchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    searchError!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              ...results.map(
                (result) => ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(result.address),
                  onTap: () {
                    final location = CustomerLocation(
                      latitude: result.latitude,
                      longitude: result.longitude,
                      city: '',
                      address: result.address,
                      attribution: '© OpenStreetMap contributors',
                    );
                    setState(() {
                      _customerLocation = location;
                      _addressController.text = result.address;
                      _manualAddressEdited = false;
                    });
                    _quoteForLocation(location);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showManualPinDialog();
                },
                icon: const Icon(Icons.push_pin_outlined),
                label: Text(context.localized(
                    'Weka pin kwa coordinates', 'Place pin by coordinates')),
              ),
            ],
          ),
        ),
      ),
    );
    searchDebounce?.cancel();
    searchController.dispose();
  }

  Future<void> _showManualPinDialog() async {
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            context.localized('Weka pin ya delivery', 'Place delivery pin')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.localized('Ghairi', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final latitude = double.tryParse(latitudeController.text.trim());
              final longitude =
                  double.tryParse(longitudeController.text.trim());
              if (latitude == null ||
                  longitude == null ||
                  latitude.abs() > 90 ||
                  longitude.abs() > 180) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: Text(context.localized('Tumia pin', 'Use pin')),
          ),
        ],
      ),
    );
    final latitude = double.tryParse(latitudeController.text.trim());
    final longitude = double.tryParse(longitudeController.text.trim());
    latitudeController.dispose();
    longitudeController.dispose();
    if (saved != true || latitude == null || longitude == null || !mounted) {
      return;
    }
    final location = CustomerLocation(
      latitude: latitude,
      longitude: longitude,
      city: '',
      address: 'Pinned location ($latitude, $longitude)',
    );
    setState(() {
      _customerLocation = location;
      _addressController.text = location.address;
      _manualAddressEdited = false;
    });
    await _quoteForLocation(location);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _landmarkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final address = _addressController.text.trim();
    final customerName = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (customerName.isEmpty || address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('checkout.fill_fields'.tr()),
          backgroundColor: FikaGoColors.charcoal,
        ),
      );
      return;
    }
    if (normalizeTzPhone(phone) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized(
            'Ingiza tarakimu 9 za simu baada ya +255.',
            'Enter the 9 phone digits after +255.',
          )),
          backgroundColor: FikaGoColors.charcoal,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cartProvider = context.read<CartProvider>();
    final selectedCart = cartProvider.cart;
    final ticketItems = (selectedCart?.items ?? const <dynamic>[])
        .map((item) => {
              'name': item.name,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
            })
        .toList();
    final orderTotal = selectedCart?.totalAmount ?? 0;

    // 1. Unda Oda kwenye Backend
    final orderResponse = await OrderService.createOrder(
      cartId: widget.cartId,
      customerName: customerName,
      deliveryAddress: address,
      deliveryLandmark: _landmarkController.text.trim(),
      deliveryLatitude:
          _manualAddressEdited ? null : _customerLocation?.latitude,
      deliveryLongitude:
          _manualAddressEdited ? null : _customerLocation?.longitude,
      customerPhone: phone,
      paymentMethod: _selectedPayment,
      specialInstructions: _instructionsController.text.trim(),
    );

    if (orderResponse['success'] != true) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(orderResponse['message'] ?? 'checkout.order_failed'.tr()),
          backgroundColor: FikaGoColors.charcoal,
        ),
      );
      return;
    }

    final orderId = orderResponse['data']['id'];

    // 2. Kama ni malipo ya Simu (Selcom), anzisha malipo
    if (_selectedPayment != 'cash') {
      final paymentResponse = await PaymentService.initiatePayment(
        orderId: orderId,
        paymentMethod: _selectedPayment,
      );

      if (paymentResponse['success'] != true) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                paymentResponse['message'] ?? 'checkout.payment_failed'.tr()),
            backgroundColor: FikaGoColors.charcoal,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    // 3. Futa cart na fungua ticket ya oda
    context.read<CartProvider>().removeCompletedCart(widget.cartId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('checkout.order_success'.tr()),
        backgroundColor: FikaGoColors.forestGreen,
      ),
    );

    final createdOrder = Map<String, dynamic>.from(orderResponse['data']);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTicketScreen(
          orderNumber: createdOrder['order_number']?.toString() ??
              createdOrder['id']?.toString() ??
              'FikaGo',
          customerName: customerName,
          customerPhone: phone,
          deliveryAddress: address,
          amount: double.tryParse(createdOrder['total_amount'].toString()) ??
              orderTotal,
          items: ticketItems,
          deliveryLandmark: _landmarkController.text.trim(),
          specialInstructions: _instructionsController.text.trim(),
          paymentMethod: _selectedPayment,
          subtotal: double.tryParse(createdOrder['subtotal'].toString()),
          deliveryFee: double.tryParse(createdOrder['delivery_fee'].toString()),
          serviceFee: double.tryParse(createdOrder['service_fee'].toString()),
          discount: double.tryParse(createdOrder['discount'].toString()),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final location = _customerLocation;
    final hasAddress = _addressController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        title: Text('Checkout',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: FikaGoColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: context.localized('Rudi nyuma', 'Back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            tooltip: context.localized('Msaada', 'Help'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(
                    context.localized('Msaada wa Checkout', 'Checkout help')),
                content: Text(context.localized(
                    'Thibitisha eneo na namba yako ya simu, kisha chagua njia ya malipo na tuma oda.',
                    'Confirm your delivery location and phone number, choose a payment method, then place your order.')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(context.localized('Sawa', 'Got it')),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _checkoutCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardLabel(context.localized(
                      'ANWANI YA DELIVERY', 'DELIVERY ADDRESS')),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on,
                          color: FikaGoColors.forestGreen, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasAddress
                                  ? _addressController.text.trim()
                                  : context.localized(
                                      'Eneo halijapatikana bado',
                                      'Location not found yet'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location != null
                                  ? '${location.city.isNotEmpty ? '${location.city} • ' : ''}${context.localized('Eneo lako la sasa', 'Your current location')}'
                                  : context.localized(
                                      'Tumia GPS au tafuta eneo lako',
                                      'Use GPS or search for your address'),
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, color: FikaGoColors.grey),
                            ),
                          ]),
                    ),
                    TextButton(
                      onPressed: _showLocationSearch,
                      style: TextButton.styleFrom(
                          foregroundColor: FikaGoColors.forestGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 4)),
                      child: Text(context.localized('Badili', 'Edit')),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    onChanged: (_) {
                      if (!_manualAddressEdited) {
                        setState(() {
                          _manualAddressEdited = true;
                          _customerLocation = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: context.localized('Jina la mtaa, jengo au eneo',
                          'Street, building or area'),
                      prefixIcon: const Icon(Icons.edit_location_alt_outlined,
                          size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          _isFindingLocation ? null : _useCurrentLocation,
                      icon: _isFindingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(context.localized(
                          'Tumia location yangu ya sasa',
                          'Use my current location')),
                    ),
                  ),
                  if (location?.attribution != null)
                    Text(location!.attribution!,
                        style: GoogleFonts.montserrat(
                            fontSize: 9, color: FikaGoColors.grey)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      hintText: 'checkout.landmark_hint'.tr(),
                      prefixIcon: const Icon(Icons.near_me_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _checkoutCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardLabel(context.localized(
                        'TAARIFA ZA MTEJA', 'CUSTOMER DETAILS')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                          context.localized(
                              'Jina lako kamili', 'Your full name'),
                          Icons.person_outline),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [TanzaniaPhoneInputFormatter()],
                      decoration:
                          _inputDecoration('712 345 678', Icons.phone_outlined)
                              .copyWith(prefixText: '+255  '),
                    ),
                  ]),
            ),
            const SizedBox(height: 14),
            _checkoutCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardLabel(
                        context.localized('NJIA YA MALIPO', 'PAYMENT METHOD')),
                    const SizedBox(height: 10),
                    RadioGroup<String>(
                      groupValue: _selectedPayment,
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedPayment = value);
                      },
                      child: Column(children: [
                        _paymentOption('mpesa', 'M-Pesa', Icons.phone_android),
                        _paymentOption(
                            'tigopesa', 'Tigo Pesa', Icons.phone_android),
                        _paymentOption(
                            'airtel', 'Airtel Money', Icons.phone_android),
                        _paymentOption('cash', 'checkout.cash'.tr(),
                            Icons.payments_outlined),
                      ]),
                    ),
                  ]),
            ),
            const SizedBox(height: 14),
            _checkoutCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardLabel(context.localized(
                        'MAELEKEZO MAALUM', 'SPECIAL INSTRUCTIONS')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                          'checkout.instructions_hint'.tr(),
                          Icons.sticky_note_2_outlined),
                    ),
                  ]),
            ),
            const SizedBox(height: 14),
            _checkoutCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardLabel(
                        context.localized('MUHTASARI WA ODA', 'ORDER SUMMARY')),
                    const SizedBox(height: 14),
                    _summaryRow('checkout.subtotal'.tr(),
                        'TZS ${cart.cart?.subtotal.toStringAsFixed(0) ?? "0"}'),
                    const SizedBox(height: 9),
                    _summaryRow('checkout.delivery_fee'.tr(),
                        'TZS ${cart.cart?.deliveryFee.toStringAsFixed(0) ?? "0"}'),
                    const SizedBox(height: 9),
                    _summaryRow('checkout.service_fee'.tr(),
                        'TZS ${cart.cart?.serviceFee.toStringAsFixed(0) ?? "0"}'),
                    const SizedBox(height: 9),
                    _summaryRow(context.localized('Punguzo', 'Discount'),
                        '- TZS ${cart.cart?.discount.toStringAsFixed(0) ?? "0"}'),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1)),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('checkout.total'.tr(),
                              style: GoogleFonts.montserrat(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                              'TZS ${(cart.cart?.totalAmount ?? 0).toStringAsFixed(0)}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: FikaGoColors.forestGreen)),
                        ]),
                  ]),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, -4)),
            ]),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: FikaGoColors.sunYellow,
                foregroundColor: FikaGoColors.charcoal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                          color: FikaGoColors.forestGreen, strokeWidth: 2.5))
                  : Text('checkout.place_order'.tr(),
                      style: GoogleFonts.montserrat(
                          fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkoutCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: child,
      );

  Widget _cardLabel(String label) => Text(
        label,
        style: GoogleFonts.montserrat(
            fontSize: 10,
            color: FikaGoColors.grey,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF4F6F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  // ============================================================
  // WIDGETS
  // ============================================================
  Widget _paymentOption(String value, String label, IconData icon) {
    final selected = _selectedPayment == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE4F3E9) : const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected ? FikaGoColors.forestGreen : Colors.transparent,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        title: Text(label, style: GoogleFonts.montserrat(fontSize: 13)),
        secondary: Icon(icon, color: FikaGoColors.forestGreen),
        activeColor: FikaGoColors.forestGreen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 13, color: FikaGoColors.charcoal)),
        Text(value,
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
