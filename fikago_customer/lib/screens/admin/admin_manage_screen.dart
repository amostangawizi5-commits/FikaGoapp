import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminManageScreen extends StatefulWidget {
  const AdminManageScreen({super.key});
  @override
  State<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends State<AdminManageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> _records = {};
  final Map<String, bool> _loading = {
    'customer': true,
    'vendor': true,
    'rider': true
  };
  static const _roles = ['customer', 'vendor', 'rider'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this)..addListener(_onTabChanged);
    _load(_roles.first);
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) _load(_roles[_tabs.index]);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String role) async {
    setState(() => _loading[role] = true);
    final result =
        await AdminService.getPeople(role, search: _search.text.trim());
    if (!mounted) return;
    setState(() {
      _records[role] = result['success'] == true && result['data'] is List
          ? (result['data'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      _loading[role] = false;
    });
    if (result['success'] != true) {
      _message(result['message']?.toString() ?? 'Could not load records.');
    }
  }

  void _searchChanged() {
    for (final role in _roles) {
      _load(role);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  Future<void> _editVendor(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id'].toString());
    if (id == null) return;
    final fullName = TextEditingController(text: item['full_name']?.toString());
    final restaurantName =
        TextEditingController(text: item['name']?.toString());
    final phone = TextEditingController(text: item['phone_number']?.toString());
    final email = TextEditingController(text: item['email']?.toString());
    final address = TextEditingController(text: item['address']?.toString());
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit vendor'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editField(fullName, 'Vendor name'),
                  _editField(restaurantName, 'Restaurant name'),
                  _editField(phone, 'Phone number',
                      keyboardType: TextInputType.phone),
                  _editField(email, 'Email',
                      keyboardType: TextInputType.emailAddress),
                  _editField(address, 'Address'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      final result = await AdminService.updateVendor(id, {
        'full_name': fullName.text.trim(),
        'restaurant_name': restaurantName.text.trim(),
        'phone_number': phone.text.trim(),
        'email': email.text.trim(),
        'address': address.text.trim(),
      });
      if (!mounted) return;
      _message(result['success'] == true
          ? 'Vendor details updated.'
          : result['message']?.toString() ?? 'Could not update vendor.');
      if (result['success'] == true) _load('vendor');
    }
    fullName.dispose();
    restaurantName.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
  }

  Widget _editField(TextEditingController controller, String label,
          {TextInputType? keyboardType}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
      );

  Future<void> _deleteVendor(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id'].toString());
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove vendor?'),
        content: Text(
          'Remove ${item['name'] ?? item['full_name']} from the active marketplace? Past orders will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _action('vendor', item, 'delete');
  }

  Future<void> _action(
      String role, Map<String, dynamic> item, String action) async {
    final id = int.tryParse(item['id'].toString());
    if (id == null) return;
    final result = await AdminService.updatePerson(role, id, action);
    if (!mounted) return;
    _message(result['success'] == true
        ? 'Account updated.'
        : result['message']?.toString() ?? 'Action failed.');
    if (result['success'] == true) _load(role);
  }

  Future<void> _details(String role, Map<String, dynamic> item) async {
    final id = int.tryParse(item['id'].toString());
    if (id == null) return;
    final result = await AdminService.getPersonDetails(role, id);
    if (!mounted) return;
    if (result['success'] != true) {
      _message(result['message']?.toString() ?? 'Could not load details.');
      return;
    }
    final data = Map<String, dynamic>.from(result['data'] ?? {});
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(
                  role == 'customer'
                      ? 'Customer order history'
                      : '${role == 'vendor' ? 'Restaurant' : 'Rider'} performance',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              content: SizedBox(
                  width: 520,
                  child: role == 'customer'
                      ? (data['orders'] as List? ?? []).isEmpty
                          ? const Text('No orders found.')
                          : SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: (data['orders'] as List).map((raw) {
                                    final order =
                                        Map<String, dynamic>.from(raw);
                                    return ListTile(
                                        dense: true,
                                        title: Text(
                                            '${order['order_number']} · ${order['restaurant_name']}'),
                                        subtitle: Text(
                                            '${order['status']} · ${order['payment_status']}'),
                                        trailing: Text(
                                            'TZS ${order['total_amount']}'));
                                  }).toList()))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: (data['metrics'] as Map? ?? {})
                              .entries
                              .map((e) => ListTile(
                                  title: Text(_metricLabel(e.key)),
                                  trailing: Text(e.value.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))))
                              .toList())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'))
              ],
            ));
  }

  String _metricLabel(String key) => switch (key) {
        'total_orders' => 'Total orders',
        'completed_orders' => 'Completed orders',
        'total_deliveries' => 'Deliveries',
        'earnings' => 'Lifetime earnings',
        _ => key,
      };

  String _status(String role, Map<String, dynamic> item) {
    if (role == 'vendor') {
      return item['approval_status']?.toString() ??
          (item['is_active'] == true ? 'approved' : 'suspended');
    }
    if (role == 'rider') {
      return item['approval_status']?.toString() ??
          (item['is_approved'] != true
              ? 'pending'
              : item['is_active'] == true
                  ? 'active'
                  : 'suspended');
    }
    if (role == 'vendor' && item['approval_status'] == 'deleted') {
      return 'deleted';
    }
    return item['is_active'] == true ? 'active' : 'suspended';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: FikaGoColors.lightGrey,
        appBar: AppBar(
            title: Text('Management',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: FikaGoColors.charcoal,
            elevation: 0,
            bottom: TabBar(
                controller: _tabs,
                labelColor: FikaGoColors.forestGreen,
                unselectedLabelColor: FikaGoColors.grey,
                indicatorColor: FikaGoColors.forestGreen,
                tabs: const [
                  Tab(text: 'Customers'),
                  Tab(text: 'Restaurants'),
                  Tab(text: 'Riders')
                ])),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _searchChanged(),
                  onChanged: (_) {
                    if (_search.text.isEmpty) _searchChanged();
                  },
                  decoration: InputDecoration(
                      hintText: 'Search name, phone or restaurant...',
                      prefixIcon: const Icon(Icons.search,
                          color: FikaGoColors.forestGreen),
                      suffixIcon: IconButton(
                          onPressed: _searchChanged,
                          icon: const Icon(Icons.arrow_forward)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none)))),
          Expanded(
              child: TabBarView(
                  controller: _tabs, children: _roles.map(_list).toList())),
        ]),
      );

  Widget _list(String role) {
    if (_loading[role] == true) {
      return const Center(child: CircularProgressIndicator());
    }
    final records = _records[role] ?? [];
    if (records.isEmpty) {
      return RefreshIndicator(
          onRefresh: () => _load(role),
          child: ListView(children: const [
            SizedBox(height: 150),
            Icon(Icons.people_outline, size: 48),
            Center(child: Text('No matching records'))
          ]));
    }
    return RefreshIndicator(
        onRefresh: () => _load(role),
        child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: records.length,
            itemBuilder: (context, index) => _card(role, records[index])));
  }

  Widget _card(String role, Map<String, dynamic> item) {
    final status = _status(role, item);
    final pending = role != 'customer' && status == 'pending';
    final suspended = status == 'suspended';
    final name = role == 'vendor'
        ? (item['name'] ?? item['full_name'] ?? 'Restaurant').toString()
        : (item['name'] ?? 'Account').toString();
    final icon = role == 'vendor'
        ? Icons.storefront
        : role == 'rider'
            ? Icons.delivery_dining
            : Icons.person_outline;
    final trailingInfo = role == 'customer'
        ? '${item['order_count'] ?? 0} orders'
        : role == 'vendor'
            ? '★ ${item['rating_avg'] ?? '—'} · ${item['order_count'] ?? 0} orders'
            : '${item['vehicle_type'] ?? 'Rider'} · '
                '${item['is_online'] == true ? 'ONLINE' : 'OFFLINE'} · '
                '${item['is_busy'] == true ? 'BUSY' : 'AVAILABLE'} · '
                '${item['total_deliveries'] ?? 0} deliveries';
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                CircleAvatar(
                    backgroundColor: FikaGoColors.lightGreen,
                    child: Icon(icon, color: FikaGoColors.forestGreen)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${item['phone_number'] ?? ''} · ${item['email'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: FikaGoColors.grey)),
                      const SizedBox(height: 5),
                      Text('${status.toUpperCase()}  ·  $trailingInfo',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: pending
                                  ? Colors.orange
                                  : suspended
                                      ? Colors.redAccent
                                      : FikaGoColors.forestGreen))
                    ]))
              ]),
              const Divider(height: 22),
              Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                        onPressed: () => _details(role, item),
                        icon: const Icon(Icons.visibility_outlined, size: 17),
                        label: Text(role == 'customer'
                            ? 'Order history'
                            : 'Performance')),
                    if (role == 'vendor') ...[
                      if (status == 'deleted')
                        TextButton(
                          onPressed: () => _action(role, item, 'reactivate'),
                          child: const Text('Restore'),
                        )
                      else ...[
                        TextButton.icon(
                          onPressed: () => _editVendor(item),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: () => _deleteVendor(item),
                          icon: const Icon(Icons.delete_outline, size: 17),
                          label: const Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                        if (pending || status == 'rejected') ...[
                          if (pending)
                            TextButton(
                              onPressed: () => _action(role, item, 'reject'),
                              child: const Text('Reject',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ElevatedButton(
                            onPressed: () => _action(role, item, 'approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FikaGoColors.forestGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ] else
                          TextButton(
                            onPressed: () => _action(role, item,
                                suspended ? 'reactivate' : 'suspend'),
                            child: Text(suspended ? 'Unblock' : 'Block',
                                style: TextStyle(
                                    color: suspended
                                        ? FikaGoColors.forestGreen
                                        : Colors.orange.shade800)),
                          ),
                      ],
                    ] else if (role == 'rider' && pending) ...[
                      TextButton(
                        onPressed: () => _action(role, item, 'reject'),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                      ElevatedButton(
                        onPressed: () => _action(role, item, 'approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FikaGoColors.forestGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ] else if (role == 'rider')
                      TextButton(
                          onPressed: () => _action(
                              role, item, suspended ? 'reactivate' : 'suspend'),
                          child: Text(suspended ? 'Reactivate' : 'Suspend',
                              style: TextStyle(
                                  color: suspended
                                      ? FikaGoColors.forestGreen
                                      : Colors.orange.shade800)))
                    else
                      TextButton(
                          onPressed: () => _action(
                              role, item, suspended ? 'reactivate' : 'suspend'),
                          child: Text(suspended ? 'Reactivate' : 'Suspend',
                              style: TextStyle(
                                  color: suspended
                                      ? FikaGoColors.forestGreen
                                      : Colors.orange.shade800))),
                  ]),
            ])));
  }
}
