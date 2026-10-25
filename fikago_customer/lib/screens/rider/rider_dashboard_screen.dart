// ============================================================
// FIKAGO RIDER - DASHBOARD (With Available Orders & Call)
// ============================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/rider_service.dart';
import '../auth/role_selection_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = false;
  bool _isUpdatingStatus = false;
  bool _isLoadingOrders = false;
  bool _isLoadingWallet = false;
  String? _ordersError;
  String _selectedSection = 'jobs';
  List<Map<String, dynamic>> _availableOrders = [];
  Map<String, dynamic>? _wallet;
  final Set<int> _processingOrderIds = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isOnline && _selectedSection == 'jobs') {
        _loadAvailableOrders(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _setOnline(bool value) async {
    setState(() => _isUpdatingStatus = true);
    final response = await RiderService.updateStatus(value);
    if (!mounted) return;
    setState(() => _isUpdatingStatus = false);
    if (response['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ??
              context.localized('Imeshindikana kubadili status.',
                  'Could not update your status.')),
        ),
      );
      return;
    }
    setState(() {
      _isOnline = value;
      if (!value) _availableOrders = [];
      _ordersError = null;
    });
    if (value) await _loadAvailableOrders();
  }

  Future<void> _loadAvailableOrders({bool silent = false}) async {
    if (!_isOnline || _isLoadingOrders) return;
    setState(() {
      _isLoadingOrders = true;
      if (!silent) _ordersError = null;
    });
    final response = await RiderService.getAssignments(status: 'new');
    if (!mounted) return;
    if (response['success'] == true && response['data'] is List) {
      final orders = (response['data'] as List)
          .whereType<Map>()
          .map((row) {
            final order = Map<String, dynamic>.from(row);
            final address = order['delivery_address']?.toString() ?? '';
            final landmark = order['delivery_landmark']?.toString() ?? '';
            return <String, dynamic>{
              ...order,
              'display_id': order['order_number']?.toString() ??
                  order['order_id']?.toString() ??
                  '',
              'restaurant': order['restaurant_name']?.toString() ?? '',
              'restaurantPhone': order['restaurant_phone']?.toString() ?? '',
              'pickup': order['restaurant_address']?.toString() ?? '',
              'dropoff': [address, landmark]
                  .where((part) => part.trim().isNotEmpty)
                  .join(', '),
            };
          })
          .toList();
      setState(() {
        _availableOrders = orders;
        _isLoadingOrders = false;
        _ordersError = null;
      });
    } else {
      setState(() {
        _isLoadingOrders = false;
        _ordersError = response['message']?.toString() ??
            context.localized('Imeshindikana kupakia oda.',
                'Could not load orders.');
      });
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final assignmentId = int.tryParse(order['id'].toString());
    if (assignmentId == null) return;
    setState(() => _processingOrderIds.add(assignmentId));
    final response = await RiderService.acceptAssignment(assignmentId);
    if (!mounted) return;
    setState(() {
      _processingOrderIds.remove(assignmentId);
      if (response['success'] == true) {
        _availableOrders.removeWhere((item) => item['id'] == order['id']);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['success'] == true
            ? context.localized('Umeikubali oda.', 'Order accepted.')
            : response['message']?.toString() ??
                context.localized('Oda imechukuliwa na rider mwingine.',
                    'Another rider has already accepted this order.')),
        backgroundColor: response['success'] == true
            ? FikaGoColors.forestGreen
            : FikaGoColors.charcoal,
      ),
    );
    await _loadAvailableOrders(silent: true);
  }

  Future<void> _declineOrder(Map<String, dynamic> order) async {
    final assignmentId = int.tryParse(order['id'].toString());
    if (assignmentId == null) return;
    setState(() => _processingOrderIds.add(assignmentId));
    final response = await RiderService.declineAssignment(assignmentId);
    if (!mounted) return;
    setState(() {
      _processingOrderIds.remove(assignmentId);
      if (response['success'] == true) {
        _availableOrders.removeWhere((item) => item['id'] == order['id']);
      }
    });
    if (response['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ??
              context.localized('Imeshindikana kukataa oda.',
                  'Could not decline this order.')),
        ),
      );
      await _loadAvailableOrders(silent: true);
    }
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoadingWallet = true);
    final response = await RiderService.getWallet();
    if (!mounted) return;
    setState(() {
      _isLoadingWallet = false;
      _wallet = response['success'] == true && response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : null;
    });
  }

  // Kazi ya Kumpigia Mgahawa
  Future<void> _callRestaurant(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.localized(
                  'Imeshindwa kupiga simu. Hakikisha una app ya simu.',
                  'Could not place the call. Make sure a phone app is available.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,

      // ============================================
      // APP BAR
      // ============================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
        title: Text(
          'FikaGo Rider',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold, color: FikaGoColors.forestGreen),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: FikaGoColors.forestGreen),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      // ============================================
      // DRAWER (Menyu ya Pembeni)
      // ============================================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: FikaGoColors.forestGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        size: 40, color: FikaGoColors.forestGreen),
                  ),
                  const SizedBox(height: 12),
                  Text(user?['full_name']?.toString() ?? 'FikaGo Rider',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text(user?['phone_number']?.toString() ?? 'Rider',
                      style: GoogleFonts.montserrat(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              selected: _selectedSection == 'jobs',
              leading: const Icon(Icons.delivery_dining,
                  color: FikaGoColors.forestGreen),
              title: Text(context.localized('Kazi Zangu', 'My jobs'),
                  style: GoogleFonts.montserrat()),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedSection = 'jobs');
              },
            ),
            ListTile(
              selected: _selectedSection == 'earnings',
              leading: const Icon(Icons.account_balance_wallet,
                  color: FikaGoColors.forestGreen),
              title: Text(context.localized('Pesa Zangu', 'My earnings'),
                  style: GoogleFonts.montserrat()),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedSection = 'earnings');
                _loadWallet();
              },
            ),
            ListTile(
              selected: _selectedSection == 'profile',
              leading: const Icon(Icons.person_outline,
                  color: FikaGoColors.forestGreen),
              title: Text(context.localized('Wasifu', 'Profile'),
                  style: GoogleFonts.montserrat()),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedSection = 'profile');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.language, color: FikaGoColors.forestGreen),
              title: Text(context.localized('Lugha', 'Language'),
                  style: GoogleFonts.montserrat()),
              trailing: Text(context.locale.languageCode == 'en'
                  ? 'English'
                  : 'Kiswahili'),
              onTap: () => context.setLocale(
                  Locale(context.locale.languageCode == 'en' ? 'sw' : 'en')),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(context.localized('Toka (Ondoka)', 'Log out'),
                  style: GoogleFonts.montserrat(color: Colors.red)),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      // ============================================
      // BODY
      // ============================================
      body: _selectedSection == 'jobs'
          ? _buildJobsPage()
          : _selectedSection == 'earnings'
              ? _buildEarningsPage()
              : _buildProfilePage(user),
    );
  }

  Widget _buildJobsPage() {
    return Column(
        children: [
          // 1. KITUFE CHA ONLINE/OFFLINE (Juu)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isOnline ? FikaGoColors.forestGreen : Colors.grey[600],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isOnline
                      ? context.localized('Uko Online', 'You are online')
                      : context.localized('Uko Offline', 'You are offline'),
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isOnline,
                  activeThumbColor: Colors.white,
                  activeTrackColor: FikaGoColors.sunYellow,
                  onChanged: _isUpdatingStatus ? null : _setOnline,
                ),
              ],
            ),
          ),

          // 2. ORODHA YA ODA (Kama yuko Online)
          Expanded(
            child: !_isOnline
                ? _buildOfflineMessage()
                : _isLoadingOrders && _availableOrders.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _ordersError != null && _availableOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_ordersError!, textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _loadAvailableOrders,
                                  child: Text(context.localized(
                                      'Jaribu tena', 'Try again')),
                                ),
                              ],
                            ),
                          )
                : _availableOrders.isEmpty
                    ? _buildNoOrdersMessage()
                    : RefreshIndicator(
                        onRefresh: _loadAvailableOrders,
                        child: _buildOrdersList(),
                      ),
          ),
        ],
      );
  }

  Widget _buildEarningsPage() {
    if (_isLoadingWallet) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_wallet == null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadWallet,
          icon: const Icon(Icons.refresh),
          label: Text(context.localized(
              'Imeshindikana kupakia mapato. Jaribu tena.',
              'Could not load earnings. Try again.')),
        ),
      );
    }
    final balance =
        double.tryParse(_wallet!['balance']?.toString() ?? '') ?? 0;
    final pending =
        double.tryParse(_wallet!['pending_balance']?.toString() ?? '') ?? 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _earningsCard(
          context.localized('Mapato yanayopatikana', 'Available earnings'),
          balance,
          Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        _earningsCard(
          context.localized('Malipo yanayosubiri', 'Pending earnings'),
          pending,
          Icons.hourglass_bottom,
        ),
      ],
    );
  }

  Widget _earningsCard(String title, double amount, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: FikaGoColors.forestGreen),
        title: Text(title),
        trailing: Text(
          'TZS ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProfilePage(Map<String, dynamic>? user) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: FikaGoColors.forestGreen,
          child: Icon(Icons.person, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(context.localized('Jina', 'Name')),
          subtitle: Text(user?['full_name']?.toString() ?? 'FikaGo Rider'),
        ),
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: Text(context.localized('Simu', 'Phone')),
          subtitle: Text(user?['phone_number']?.toString() ?? '—'),
        ),
      ],
    );
  }

  // ============================================
  // WIDGETS
  // ============================================
  Widget _buildOfflineMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
              context.localized('Washa (Online) ili uone oda zilizopo',
                  'Go online to see available orders'),
              style: GoogleFonts.montserrat(
                  color: FikaGoColors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNoOrdersMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
              context.localized('Hakuna oda kwa sasa. Subiri kidogo...',
                  'No orders right now. Please wait...'),
              style: GoogleFonts.montserrat(color: FikaGoColors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableOrders.length,
      itemBuilder: (context, index) {
        final order = _availableOrders[index];
        final assignmentId = int.tryParse(order['id'].toString());
        final isProcessing = assignmentId != null &&
            _processingOrderIds.contains(assignmentId);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FikaGoColors.sunYellow, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kichwa: Order ID & Earnings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order['display_id']?.toString() ?? '',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('TZS ${order['earnings'] ?? 0}',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: FikaGoColors.forestGreen,
                          fontSize: 16)),
                ],
              ),
              const Divider(height: 24),

              // Pickup
              Row(
                children: [
                  const Icon(Icons.store,
                      size: 16, color: FikaGoColors.forestGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['restaurant']?.toString() ?? '',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600)),
                        Text(order['pickup']?.toString() ?? '',
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: FikaGoColors.grey)),
                      ],
                    ),
                  ),
                  // Kitufe cha Kumpigia Mgahawa
                  IconButton(
                    onPressed: () => _callRestaurant(
                        order['restaurantPhone']?.toString() ?? ''),
                    icon:
                        const Icon(Icons.phone, color: FikaGoColors.sunYellow),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          FikaGoColors.sunYellow.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dropoff
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.localized('Mteja', 'Customer'),
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600)),
                        Text(order['dropoff']?.toString() ?? '',
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: FikaGoColors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Vitufe vya Kazi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          isProcessing ? null : () => _declineOrder(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(context.localized('KATAA', 'DECLINE'),
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          isProcessing ? null : () => _acceptOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FikaGoColors.forestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(context.localized('KUBALI', 'ACCEPT'),
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
