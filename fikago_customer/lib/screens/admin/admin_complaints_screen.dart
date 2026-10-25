import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await AdminService.getComplaints(status: _filter);
    if (!mounted) return;
    setState(() {
      _items = result['success'] == true && result['data'] is List
          ? (result['data'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      _loading = false;
    });
    if (result['success'] != true) {
      _message(result['message']?.toString() ?? 'Could not load complaints.');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _review(Map<String, dynamic> complaint) async {
    final id = int.tryParse(complaint['id'].toString());
    if (id == null) return;
    final resolution =
        TextEditingController(text: complaint['resolution']?.toString() ?? '');
    final state = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(complaint['subject']?.toString() ?? 'Complaint',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Customer: ${complaint['customer_name']} · ${complaint['phone_number']}'),
                Text('Order: ${complaint['order_number'] ?? '—'}'),
                const SizedBox(height: 12),
                Text(complaint['description']?.toString() ?? ''),
                const SizedBox(height: 12),
                TextField(
                    controller: resolution,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Resolution / internal note')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, {
                    'status': 'in_review',
                    'resolution': resolution.text.trim()
                  }),
              child: const Text('Mark in review')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, {
                    'status': 'dismissed',
                    'resolution': resolution.text.trim()
                  }),
              child: const Text('Dismiss')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx,
                  {'status': 'resolved', 'resolution': resolution.text.trim()}),
              style: ElevatedButton.styleFrom(
                  backgroundColor: FikaGoColors.forestGreen,
                  foregroundColor: Colors.white),
              child: const Text('Resolve')),
        ],
      ),
    );
    resolution.dispose();
    if (state == null) return;
    final result = await AdminService.updateComplaint(id, state['status'],
        resolution: state['resolution']);
    if (!mounted) return;
    _message(result['success'] == true
        ? 'Complaint updated.'
        : result['message']?.toString() ?? 'Update failed.');
    if (result['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      appBar: AppBar(
          title: Text('Complaints',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: FikaGoColors.charcoal,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
                initialValue: _filter,
                onSelected: (value) {
                  _filter = value;
                  _load();
                },
                itemBuilder: (_) => const [
                      PopupMenuItem(value: 'all', child: Text('All')),
                      PopupMenuItem(value: 'open', child: Text('Open')),
                      PopupMenuItem(
                          value: 'in_review', child: Text('In review')),
                      PopupMenuItem(value: 'resolved', child: Text('Resolved')),
                      PopupMenuItem(
                          value: 'dismissed', child: Text('Dismissed'))
                    ],
                icon: const Icon(Icons.filter_list))
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 150),
                      Icon(Icons.support_agent_outlined, size: 48),
                      Center(child: Text('No complaints found'))
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _card(_items[i]))));

  Widget _card(Map<String, dynamic> item) => Card(
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
          onTap: () => _review(item),
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
              backgroundColor: item['status'] == 'open'
                  ? Colors.orange.shade50
                  : FikaGoColors.lightGreen,
              child: Icon(Icons.support_agent,
                  color: item['status'] == 'open'
                      ? Colors.orange
                      : FikaGoColors.forestGreen)),
          title: Text(item['subject']?.toString() ?? '',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          subtitle: Text(
              '${item['customer_name']} · ${item['order_number'] ?? 'No order'}\n${item['description']}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          isThreeLine: true,
          trailing: Text(
              (item['status'] ?? '')
                  .toString()
                  .replaceAll('_', '\n')
                  .toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 9, fontWeight: FontWeight.bold))));
}
