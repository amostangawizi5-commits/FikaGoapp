// ============================================================
// FIKAGO - CHECKOUT SCREEN (Professional & Multi-Language)
// ============================================================
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
  const CheckoutScreen({super.key});

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
      if (city.isNotEmpty && !address.toLowerCase().contains(city.toLowerCase()))
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
          latitude: location.latitude,
          longitude: location.longitude,
        );
  }

  Future<void> _showLocationSearch() async {
    final searchController = TextEditingController();
    List<LocationSearchResult> results = [];
    var searching = false;
    String? searchError;

    Future<void> searchLocations(
        BuildContext sheetContext, StateSetter setSheetState) async {
      final query = searchController.text.trim();
      if (searching) return;
      if (query.length < 2) {
        setSheetState(() {
          searchError = context.localized(
            'Andika angalau herufi mbili kutafuta eneo.',
            'Enter at least two characters to search.',
          );
        });
        return;
      }
      setSheetState(() {
        searching = true;
        searchError = null;
        results = [];
      });
      try {
        final found = await LocationService.search(query);
        if (!sheetContext.mounted) return;
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
        if (!sheetContext.mounted) return;
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
                  labelText: context.localized('Tafuta eneo', 'Search location'),
                  suffixIcon: IconButton(
                    icon: searching
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Icon(Icons.search),
                    onPressed: searching
                        ? null
                        : () => searchLocations(context, setSheetState),
                  ),
                ),
                onSubmitted: (_) => searchLocations(context, setSheetState),
              ),
              if (searchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    searchError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    searchController.dispose();
  }

  Future<void> _showManualPinDialog() async {
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.localized('Weka pin ya delivery', 'Place delivery pin')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: longitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
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
              final longitude = double.tryParse(longitudeController.text.trim());
              if (latitude == null || longitude == null ||
                  latitude.abs() > 90 || longitude.abs() > 180) {
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
    if (saved != true ||
        latitude == null ||
        longitude == null ||
        !mounted) {
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

    setState(() => _isLoading = true);

    final ticketItems = context
        .read<CartProvider>()
        .items
        .map((item) => {
              'name': item.name,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
            })
        .toList();
    final orderTotal = context.read<CartProvider>().totalAmount;

    // 1. Unda Oda kwenye Backend
    final orderResponse = await OrderService.createOrder(
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
    await context.read<CartProvider>().clearCart();
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
          amount: double.tryParse(createdOrder['total_amount'].toString()) ?? orderTotal,
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

    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        title: Text(
          'checkout.title'.tr(),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
                context.localized('Taarifa za mteja', 'Customer details'),
                Icons.person),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText:
                    context.localized('Jina lako kamili', 'Your full name'),
                filled: true,
                fillColor: FikaGoColors.lightGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ============================================
            // 1. DELIVERY ADDRESS
            // ============================================
            _sectionTitle('checkout.delivery_address'.tr(), Icons.location_on),
            const SizedBox(height: 8),
            if (_customerLocation != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.localized(
                      'Eneo limegunduliwa: ${_addressForLocation(_customerLocation!)}',
                      'Detected location: ${_addressForLocation(_customerLocation!)}'),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: FikaGoColors.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                hintText: 'checkout.address_hint'.tr(),
                helperText: context.localized(
                    'Unaweza kuandika eneo au kutumia GPS / utafutaji hapa chini.',
                    'Type a delivery address or use GPS/search below.'),
                filled: true,
                fillColor: FikaGoColors.lightGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showLocationSearch,
                    icon: const Icon(Icons.search),
                    label: Text(context.localized('Tafuta eneo', 'Search')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isFindingLocation ? null : _useCurrentLocation,
                    icon: _isFindingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(context.localized('GPS yangu', 'Use GPS')),
                  ),
                ),
              ],
            ),
            if (_customerLocation?.attribution != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _customerLocation!.attribution!,
                    style: GoogleFonts.montserrat(
                        fontSize: 9, color: FikaGoColors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _landmarkController,
              decoration: InputDecoration(
                hintText: 'checkout.landmark_hint'.tr(),
                filled: true,
                fillColor: FikaGoColors.lightGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // 2. PHONE NUMBER
            // ============================================
            _sectionTitle('checkout.phone'.tr(), Icons.phone),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+255 ',
                hintText: '712 345 678',
                filled: true,
                fillColor: FikaGoColors.lightGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // 3. PAYMENT METHOD
            // ============================================
            _sectionTitle('checkout.payment_method'.tr(), Icons.payment),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selectedPayment,
              onChanged: (value) {
                if (value != null) setState(() => _selectedPayment = value);
              },
              child: Column(
                children: [
                  _paymentOption('mpesa', 'M-Pesa', Icons.phone_android),
                  _paymentOption('tigopesa', 'Tigo Pesa', Icons.phone_android),
                  _paymentOption('airtel', 'Airtel Money', Icons.phone_android),
                  _paymentOption('cash', 'checkout.cash'.tr(), Icons.money),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // 4. SPECIAL INSTRUCTIONS
            // ============================================
            _sectionTitle('checkout.instructions'.tr(), Icons.note),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'checkout.instructions_hint'.tr(),
                filled: true,
                fillColor: FikaGoColors.lightGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // 5. ORDER SUMMARY
            // ============================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FikaGoColors.lightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _summaryRow('checkout.subtotal'.tr(),
                      'TZS ${cart.cart?.subtotal.toStringAsFixed(0) ?? "0"}'),
                  const SizedBox(height: 8),
                  _summaryRow('checkout.delivery_fee'.tr(),
                      'TZS ${cart.cart?.deliveryFee.toStringAsFixed(0) ?? "0"}'),
                  const SizedBox(height: 8),
                  _summaryRow('checkout.service_fee'.tr(),
                      'TZS ${cart.cart?.serviceFee.toStringAsFixed(0) ?? "0"}'),
                  const SizedBox(height: 8),
                  _summaryRow(context.localized('Punguzo', 'Discount'),
                      '- TZS ${cart.cart?.discount.toStringAsFixed(0) ?? "0"}'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('checkout.total'.tr(),
                          style: GoogleFonts.montserrat(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('TZS ${cart.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: FikaGoColors.forestGreen)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),

      // ============================================
      // BOTTOM BAR (Place Order Button)
      // ============================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FikaGoColors.lightGreen,
          boxShadow: [
            BoxShadow(
                color: FikaGoColors.charcoal.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: FikaGoColors.forestGreen,
                foregroundColor: FikaGoColors.lightGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: FikaGoColors.lightGreen, strokeWidth: 3))
                  : Text('checkout.place_order'.tr(),
                      style: GoogleFonts.montserrat(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: FikaGoColors.forestGreen, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.montserrat(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      title: Text(label, style: GoogleFonts.montserrat(fontSize: 14)),
      secondary: Icon(icon, color: FikaGoColors.forestGreen),
      activeColor: FikaGoColors.forestGreen,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 14, color: FikaGoColors.charcoal)),
        Text(value,
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
