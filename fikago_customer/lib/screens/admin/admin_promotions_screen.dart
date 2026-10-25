import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});
  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  List<Map<String, dynamic>> _promos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await AdminService.getPromotions();
    if (!mounted) return;
    setState(() {
      _promos = result['success'] == true && result['data'] is List
          ? (result['data'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      _loading = false;
    });
    if (result['success'] != true) {
      _message(result['message']?.toString() ?? 'Could not load promotions.');
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  Future<void> _create() async {
    final code = TextEditingController();
    final value = TextEditingController();
    final minimum = TextEditingController(text: '0');
    var type = 'percentage';
    var starts = DateTime.now();
    var expiry = DateTime.now().add(const Duration(days: 7));
    final created = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                  title: Text('Create promotion',
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                  content: SizedBox(
                      width: 460,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: code,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                                labelText: 'Discount code',
                                hintText: 'FIKA20')),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration: const InputDecoration(
                                labelText: 'Discount type'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'percentage',
                                  child: Text('Percentage discount')),
                              DropdownMenuItem(
                                  value: 'fixed',
                                  child: Text('Fixed amount (TZS)')),
                              DropdownMenuItem(
                                  value: 'free_delivery',
                                  child: Text('Free delivery'))
                            ],
                            onChanged: (v) {
                              if (v != null) setDialog(() => type = v);
                            }),
                        if (type != 'free_delivery')
                          TextField(
                              controller: value,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: type == 'percentage'
                                      ? 'Discount (%)'
                                      : 'Discount amount (TZS)')),
                        TextField(
                            controller: minimum,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Minimum order (TZS)')),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _dateButton(context, 'Starts', starts,
                                  (d) => setDialog(() => starts = d))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _dateButton(context, 'Expires', expiry,
                                  (d) => setDialog(() => expiry = d)))
                        ]),
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, {
                              'code': code.text.trim(),
                              'discount_type': type,
                              'value': type == 'free_delivery'
                                  ? 0
                                  : double.tryParse(value.text) ?? 0,
                              'min_order_amount':
                                  double.tryParse(minimum.text) ?? -1,
                              'starts_at': starts.toUtc().toIso8601String(),
                              'expiry_date': expiry.toUtc().toIso8601String(),
                              'is_active': true
                            }),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: FikaGoColors.forestGreen,
                            foregroundColor: Colors.white),
                        child: const Text('Create'))
                  ],
                )));
    code.dispose();
    value.dispose();
    minimum.dispose();
    if (created == null) return;
    final result = await AdminService.createPromotion(created);
    if (!mounted) return;
    _message(result['success'] == true
        ? 'Promotion created.'
        : result['message']?.toString() ?? 'Could not create promotion.');
    if (result['success'] == true) _load();
  }

  Widget _dateButton(BuildContext context, String label, DateTime value,
          ValueChanged<DateTime> set) =>
      OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 730)));
            if (d != null) {
              set(DateTime(d.year, d.month, d.day, value.hour, value.minute));
            }
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(
              '$label: ${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
              overflow: TextOverflow.ellipsis));

  Future<void> _setActive(Map<String, dynamic> promo, bool active) async {
    final id = int.tryParse(promo['id'].toString());
    if (id == null) return;
    final result = await AdminService.updatePromotion(id, active);
    if (!mounted) return;
    _message(result['success'] == true
        ? 'Promotion status updated.'
        : result['message']?.toString() ?? 'Update failed.');
    if (result['success'] == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> promo) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Delete promotion?'),
                content: Text('Delete ${promo['code']}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.redAccent)))
                ]));
    if (yes != true) return;
    final result =
        await AdminService.deletePromotion(int.parse(promo['id'].toString()));
    if (!mounted) return;
    _message(result['success'] == true
        ? 'Promotion deleted.'
        : result['message']?.toString() ?? 'Delete failed.');
    if (result['success'] == true) _load();
  }

  String _discount(Map<String, dynamic> item) =>
      switch ((item['discount_type'] ?? item['type']).toString()) {
        'percentage' => '${item['value']}% off',
        'fixed' => 'TZS ${item['value']} off',
        'free_delivery' => 'Free delivery',
        _ => item['type'].toString()
      };
  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    return d == null
        ? '—'
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      appBar: AppBar(
          title: Text('Promotions',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: FikaGoColors.charcoal,
          elevation: 0,
          actions: [
            IconButton(
                onPressed: _create,
                icon: const Icon(Icons.add_circle_outline,
                    color: FikaGoColors.forestGreen),
                tooltip: 'Create promotion')
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _promos.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 150),
                      Icon(Icons.local_offer_outlined, size: 48),
                      Center(child: Text('No promotions yet'))
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _promos.length,
                      itemBuilder: (_, i) => _card(_promos[i]))));

  Widget _card(Map<String, dynamic> promo) {
    final active = promo['is_active'] == true;
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: active
                          ? FikaGoColors.lightGreen
                          : Colors.grey.shade100,
                      shape: BoxShape.circle),
                  child: Icon(Icons.sell_outlined,
                      color: active ? FikaGoColors.forestGreen : Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(promo['code']?.toString() ?? '',
                        style: GoogleFonts.montserrat(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(_discount(promo),
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            color: FikaGoColors.forestGreen)),
                    Text(
                        'Minimum TZS ${promo['min_order_amount'] ?? 0} · ${_date(promo['starts_at'])} → ${_date(promo['expiry_date'])}',
                        style: GoogleFonts.montserrat(
                            fontSize: 10, color: FikaGoColors.grey))
                  ])),
              Switch(
                  value: active,
                  activeThumbColor: FikaGoColors.forestGreen,
                  onChanged: (v) => _setActive(promo, v)),
              PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') _delete(promo);
                  },
                  itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete'))
                      ])
            ])));
  }
}
