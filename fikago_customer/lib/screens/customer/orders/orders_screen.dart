import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../services/order_service.dart';
import 'order_ticket_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final response = await OrderService.getMyOrders();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message'] ??
                context.localized(
                    'Imeshindwa kupata oda.', 'Could not load orders.'))),
      );
    }
  }

  Future<void> _reportIssue(Map<String, dynamic> order) async {
    final orderId = int.tryParse(order['id'].toString());
    if (orderId == null) return;
    final subject = TextEditingController();
    final description = TextEditingController();
    final submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title:
                  Text(context.localized('Ripoti tatizo', 'Report an issue')),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: subject,
                    decoration: InputDecoration(
                        labelText: context.localized('Kichwa', 'Subject'))),
                const SizedBox(height: 10),
                TextField(
                    controller: description,
                    maxLines: 4,
                    decoration: InputDecoration(
                        labelText: context.localized(
                            'Maelezo', 'Describe the issue'))),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(context.localized('Ghairi', 'Cancel'))),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(context.localized('Tuma', 'Submit')))
              ],
            ));
    if (submitted != true) {
      subject.dispose();
      description.dispose();
      return;
    }
    final result = await OrderService.createComplaint(
        orderId: orderId,
        subject: subject.text.trim(),
        description: description.text.trim());
    subject.dispose();
    description.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true
            ? context.localized(
                'Malalamiko yametumwa.', 'Your complaint was sent.')
            : result['message']?.toString() ??
                context.localized('Imeshindwa kutuma malalamiko.',
                    'Could not send complaint.'))));
  }

  @override
  Widget build(BuildContext context) {
    final active = _orders
        .where((order) =>
            !['delivered', 'cancelled', 'rejected'].contains(order['status']))
        .toList();
    final history = _orders
        .where((order) =>
            ['delivered', 'cancelled', 'rejected'].contains(order['status']))
        .toList();

    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        title: Text(
          context.localized('Oda Zangu', 'My Orders'),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
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
            Tab(text: context.localized('Zinaendelea', 'Active')),
            Tab(text: context.localized('Historia', 'History')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _orderList(active),
                _orderList(history),
              ],
            ),
    );
  }

  Widget _orderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          children: [
            const SizedBox(height: 150),
            const Icon(Icons.receipt_long_outlined,
                size: 52, color: FikaGoColors.forestGreen),
            const SizedBox(height: 12),
            Center(
                child: Text(
                    context.localized('Bado huna oda.', 'No orders yet.'))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _orderCard(orders[index]),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final orderNumber = order['order_number']?.toString() ?? '';
    final restaurant = order['restaurant_name']?.toString() ?? 'FikaGo';
    final status = order['status']?.toString() ?? 'pending';
    final amount = double.tryParse(order['total_amount'].toString()) ?? 0;
    final items = (order['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                ),
                Text(status.toUpperCase(),
                    style: GoogleFonts.montserrat(
                        color: FikaGoColors.forestGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(restaurant,
                style: GoogleFonts.montserrat(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('TZS ${amount.toStringAsFixed(0)}',
                style: GoogleFonts.montserrat(
                    color: FikaGoColors.forestGreen,
                    fontWeight: FontWeight.bold)),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                  onPressed: () => _reportIssue(order),
                  icon: const Icon(Icons.support_agent_outlined),
                  label: Text(context.localized('Tatizo?', 'Report issue'))),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTicketScreen(
                      orderNumber: orderNumber,
                      customerName: order['customer_name']?.toString() ?? '',
                      customerPhone: order['customer_phone']?.toString() ?? '',
                      deliveryAddress:
                          order['delivery_address']?.toString() ?? '',
                      amount: amount,
                      items: items,
                      deliveryLandmark:
                          order['delivery_landmark']?.toString(),
                      specialInstructions:
                          order['special_instructions']?.toString(),
                      paymentMethod: order['payment_method']?.toString(),
                      subtotal: double.tryParse(order['subtotal'].toString()),
                      deliveryFee:
                          double.tryParse(order['delivery_fee'].toString()),
                      serviceFee:
                          double.tryParse(order['service_fee'].toString()),
                      discount:
                          double.tryParse(order['discount'].toString()),
                    ),
                  ),
                ),
                icon: const Icon(Icons.download_outlined),
                label: Text(context.localized('Tiketi', 'View ticket')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
