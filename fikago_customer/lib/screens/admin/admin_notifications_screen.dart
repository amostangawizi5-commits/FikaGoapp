// ============================================================
// FIKAGO ADMIN - NOTIFICATIONS
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      appBar: AppBar(
        title: Text('Send Notifications',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Push Notification',
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Chagua Watumiaji
            DropdownButtonFormField<String>(
              initialValue: 'All Customers',
              decoration: InputDecoration(
                labelText: 'Send To',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              items: ['All Customers', 'All Vendors', 'All Riders', 'Everyone']
                  .map((val) {
                return DropdownMenuItem(value: val, child: Text(val));
              }).toList(),
              onChanged: (val) {},
            ),
            const SizedBox(height: 16),

            // Kichwa
            TextField(
              decoration: InputDecoration(
                labelText: 'Notification Title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Ujumbe
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message Body',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FikaGoColors.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                label: Text('SEND NOTIFICATION',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
