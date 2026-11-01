import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int? orderId;
  final String orderNumber;
  final String currentStatus;
  final ValueChanged<int>? onNavigateToTab;

  const OrderTrackingScreen({
    super.key,
    this.orderId,
    required this.orderNumber,
    this.currentStatus = 'pending',
    this.onNavigateToTab,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _refreshTimer;
  Map<String, dynamic> _order = {};
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isSubmittingSupport = false;
  bool _isConfirmingDelivery = false;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _refreshOrder();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshOrder(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshOrder({bool showLoading = true}) async {
    final orderId = widget.orderId;
    if (orderId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      final response = await OrderService.getOrder(orderId);
      if (!mounted) return;
      if (response['success'] == true && response['data'] is Map) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        setState(() {
          _order = data['order'] is Map
              ? Map<String, dynamic>.from(data['order'] as Map)
              : {};
          _items = (data['items'] as List? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _hasReviewed = _order['customer_rating'] != null;
          _history = (data['status_history'] as List? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList();
          _isLoading = false;
        });
        if (['delivered', 'cancelled', 'rejected']
            .contains(_order['status']?.toString())) {
          _refreshTimer?.cancel();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _status =>
      (_order['status']?.toString() ?? widget.currentStatus).toLowerCase();

  int get _progressIndex {
    switch (_status) {
      case 'confirmed':
        return 0;
      case 'preparing':
      case 'ready':
      case 'rider_assigned':
        return 1;
      case 'picked_up':
      case 'on_the_way':
        return 2;
      case 'delivered':
        return 3;
      default:
        return -1;
    }
  }

  String _statusTitle(BuildContext context) {
    switch (_status) {
      case 'delivered':
        return context.localized(
            'Imefika! Chakula kiko hapa', 'Delivered! Your food is here');
      case 'picked_up':
      case 'on_the_way':
        return context.localized('Rider ameanza safari ya kukuletea oda',
            'The rider has started the trip to you');
      case 'rider_assigned':
        return context.localized('Rider ameanza safari kwenda mgahawani',
            'The rider is heading to the restaurant');
      case 'ready':
        return context.localized('Chakula kiko tayari', 'Food is ready');
      case 'preparing':
        return context.localized('Chakula kinaandaliwa', 'Preparing your food');
      case 'cancelled':
      case 'rejected':
        return context.localized('Oda imefungwa', 'Order closed');
      default:
        return context.localized('Oda imepokelewa', 'Order received');
    }
  }

  String _statusSubtitle(BuildContext context) {
    switch (_status) {
      case 'delivered':
        return context.localized('Oda imewasili salama kwenye eneo lako.',
            'Your order has arrived at your location.');
      case 'picked_up':
      case 'on_the_way':
        return context.localized(
            'Rider amechukua oda yako na yuko njiani kukuletea.',
            'The rider picked up your order and is on the way to you.');
      case 'rider_assigned':
        return context.localized(
            'Mgahawa unasubiri rider afike kuchukua oda yako.',
            'The restaurant is waiting for the rider to pick up your order.');
      case 'cancelled':
      case 'rejected':
        return context.localized('Tazama maelezo ya oda yako hapa chini.',
            'See your order details below.');
      default:
        return context.localized('Tutakujulisha hatua inayofuata.',
            'We will update you as your order progresses.');
    }
  }

  Future<void> _confirmDelivery() async {
    final orderId = widget.orderId;
    if (orderId == null || _isConfirmingDelivery) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            context.localized('Thibitisha kupokea oda', 'Confirm receipt')),
        content: Text(context.localized(
          'Thibitisha tu ikiwa umepokea chakula chako kutoka kwa rider.',
          'Confirm only if you have received your food from the rider.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.localized('Bado', 'Not yet')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.localized('Nimepokea', 'I received it')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isConfirmingDelivery = true);
    final response = await OrderService.confirmDelivery(orderId);
    if (!mounted) return;
    setState(() => _isConfirmingDelivery = false);
    if (response['success'] == true) {
      await _refreshOrder();
      if (!mounted) return;
      _showMessage(context.localized(
        'Asante! Oda yako imekamilika.',
        'Thanks! Your order is complete.',
      ));
    } else {
      _showMessage(response['message']?.toString() ??
          context.localized(
            'Imeshindikana kuthibitisha kupokea oda.',
            'Could not confirm receipt of the order.',
          ));
    }
  }

  DateTime? _timeForStatuses(Set<String> statuses) {
    for (final entry in _history.reversed) {
      if (statuses.contains(entry['status']?.toString().toLowerCase())) {
        return DateTime.tryParse(entry['created_at']?.toString() ?? '')
            ?.toLocal();
      }
    }
    return null;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return context.localized('Inasubiri', 'Waiting');
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _openRoute() async {
    final riderLat =
        double.tryParse(_order['rider_latitude']?.toString() ?? '');
    final riderLng =
        double.tryParse(_order['rider_longitude']?.toString() ?? '');
    final destinationLat =
        double.tryParse(_order['delivery_latitude']?.toString() ?? '');
    final destinationLng =
        double.tryParse(_order['delivery_longitude']?.toString() ?? '');
    final hasRider = riderLat != null && riderLng != null;
    final hasDestination = destinationLat != null && destinationLng != null;
    if (!hasDestination) {
      _showMessage(context.localized(
        'Eneo la delivery halina GPS iliyohifadhiwa.',
        'This delivery address has no saved GPS location.',
      ));
      return;
    }
    final route = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      if (hasRider) 'origin': '$riderLat,$riderLng',
      'destination': '$destinationLat,$destinationLng',
      'travelmode': 'driving',
    });
    if (!await launchUrl(route, mode: LaunchMode.externalApplication) &&
        mounted) {
      _showMessage(context.localized(
        'Imeshindikana kufungua ramani.',
        'Could not open Maps.',
      ));
    }
  }

  Future<void> _callRider() async {
    final phone = _order['rider_phone']?.toString();
    if (phone == null || phone.isEmpty) {
      _showMessage(context.localized(
        'Namba ya rider haipatikani bado.',
        'The rider phone number is not available yet.',
      ));
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _messageRider() async {
    final phone = _order['rider_phone']?.toString();
    if (phone == null || phone.isEmpty) {
      _showMessage(context.localized(
        'Namba ya rider haipatikani bado.',
        'The rider phone number is not available yet.',
      ));
      return;
    }
    await launchUrl(Uri(scheme: 'sms', path: phone));
  }

  Future<void> _showSupportForm() async {
    if (widget.orderId == null) return;
    final subject = TextEditingController();
    final description = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.localized('Msaada wa oda', 'Order support')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: InputDecoration(
                  labelText: context.localized('Kichwa', 'Subject')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText:
                      context.localized('Maelezo', 'Describe the issue')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.localized('Ghairi', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.localized('Tuma', 'Send'))),
        ],
      ),
    );
    if (submitted != true) {
      subject.dispose();
      description.dispose();
      return;
    }
    setState(() => _isSubmittingSupport = true);
    final result = await OrderService.createComplaint(
      orderId: widget.orderId!,
      subject: subject.text.trim(),
      description: description.text.trim(),
    );
    subject.dispose();
    description.dispose();
    if (!mounted) return;
    setState(() => _isSubmittingSupport = false);
    _showMessage(result['success'] == true
        ? context.localized('Ombi lako la msaada limetumwa.',
            'Your support request has been sent.')
        : result['message']?.toString() ??
            context.localized(
                'Imeshindikana kutuma ombi.', 'Could not send your request.'));
  }

  Future<void> _showReviewForm() async {
    final orderId = widget.orderId;
    if (orderId == null || _hasReviewed) return;
    final comment = TextEditingController();
    var rating = 5;
    final selectedRating = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.localized('Kadiria oda', 'Rate your order')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setDialogState(() => rating = value),
                    icon: Icon(
                      value <= rating ? Icons.star : Icons.star_border,
                      color: FikaGoColors.sunYellow,
                      size: 30,
                    ),
                  );
                }),
              ),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: context.localized(
                        'Maoni (si lazima)', 'Comment (optional)')),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.localized('Ghairi', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, rating),
                child: Text(context.localized('Tuma', 'Submit'))),
          ],
        ),
      ),
    );
    if (selectedRating == null) {
      comment.dispose();
      return;
    }
    final response = await OrderService.createReview(
      orderId: orderId,
      rating: selectedRating,
      comment: comment.text,
    );
    comment.dispose();
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() => _hasReviewed = true);
      _showMessage(context.localized(
          'Asante kwa tathmini yako!', 'Thanks for your review!'));
    } else {
      _showMessage(response['message']?.toString() ??
          context.localized(
              'Imeshindikana kutuma tathmini.', 'Could not submit review.'));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final riderName = _order['rider_name']?.toString() ?? '';
    final vehicle = _order['vehicle_type']?.toString() ?? '';
    final plate = _order['license_plate']?.toString() ?? '';
    final riderRating =
        double.tryParse(_order['rider_rating']?.toString() ?? '');
    final riderDetails = [
      if (riderRating != null) '★ ${riderRating.toStringAsFixed(1)}',
      if (vehicle.isNotEmpty) vehicle,
      if (plate.isNotEmpty) plate,
    ].join(' • ');
    final total =
        double.tryParse(_order['total_amount']?.toString() ?? '') ?? 0;
    final paymentStatus = _order['payment_status']?.toString() ?? 'pending';
    final delivered = _status == 'delivered';
    final itemNames = _items
        .map((item) => item['item_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .take(2)
        .join(' · ');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: FikaGoColors.forestGreen,
        foregroundColor: Colors.white,
        title: Text(context.localized('Fuatilia Oda', 'Tracking Order'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: context.localized('Msaada', 'Help'),
            onPressed: _showSupportForm,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshOrder(),
        color: FikaGoColors.forestGreen,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
          children: [
            _statusBanner(context, delivered),
            if (['picked_up', 'on_the_way'].contains(_status)) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isConfirmingDelivery ? null : _confirmDelivery,
                  icon: _isConfirmingDelivery
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(context.localized(
                    'Nimepokea chakula changu',
                    'I received my food',
                  )),
                  style: FilledButton.styleFrom(
                    backgroundColor: FikaGoColors.sunYellow,
                    foregroundColor: FikaGoColors.charcoal,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _mapCard(context),
            const SizedBox(height: 10),
            _progressCard(context),
            _riderCard(context, riderName, riderDetails),
            _orderCard(context, total, paymentStatus, itemNames),
          ],
        ),
      ),
      bottomNavigationBar: widget.onNavigateToTab == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                height: 58,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(Icons.home_outlined, Icons.home,
                        context.localized('Nyumbani', 'Home'), 0),
                    _navItem(Icons.search, Icons.search,
                        context.localized('Tafuta', 'Search'), 1),
                    _navItem(Icons.receipt_long_outlined, Icons.receipt_long,
                        context.localized('Oda', 'Orders'), 2,
                        selected: true),
                    _navItem(Icons.person_outline, Icons.person,
                        context.localized('Wasifu', 'Profile'), 3),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statusBanner(BuildContext context, bool delivered) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: delivered
                ? const [Color(0xFF168B50), Color(0xFF0B6B3A)]
                : const [Color(0xFF11834A), Color(0xFF075C34)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: FikaGoColors.forestGreen.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                _status == 'cancelled' || _status == 'rejected'
                    ? Icons.close
                    : delivered
                        ? Icons.check
                        : Icons.delivery_dining,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_statusTitle(context),
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(_statusSubtitle(context),
                      style: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.93),
                          fontSize: 10)),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
          ],
        ),
      );

  Widget _mapCard(BuildContext context) {
    final riderLat = _order['rider_latitude']?.toString();
    final riderLng = _order['rider_longitude']?.toString();
    final hasRiderLocation = riderLat != null &&
        riderLng != null &&
        double.tryParse(riderLat) != null &&
        double.tryParse(riderLng) != null;
    final hasDestination = _order['delivery_latitude'] != null &&
        _order['delivery_longitude'] != null;
    final riderAssigned = _order['rider_name']?.toString().isNotEmpty == true;
    final mapStatus = _status == 'delivered'
        ? context.localized(
            'Imefikishwa · ${_formatTime(_timeForStatuses({'delivered'}))}',
            'Delivered · ${_formatTime(_timeForStatuses({'delivered'}))}',
          )
        : hasRiderLocation
            ? context.localized('Rider GPS imesasishwa', 'Rider GPS updated')
            : riderAssigned
                ? context.localized(
                    'Inasubiri GPS ya rider', 'Waiting for rider GPS')
                : context.localized('Inasubiri rider', 'Waiting for rider');
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _MapPlaceholderPainter()),
            Positioned(
              right: 10,
              top: 9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mapStatus,
                      style: GoogleFonts.montserrat(
                          fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      hasRiderLocation || _status == 'delivered'
                          ? Icons.check_circle
                          : Icons.schedule,
                      size: 13,
                      color: hasRiderLocation || _status == 'delivered'
                          ? FikaGoColors.forestGreen
                          : FikaGoColors.grey,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 37,
              top: 53,
              child: _mapMarker(
                icon: Icons.delivery_dining,
                color: FikaGoColors.forestGreen,
              ),
            ),
            Positioned(
              right: 37,
              bottom: 15,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(context.localized('Wewe', 'You'),
                        style: GoogleFonts.montserrat(
                            fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 5),
                  _mapMarker(
                    icon: Icons.person_pin_circle,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            if (hasDestination)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: _openRoute),
                ),
              ),
            if (!hasDestination)
              Positioned(
                left: 8,
                bottom: 7,
                child: Text(
                  context.localized(
                      'GPS ya anuani haipo', 'No saved address GPS'),
                  style: GoogleFonts.montserrat(
                      fontSize: 8, color: FikaGoColors.charcoal),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapMarker({required IconData icon, required Color color}) =>
      Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 21),
      );

  Widget _progressCard(BuildContext context) {
    final stages = [
      _TrackingStage(
        title: context.localized('Oda imethibitishwa', 'Order Confirmed'),
        statuses: {'confirmed'},
        note: context.localized(
            'Mgahawa umepokea oda yako', 'Restaurant accepted your order'),
      ),
      _TrackingStage(
        title: context.localized('Inaandaliwa', 'Preparing'),
        statuses: {'preparing', 'ready'},
        note: context.localized('Mgahawa unaandaa chakula',
            'The restaurant is preparing your food'),
      ),
      _TrackingStage(
        title: context.localized('Rider yuko njiani', 'Rider on the way'),
        statuses: {'picked_up', 'on_the_way'},
        note: context.localized(
            'Rider amechukua oda yako', 'Rider picked up your order'),
      ),
      _TrackingStage(
        title: context.localized('Imefikishwa', 'Delivered'),
        statuses: {'delivered'},
        note: context.localized(
            'Oda imewasili kwenye eneo lako', 'Delivered to your location'),
      ),
    ];
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.localized('Hatua za Oda', 'Order Progress'),
              style: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...List.generate(stages.length, (index) {
            final stage = stages[index];
            final complete = index <= _progressIndex;
            final time = _formatTime(_timeForStatuses(stage.statuses));
            return _timelineItem(
              title: stage.title,
              note: '$time · ${stage.note}',
              complete: complete,
              active: index == _progressIndex ||
                  (_status == 'pending' && index == 0),
              isLast: index == stages.length - 1,
            );
          }),
          if (_status == 'pending')
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 1),
              child: Text(
                context.localized('Tunasubiri mgahawa uthibitishe.',
                    'Waiting for the restaurant to confirm.'),
                style: GoogleFonts.montserrat(
                    fontSize: 9, color: FikaGoColors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required String title,
    required String note,
    required bool complete,
    required bool active,
    required bool isLast,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete ? const Color(0xFF19A35D) : Colors.white,
                    border: Border.all(
                      color: complete || active
                          ? const Color(0xFF19A35D)
                          : const Color(0xFFD5DDD8),
                      width: 2,
                    ),
                  ),
                  child: complete
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 18,
                    color: complete
                        ? const Color(0xFF19A35D)
                        : const Color(0xFFD5DDD8),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: complete || active
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: complete || active
                              ? FikaGoColors.charcoal
                              : FikaGoColors.grey)),
                  const SizedBox(height: 1),
                  Text(note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 8, color: FikaGoColors.grey)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _riderCard(
      BuildContext context, String riderName, String riderDetails) {
    if (riderName.isEmpty) {
      return _whiteCard(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 23,
              backgroundColor: FikaGoColors.lightGreen,
              child:
                  Icon(Icons.delivery_dining, color: FikaGoColors.forestGreen),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  context.localized('Rider ataonekana baada ya kupangiwa.',
                      'Rider details will show once assigned.'),
                  style: GoogleFonts.montserrat(fontSize: 10)),
            ),
          ],
        ),
      );
    }
    return _whiteCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: FikaGoColors.lightGreen,
            child: Text(
              _riderInitials(riderName),
              style: GoogleFonts.montserrat(
                color: FikaGoColors.forestGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${context.localized('Rider', 'Rider')} · $riderName',
                    style: GoogleFonts.montserrat(
                        fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  riderDetails.isEmpty
                      ? context.localized('Dereva wa FikaGo', 'FikaGo rider')
                      : riderDetails,
                  style: GoogleFonts.montserrat(
                      fontSize: 9, color: FikaGoColors.grey),
                ),
              ],
            ),
          ),
          _roundAction(Icons.phone, FikaGoColors.sunYellow, _callRider),
          const SizedBox(width: 7),
          _roundAction(
              Icons.sms_outlined, FikaGoColors.lightGrey, _messageRider),
        ],
      ),
    );
  }

  String _riderInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'FG';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Widget _orderCard(BuildContext context, double total, String paymentStatus,
          String itemNames) =>
      _whiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${_order['order_number'] ?? widget.orderNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                    'TZS ${total.toStringAsFixed(0)} · ${paymentStatus == 'released' ? context.localized('IMELIPWA', 'PAID') : paymentStatus.replaceAll('_', ' ').toUpperCase()}',
                    style: GoogleFonts.montserrat(
                        fontSize: 9,
                        color: FikaGoColors.forestGreen,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_order['restaurant_name']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 9)),
            if (itemNames.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(itemNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 9, color: FikaGoColors.grey)),
            ],
            const SizedBox(height: 7),
            if (_status == 'delivered' && !_hasReviewed)
              SizedBox(
                width: double.infinity,
                height: 30,
                child: FilledButton.icon(
                  onPressed: _showReviewForm,
                  icon: const Icon(Icons.star_outline, size: 14),
                  label: Text(
                      context.localized(
                          'Kadiria na Toa Maoni', 'Rate & Review'),
                      style: GoogleFonts.montserrat(fontSize: 9)),
                  style: FilledButton.styleFrom(
                    backgroundColor: FikaGoColors.sunYellow,
                    foregroundColor: FikaGoColors.charcoal,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7)),
                  ),
                ),
              ),
            if (_status == 'delivered' && _hasReviewed)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Center(
                  child: Text(
                      context.localized(
                          'Asante kwa tathmini yako', 'Thanks for your review'),
                      style: GoogleFonts.montserrat(
                          fontSize: 9, color: FikaGoColors.forestGreen)),
                ),
              ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: OutlinedButton(
                onPressed: _isSubmittingSupport ? null : _showSupportForm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FikaGoColors.charcoal,
                  side: const BorderSide(color: Color(0xFFD9DEDB)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7)),
                ),
                child: Text(
                    _isSubmittingSupport
                        ? context.localized('Inatuma...', 'Sending...')
                        : context.localized(
                            'Pata Msaada', 'Get Help / Support'),
                    style: GoogleFonts.montserrat(fontSize: 9)),
              ),
            ),
          ],
        ),
      );

  Widget _whiteCard({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _roundAction(IconData icon, Color color, VoidCallback onTap) =>
      Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(icon, size: 17, color: FikaGoColors.charcoal)),
        ),
      );

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index,
          {bool selected = false}) =>
      InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onNavigateToTab?.call(index);
        },
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon,
                  color:
                      selected ? FikaGoColors.forestGreen : FikaGoColors.grey,
                  size: 21),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  style: GoogleFonts.montserrat(
                      color: selected
                          ? FikaGoColors.forestGreen
                          : FikaGoColors.grey,
                      fontSize: 9,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      );
}

