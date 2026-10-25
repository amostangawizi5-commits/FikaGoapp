import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_selection_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
        backgroundColor: FikaGoColors.lightGrey,
        appBar: AppBar(
            title: Text('Admin settings',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: FikaGoColors.charcoal,
            elevation: 0),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(children: [
                    const CircleAvatar(
                        radius: 38,
                        backgroundColor: FikaGoColors.lightGreen,
                        child: Icon(Icons.admin_panel_settings_outlined,
                            size: 40, color: FikaGoColors.forestGreen)),
                    const SizedBox(height: 12),
                    Text(user?['full_name']?.toString() ?? 'FikaGo Admin',
                        style: GoogleFonts.montserrat(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                        user?['email']?.toString() ??
                            user?['phone_number']?.toString() ??
                            '',
                        style: GoogleFonts.montserrat(color: FikaGoColors.grey))
                  ]))),
          const SizedBox(height: 18),
          const ListTile(
              leading: Icon(Icons.verified_user_outlined,
                  color: FikaGoColors.forestGreen),
              title: Text('Administrator access'),
              subtitle:
                  Text('Management actions are recorded under your account.')),
          const SizedBox(height: 18),
          ElevatedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RoleSelectionScreen()),
                      (_) => false);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15)))
        ]));
  }
}
