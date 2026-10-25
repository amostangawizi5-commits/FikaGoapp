// ============================================================
// FIKAGO - ORDER TRACKING SCREEN (Professional Design)
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderNumber;
  final String currentStatus; // Hii ndio parameter inayotumika

  const OrderTrackingScreen({
    super.key,
    required this.orderNumber,
    this.currentStatus = 'preparing',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        title: Text(
          context.localized('Fuatilia Oda', 'Track Order'),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATUS CARD (ETA)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FikaGoColors.forestGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: FikaGoColors.forestGreen.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    orderNumber,
                    style: GoogleFonts.montserrat(
                      color: FikaGoColors.lightGreen.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.localized('Dakika 15 - 20', '15 - 20 minutes'),
                    style: GoogleFonts.montserrat(
                      color: FikaGoColors.lightGreen,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.localized('Chakula chako kinafika hivi karibuni',
                        'Your food will arrive soon'),
                    style: GoogleFonts.montserrat(
                      color: FikaGoColors.lightGreen.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. RIDER INFO
            Text(
              context.localized('Dereva Wako', 'Your Rider'),
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FikaGoColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: FikaGoColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: FikaGoColors.lightGreen,
                    child: Icon(Icons.person,
                        size: 30, color: FikaGoColors.forestGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Juma M.',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.localized('Pikipiki • MC 123 ABC',
                              'Motorcycle • MC 123 ABC'),
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: FikaGoColors.charcoal),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _actionButton(
                          Icons.phone, FikaGoColors.forestGreen, () {}),
                      const SizedBox(width: 8),
                      _actionButton(
                          Icons.message, FikaGoColors.sunYellow, () {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. TIMELINE
            Text(
              context.localized('Hatua za Oda', 'Order Progress'),
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FikaGoColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: FikaGoColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _timelineItem(
                      context.localized(
                          'Oda Imethibitishwa', 'Order Confirmed'),
                      '12:15 PM',
                      true,
                      true),
                  _timelineItem(context.localized('Inapikwa', 'Preparing'),
                      '12:20 PM', true, true),
                  _timelineItem(
                      context.localized(
                          'Imechukuliwa na dereva', 'Picked up by rider'),
                      '12:30 PM',
                      true,
                      currentStatus != 'preparing'),
                  _timelineItem(context.localized('Imefikishwa', 'Delivered'),
                      '--:--', false, currentStatus == 'delivered',
                      isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _timelineItem(
      String title, String time, bool isActive, bool isCompleted,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? FikaGoColors.forestGreen
                    : (isActive
                        ? FikaGoColors.sunYellow
                        : FikaGoColors.charcoal.withValues(alpha: 0.2)),
              ),
              child: isCompleted
                  ? const Icon(Icons.check,
                      size: 16, color: FikaGoColors.lightGreen)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? FikaGoColors.forestGreen
                    : FikaGoColors.charcoal.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontWeight: (isActive || isCompleted)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: (isActive || isCompleted)
                        ? FikaGoColors.charcoal
                        : FikaGoColors.charcoal,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: FikaGoColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
