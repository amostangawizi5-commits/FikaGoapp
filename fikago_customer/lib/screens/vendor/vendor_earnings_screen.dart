// ============================================================
// FIKAGO VENDOR - EARNINGS SCREEN
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';

class VendorEarningsScreen extends StatelessWidget {
  const VendorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/images/fikaGO.png', height: 35),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. BALANCE CARD
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
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          color: FikaGoColors.lightGreen),
                      const SizedBox(width: 8),
                      Text(context.localized('MAPATO YANGU', 'MY EARNINGS'),
                          style: GoogleFonts.montserrat(
                              color: FikaGoColors.lightGreen
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                              letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('TZS 450,000',
                      style: GoogleFonts.montserrat(
                          color: FikaGoColors.lightGreen,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: FikaGoColors.sunYellow,
                          foregroundColor: FikaGoColors.charcoal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {},
                      child: Text(context.localized('TOA PESA', 'WITHDRAW'),
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. STATISTICS
            Row(
              children: [
                Expanded(
                    child: _statCard(
                        context.localized('Inasubiri', 'Pending (Escrow)'),
                        'TZS 120,000',
                        FikaGoColors.sunYellow)),
                const SizedBox(width: 16),
                Expanded(
                    child: _statCard(
                        context.localized(
                            'Kamisheni (15%)', 'Commission (15%)'),
                        'TZS 67,500',
                        FikaGoColors.forestGreen)),
              ],
            ),
            const SizedBox(height: 24),

            // 3. TRANSACTIONS
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    context.localized('Historia ya Mapato', 'Earnings History'),
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            _transactionTile(
                '#FK-101',
                context.localized('Leo, 12:30 PM', 'Today, 12:30 PM'),
                '+ TZS 20,400',
                FikaGoColors.forestGreen),
            _transactionTile(
                '#FK-100',
                context.localized('Jana, 07:00 PM', 'Yesterday, 07:00 PM'),
                '+ TZS 12,750',
                FikaGoColors.forestGreen),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FikaGoColors.lightGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: FikaGoColors.charcoal.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: FikaGoColors.charcoal)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _transactionTile(
      String orderNum, String date, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FikaGoColors.lightGreen,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orderNum,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              Text(date,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: FikaGoColors.charcoal)),
            ],
          ),
          Text(amount,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