class _TrackingStage {
  final String title;
  final Set<String> statuses;
  final String note;

  const _TrackingStage({
    required this.title,
    required this.statuses,
    required this.note,
  });
}

class _MapPlaceholderPainter extends CustomPainter {
  const _MapPlaceholderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE8F1E8);
    canvas.drawRect(Offset.zero & size, background);

    final park = Paint()..color = const Color(0xFFC5E5B5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .69, size.height * .36, size.width * .24,
              size.height * .48),
          const Radius.circular(12)),
      park,
    );

    final block = Paint()..color = const Color(0xFFD5E3E9);
    final blocks = [
      Rect.fromLTWH(size.width * .06, size.height * .16, 42, 25),
      Rect.fromLTWH(size.width * .24, size.height * .12, 56, 30),
      Rect.fromLTWH(size.width * .46, size.height * .13, 34, 23),
      Rect.fromLTWH(size.width * .12, size.height * .59, 56, 25),
      Rect.fromLTWH(size.width * .39, size.height * .63, 42, 24),
    ];
    for (final rect in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        block,
      );
    }

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * .04, size.height * .47),
        Offset(size.width * .96, size.height * .28), road);
    canvas.drawLine(Offset(size.width * .31, size.height * .06),
        Offset(size.width * .39, size.height * .96), road);
    canvas.drawLine(Offset(size.width * .61, size.height * .05),
        Offset(size.width * .53, size.height * .94), road);
    canvas.drawLine(Offset(size.width * .02, size.height * .82),
        Offset(size.width * .97, size.height * .67), road);

    final minorRoad = Paint()
      ..color = const Color(0xFFC7D4D6)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 7), minorRoad);
    }
    for (var i = 1; i < 9; i++) {
      final x = size.width * i / 9;
      canvas.drawLine(Offset(x, 0), Offset(x - 10, size.height), minorRoad);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
