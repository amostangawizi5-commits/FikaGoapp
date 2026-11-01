import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/vendor_service.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _loadOrders(showLoader: false));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);
    final response = await VendorService.getOrders();
    if (!mounted) return;
    setState(() {
      _orders = response['success'] == true
          ? (response['data'] as List)
              .map((order) => Map<String, dynamic>.from(order))
              .toList()
          : [];
      _isLoading = false;
    });
    if (response['success'] != true) {
      _showMessage(response['message'] ?? 'Could not load orders.');
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final id = int.tryParse(order['id'].toString());
    if (id == null) return;
    final minutesController = TextEditingController(text: '20');
    final minutes = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(context.localized('Kubali oda', 'Accept order')),
              content: TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: context.localized(
                          'Muda wa maandalizi (dakika)',
                          'Preparation time (minutes)'))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.localized('Ghairi', 'Cancel'))),
                TextButton(
                    onPressed: () {
                      final value = int.tryParse(minutesController.text);
                      if (value != null && value >= 5 && value <= 180) {
                        Navigator.pop(ctx, value);
                      }
                    },
                    child: Text(context.localized('Kubali', 'Accept'))),
              ],
            ));
    minutesController.dispose();
    if (minutes == null) return;
    final response =
        await VendorService.acceptOrder(id, preparationTimeMinutes: minutes);
    if (!mounted) return;
    _showMessage(response['success'] == true
        ? context.localized('Oda ${order['order_number']} imekubaliwa.',
            'Order ${order['order_number']} accepted.')
        : response['message'] ??
            context.localized(
                'Imeshindwa kukubali oda.', 'Could not accept order.'));
    if (response['success'] == true) await _loadOrders();
  }

  Future<void> _rejectOrder(Map<String, dynamic> order) async {
    final id = int.tryParse(order['id'].toString());
    if (id == null) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(context.localized('Kataa oda?', 'Reject order?')),
              content: TextField(
                  controller: controller,
                  maxLines: 2,
                  decoration: InputDecoration(
                      labelText: context.localized(
                          'Sababu (hiari)', 'Reason (optional)'))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.localized('Rudi', 'Keep order'))),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    child: Text(context.localized('Kataa oda', 'Reject')))
              ],
            ));
    controller.dispose();
    if (reason == null) return;
    final response = await VendorService.rejectOrder(id, reason: reason);
    if (!mounted) return;
    _showMessage(response['success'] == true
        ? context.localized('Oda imekataliwa.', 'Order rejected.')
        : response['message'] ??
            context.localized(
                'Imeshindwa kukataa oda.', 'Could not reject order.'));
    if (response['success'] == true) await _loadOrders();
  }

  Future<void> _setOrderStatus(
      Map<String, dynamic> order, String status) async {
    final id = int.tryParse(order['id'].toString());
    if (id == null) return;
    final response = await VendorService.updateOrderStatus(id, status);
    if (!mounted) return;
    _showMessage(response['success'] == true
        ? context.localized('Status imesasishwa.', 'Order status updated.')
        : response['message'] ??
            context.localized(
                'Imeshindwa kusasisha status.', 'Could not update status.'));
    if (response['success'] == true) await _loadOrders();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        _orders.where((order) => order['status'] == 'pending').toList();
    final preparing = _orders
        .where((order) => [
              'confirmed',
              'preparing',
              'ready',
              'rider_assigned',
              'picked_up',
              'on_the_way',
            ].contains(order['status']))
        .toList();
    final history = _orders
        .where((order) =>
            ['delivered', 'rejected', 'cancelled'].contains(order['status']))
        .toList();

    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/images/fikaGO.png', height: 35),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: FikaGoColors.forestGreen,
          unselectedLabelColor: FikaGoColors.charcoal,
          indicatorColor: FikaGoColors.forestGreen,
          labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: context.localized('Oda mpya', 'New orders')),
            Tab(text: context.localized('Zinazoendelea', 'In progress')),
            Tab(text: context.localized('Historia', 'History')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ordersList(pending, isNew: true),
                _ordersList(preparing, isNew: false),
                _ordersList(history, isNew: false),
              ],
            ),
    );
  }

  Widget _ordersList(List<Map<String, dynamic>> orders, {required bool isNew}) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          children: [
            const SizedBox(height: 160),
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: FikaGoColors.forestGreen),
            const SizedBox(height: 12),
            Center(
                child: Text(context.localized(
                    'Hakuna oda kwa sasa.', 'No orders here yet.'))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _orderCard(orders[index], isNew),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order, bool isNew) {
    final rawItems = (order['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final total = double.tryParse(order['total_amount'].toString()) ?? 0;
    final orderNumber = order['order_number']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FikaGoColors.lightGreen,
        borderRadius: BorderRadius.circular(20),
        border:
            isNew ? Border.all(color: FikaGoColors.sunYellow, width: 2) : null,
        boxShadow: [
          BoxShadow(
              color: FikaGoColors.charcoal.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(orderNumber,
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(_statusLabel(context, order['status']?.toString() ?? ''),
                    style: GoogleFonts.montserrat(
                        color: isNew
                            ? FikaGoColors.sunYellow
                            : FikaGoColors.forestGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _detail(
                Icons.person, order['customer_name']?.toString() ?? 'Customer'),
            _detail(Icons.phone, order['customer_phone']?.toString() ?? ''),
            _detail(Icons.location_on,
                order['delivery_address']?.toString() ?? 'Pickup'),
            if (order['preparation_time_minutes'] != null)
              _detail(Icons.timer_outlined,
                  '${order['preparation_time_minutes']} ${context.localized('dakika za maandalizi', 'minutes prep time')}'),
            const Divider(height: 24),
            ...rawItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu,
                          size: 16, color: FikaGoColors.forestGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            '${item['quantity']}× ${item['name'] ?? item['item_name']}',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${context.localized('Jumla', 'Total')}: TZS ${total.toStringAsFixed(0)}',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: FikaGoColors.forestGreen,
                        fontSize: 15)),
                if (isNew) ...[
                  TextButton(
                      onPressed: () => _rejectOrder(order),
                      child: Text(context.localized('Kataa', 'Reject'),
                          style: const TextStyle(color: Colors.redAccent))),
                  ElevatedButton(
                      onPressed: () => _acceptOrder(order),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: FikaGoColors.forestGreen,
                          foregroundColor: Colors.white),
                      child: Text(context.localized('Kubali', 'Accept'),
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                ] else if (order['status'] == 'confirmed')
                  ElevatedButton(
                      onPressed: () => _setOrderStatus(order, 'preparing'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: FikaGoColors.forestGreen,
                          foregroundColor: Colors.white),
                      child: Text(
                          context.localized('Anza kupika', 'Start preparing')))
                else if (order['status'] == 'preparing')
                  ElevatedButton(
                      onPressed: () => _setOrderStatus(order, 'ready'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: FikaGoColors.sunYellow,
                          foregroundColor: FikaGoColors.charcoal),
                      child: Text(
                          context.localized('Tayari kwa pickup', 'Mark ready')))
                else if (order['status'] == 'ready')
                  Text(
                      context.localized('Inasubiri rider', 'Waiting for rider'),
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600, fontSize: 12))
                else if (order['status'] == 'rider_assigned')
                  Text(
                      context.localized(
                          'Rider amekubali; inasubiri afike kuchukua oda.',
                          'Rider accepted; waiting for pickup.'),
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600, fontSize: 12))
                else if (['picked_up', 'on_the_way'].contains(order['status']))
                  Text(
                      context.localized('Rider yuko njiani kwa mteja.',
                          'Rider is on the way to the customer.'),
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: FikaGoColors.forestGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: FikaGoColors.charcoal)),
            ),
          ],
        ),
      );

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return context.localized('INASUBIRI', 'PENDING');
      case 'rider_assigned':
        return context.localized('RIDER AMEJIPANGA · SUBIRI UHAKIKI',
            'RIDER ASSIGNED · AWAITING REVIEW');
      case 'confirmed':
        return context.localized('IMEKUBALIWA', 'CONFIRMED');
      case 'preparing':
        return context.localized('INAPANGWA', 'PREPARING');
      case 'ready':
        return context.localized('IKO TAYARI', 'READY');
      case 'rejected':
        return context.localized('IMEKATALIWA', 'REJECTED');
      case 'delivered':
        return context.localized('IMEFIKISHWA', 'DELIVERED');
      default:
        return status.toUpperCase();
    }
  }
}
