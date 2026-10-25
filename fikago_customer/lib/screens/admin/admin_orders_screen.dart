import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _search = TextEditingController();
  String _status = 'all';
  String _payment = 'all';
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final response = await AdminService.getOrders(
        search: _search.text.trim(), status: _status, paymentStatus: _payment);
    if (!mounted) return;
    setState(() {
      _orders = response['success'] == true && response['data'] is List
          ? (response['data'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      _loading = false;
    });
    if (response['success'] != true) {
      _message(response['message']?.toString() ?? 'Could not load orders.');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _details(Map<String, dynamic> order) async {
    final id = int.tryParse(order['id'].toString());
    if (id == null) return;
    final response = await AdminService.getOrder(id);
    if (!mounted) return;
    if (response['success'] != true) {
      _message(response['message']?.toString() ?? 'Could not load order.');
      return;
    }
    final data = Map<String, dynamic>.from(response['data']);
    final items = (data['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final history = (data['status_history'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final status = data['status']?.toString() ?? '';
    final payment = data['payment_status']?.toString() ?? '';
    final cancellable = [
      'pending',
      'confirmed',
      'preparing',
      'ready',
      'rider_assigned'
    ].contains(status);
    final refundable =
        ['delivered', 'cancelled', 'rejected'].contains(status) &&
            ['held_in_escrow', 'released'].contains(payment);
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('${data['order_number']} · ${status.toUpperCase()}',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        _line('Customer',
                            '${data['customer_name']} · ${data['customer_phone']}'),
                        _line('Restaurant',
                            '${data['restaurant_name']} · ${data['restaurant_phone']}'),
                        _line('Delivery address',
                            data['delivery_address']?.toString() ?? '—'),
                        _line(
                            'Payment', '${data['payment_method']} · $payment'),
                        _line('Total', 'TZS ${data['total_amount']}'),
                        const Divider(),
                        Text('Items',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold)),
                        ...items.map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                                '${item['quantity']} × ${item['item_name']}'),
                            subtitle: Text(
                                item['special_instructions']?.toString() ?? ''),
                            trailing: Text('TZS ${item['total_price']}'))),
                        const Divider(),
                        Text('Status history',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold)),
                        ...history.map((entry) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.circle,
                                size: 9, color: FikaGoColors.forestGreen),
                            title: Text(
                                '${entry['status']} · ${entry['changed_by'] ?? 'System'}'),
                            subtitle: Text(
                                '${entry['notes'] ?? ''} ${entry['created_at'] ?? ''}'))),
                        if ((data['refunds'] as List? ?? []).isNotEmpty) ...[
                          const Divider(),
                          Text('Refunds',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold)),
                          ...(data['refunds'] as List).map((refund) => Text(
                              'TZS ${refund['amount']} · ${refund['status']} · ${refund['reason']}')),
                        ],
                      ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close')),
                if (cancellable)
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _cancel(data);
                      },
                      child: const Text('Cancel order',
                          style: TextStyle(color: Colors.redAccent))),
                if (refundable)
                  ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _refund(data);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white),
                      child: const Text('Authorize refund')),
              ],
            ));
  }

  Widget _line(String title, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
          text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
            TextSpan(
                text: '$title: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value)
          ])));

  Future<void> _cancel(Map<String, dynamic> order) async {
    final reason =
        await _reasonDialog('Cancel order', 'Reason for cancellation');
    if (reason == null) return;
    final response = await AdminService.cancelOrder(
        int.parse(order['id'].toString()),
        reason: reason);
    if (!mounted) return;
    _message(response['success'] == true
        ? 'Order cancelled. Review it again to issue a refund if payment was captured.'
        : response['message']?.toString() ?? 'Could not cancel order.');
    if (response['success'] == true) _load();
  }

  Future<void> _refund(Map<String, dynamic> order) async {
    final reason =
        await _reasonDialog('Authorize refund', 'Refund reason (required)');
    if (reason == null || reason.trim().length < 3) return;
    final response = await AdminService.refundOrder(
        int.parse(order['id'].toString()), reason.trim());
    if (!mounted) return;
    _message(response['success'] == true
        ? 'Refund recorded: TZS ${response['data']?['amount'] ?? ''}'
        : response['message']?.toString() ?? 'Refund failed.');
    if (response['success'] == true) _load();
  }

  Future<String?> _reasonDialog(String title, String label) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(title),
                content: TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: label)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Back')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Continue'))
                ]));
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: FikaGoColors.lightGrey,
        appBar: AppBar(
            title: Text('Orders, payments & refunds',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: FikaGoColors.charcoal,
            elevation: 0),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                      hintText: 'Search order, customer, phone or restaurant',
                      prefixIcon: const Icon(Icons.search,
                          color: FikaGoColors.forestGreen),
                      suffixIcon: IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.arrow_forward)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                Expanded(
                    child: _filter('Order status', _status, [
                  'all',
                  'pending',
                  'confirmed',
                  'preparing',
                  'ready',
                  'picked_up',
                  'delivered',
                  'cancelled',
                  'rejected'
                ], (v) {
                  _status = v;
                  _load();
                })),
                const SizedBox(width: 10),
                Expanded(
                    child: _filter('Payment', _payment, [
                  'all',
                  'pending',
                  'held_in_escrow',
                  'released',
                  'refunded'
                ], (v) {
                  _payment = v;
                  _load();
                }))
              ])),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _orders.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 150),
                              Icon(Icons.receipt_long_outlined, size: 48),
                              Center(child: Text('No matching orders'))
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _orders.length,
                              itemBuilder: (_, i) => _card(_orders[i])))),
        ]),
      );

  Widget _filter(String label, String value, List<String> options,
          ValueChanged<String> change) =>
      DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none)),
          items: options
              .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v == 'all' ? 'All' : v.replaceAll('_', ' '),
                      overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) {
            if (v != null) change(v);
          });

  Widget _card(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final payStatus = order['payment_status']?.toString() ?? '';
    return Card(
        margin: const EdgeInsets.only(bottom: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => _details(order),
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                order['order_number']?.toString() ?? 'Order',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16))),
                        _pill(
                            status,
                            status == 'delivered'
                                ? FikaGoColors.forestGreen
                                : status == 'cancelled' || status == 'rejected'
                                    ? Colors.redAccent
                                    : Colors.orange)
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          '${order['customer_name']} · ${order['customer_phone']}',
                          style: GoogleFonts.montserrat(fontSize: 12)),
                      Text(order['restaurant_name']?.toString() ?? '',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: FikaGoColors.grey)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: Text('TZS ${order['total_amount']}',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: FikaGoColors.forestGreen))),
                        _pill(
                            payStatus.replaceAll('_', ' '),
                            payStatus == 'refunded'
                                ? Colors.blueGrey
                                : FikaGoColors.forestGreen)
                      ]),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                              onPressed: () => _details(order),
                              icon: const Icon(Icons.open_in_new, size: 17),
                              label: const Text('Details & actions'))),
                    ]))));
  }

  Widget _pill(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text.toUpperCase(),
          style: GoogleFonts.montserrat(
              fontSize: 9, color: color, fontWeight: FontWeight.bold)));
}
