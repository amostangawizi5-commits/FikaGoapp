// ============================================================
// FIKAGO - WALLET SCREEN (With Multi-Step Add/Withdraw)
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../utils/phone_number.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 45000.0;
  final double _pendingBalance = 8000.0;

  // ============================================================
  // DIALOG: ONGEZA PESA (ADD MONEY)
  // ============================================================
  void _showAddMoneyDialog() {
    final amountController = TextEditingController();
    String selectedMethod = 'M-Pesa';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: FikaGoColors.lightGreen,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_circle, color: FikaGoColors.forestGreen),
              const SizedBox(width: 8),
              Text(context.localized('Ongeza Pesa', 'Add Money'),
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.localized('Weka kiasi:', 'Enter amount:'),
                    style: GoogleFonts.montserrat(fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'TZS ',
                    hintText: context.localized('Mfano: 50,000', 'e.g. 50,000'),
                    filled: true,
                    fillColor: FikaGoColors.lightGreen,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                    context.localized(
                        'Chagua Njia ya Malipo:', 'Choose payment method:'),
                    style: GoogleFonts.montserrat(fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: FikaGoColors.lightGreen,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: [
                    'M-Pesa',
                    'Tigo Pesa',
                    'Airtel Money',
                    'Benki (CRDB/NMB)'
                  ].map((String val) {
                    return DropdownMenuItem(
                        value: val,
                        child: Text(val == 'Benki (CRDB/NMB)'
                            ? context.localized(val, 'Bank (CRDB/NMB)')
                            : val));
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedMethod = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.localized('HAPANA', 'CANCEL'),
                  style: GoogleFonts.montserrat(color: FikaGoColors.charcoal)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FikaGoColors.forestGreen,
                foregroundColor: FikaGoColors.lightGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount != null && amount >= 1000) {
                  Navigator.pop(ctx);
                  // Hapa tunampeleka kwenye hatua ya mwisho (USSD/Simulation)
                  _simulatePayment(amount, selectedMethod);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.localized(
                            'Kiasi cha chini ni TZS 1,000',
                            'Minimum amount is TZS 1,000')),
                        backgroundColor: FikaGoColors.charcoal),
                  );
                }
              },
              child: Text(context.localized('THIBITISHA', 'CONFIRM'),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  // ============================================================
  // DIALOG: TOA PESA (WITHDRAW)
  // ============================================================
  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedMethod = 'M-Pesa';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: FikaGoColors.lightGreen,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.arrow_downward, color: FikaGoColors.charcoal),
              const SizedBox(width: 8),
              Text(context.localized('Toa Pesa', 'Withdraw Money'),
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    context.localized('Kiasi (Kiwango cha chini: TZS 5,000):',
                        'Amount (Min: TZS 5,000):'),
                    style: GoogleFonts.montserrat(fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'TZS ',
                    hintText: context.localized('Mfano: 10,000', 'e.g. 10,000'),
                    filled: true,
                    fillColor: FikaGoColors.lightGreen,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                    context.localized(
                        'Chagua Njia ya Kupokea:', 'Choose withdrawal method:'),
                    style: GoogleFonts.montserrat(fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: FikaGoColors.lightGreen,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: [
                    'M-Pesa',
                    'Tigo Pesa',
                    'Airtel Money',
                    'Benki (CRDB/NMB)'
                  ].map((String val) {
                    return DropdownMenuItem(
                        value: val,
                        child: Text(val == 'Benki (CRDB/NMB)'
                            ? context.localized(val, 'Bank (CRDB/NMB)')
                            : val));
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedMethod = val!),
                ),
                const SizedBox(height: 16),
                Text(
                    context.localized(
                        'Namba ya Simu / Akaunti:', 'Phone / Account Number:'),
                    style: GoogleFonts.montserrat(fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [TanzaniaPhoneInputFormatter()],
                  decoration: InputDecoration(
                    prefixText: '+255 ',
                    hintText: '712 345 678',
                    filled: true,
                    fillColor: FikaGoColors.lightGreen,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.localized('HAPANA', 'CANCEL'),
                  style: GoogleFonts.montserrat(color: FikaGoColors.charcoal)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FikaGoColors.charcoal,
                foregroundColor: FikaGoColors.lightGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount < 5000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.localized(
                            'Kiasi cha chini ni TZS 5,000',
                            'Minimum amount is TZS 5,000')),
                        backgroundColor: FikaGoColors.charcoal),
                  );
                  return;
                }
                if (amount > _balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.localized(
                            'Huna salio la kutosha', 'Insufficient balance')),
                        backgroundColor: FikaGoColors.charcoal),
                  );
                  return;
                }
                if (normalizeTzPhone(phoneController.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.localized(
                            'Ingiza tarakimu 9 za simu baada ya +255.',
                            'Enter the 9 phone digits after +255.')),
                        backgroundColor: FikaGoColors.charcoal),
                  );
                  return;
                }

                Navigator.pop(ctx);
                _simulateWithdraw(
                  amount,
                  normalizeTzPhone(phoneController.text) ??
                      phoneController.text,
                  selectedMethod,
                );
              },
              child: Text(context.localized('TOA', 'WITHDRAW'),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  // ============================================================
  // SIMULATION: UTHIBITISHO WA MALIPO (Kama Unalipa kwa Simu)
  // ============================================================
  void _simulatePayment(double amount, String method) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AlertDialog(
        backgroundColor: FikaGoColors.lightGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: FikaGoColors.forestGreen),
            const SizedBox(height: 20),
            Text(
              context.localized('Tafadhali angalia simu yako...',
                  'Please check your phone...'),
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.localized(
                'Ombi la malipo la TZS ${amount.toStringAsFixed(0)} limetumwa kwa $method. Weka PIN yako kuidhinisha.',
                'A payment request for TZS ${amount.toStringAsFixed(0)} was sent to $method. Enter your PIN to approve.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: FikaGoColors.charcoal),
            ),
          ],
        ),
      ),
    );

    // Baada ya sekunde 3, tunaona kama imefanikiwa (Simulation)
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pop(context); // Futa dialog ya kusubiri
      setState(() {
        _balance += amount;
      });
      _showSuccessSnackBar(context.localized(
          'Umefanikiwa kuongeza TZS ${amount.toStringAsFixed(0)}',
          'Successfully added TZS ${amount.toStringAsFixed(0)}'));
    });
  }

  // ============================================================
  // SIMULATION: UTHIBITISHO WA KUTOA PESA
  // ============================================================
  void _simulateWithdraw(double amount, String phone, String method) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AlertDialog(
        backgroundColor: FikaGoColors.lightGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: FikaGoColors.charcoal),
            const SizedBox(height: 20),
            Text(
              context.localized(
                  'Inachakata ombi lako...', 'Processing your request...'),
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.localized(
                  'TZS ${amount.toStringAsFixed(0)} inatumwa kwenda $phone ($method).',
                  'TZS ${amount.toStringAsFixed(0)} is being sent to $phone ($method).'),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: FikaGoColors.charcoal),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _balance -= amount;
      });
      _showSuccessSnackBar(context.localized(
          'Umefanikiwa kutoa TZS ${amount.toStringAsFixed(0)}',
          'Successfully withdrew TZS ${amount.toStringAsFixed(0)}'));
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FikaGoColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        title: Text(context.localized('Wallet Yangu', 'My Wallet'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // BALANCE CARD
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
                      offset: const Offset(0, 8)),
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
                      Text(context.localized('SALIO LANGU', 'MY BALANCE'),
                          style: GoogleFonts.montserrat(
                              color: FikaGoColors.lightGreen
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                              letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'TZS ${_balance.toStringAsFixed(0)}',
                    style: GoogleFonts.montserrat(
                        color: FikaGoColors.lightGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FikaGoColors.sunYellow,
                            foregroundColor: FikaGoColors.charcoal,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed:
                              _showAddMoneyDialog, // Inafungua Dialog ya Kuweka Namba
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(context.localized('ONGEZA', 'ADD MONEY'),
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FikaGoColors.lightGreen,
                            side: const BorderSide(
                                color: FikaGoColors.lightGreen),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed:
                              _showWithdrawDialog, // Inafungua Dialog ya Kutoa
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          label: Text(context.localized('TOA', 'WITHDRAW'),
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // STATISTICS & TRANSACTIONS ZINAENDELEA...
            Row(
              children: [
                Expanded(
                    child: _statCard(
                        context.localized('Inasubiri', 'Pending'),
                        'TZS ${_pendingBalance.toStringAsFixed(0)}',
                        FikaGoColors.sunYellow)),
                const SizedBox(width: 16),
                Expanded(
                    child: _statCard(
                        context.localized(
                            'Pointi za uaminifu', 'Loyalty Points'),
                        '1,250 ${context.localized('pointi', 'pts')}',
                        FikaGoColors.forestGreen)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.localized('Historia ya Malipo', 'Payment History'),
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(context.localized('Ona Zote', 'See All'),
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: FikaGoColors.forestGreen,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            _transactionTile(
              icon: Icons.shopping_bag,
              color: FikaGoColors.charcoal,
              title: context.localized(
                  'Malipo - Oda #FK-001', 'Payment - Order #FK-001'),
              subtitle: context.localized('Leo, 12:30 PM', 'Today, 12:30 PM'),
              amount: '- TZS 24,200',
              amountColor: FikaGoColors.charcoal,
            ),
            _transactionTile(
              icon: Icons.add_circle,
              color: FikaGoColors.forestGreen,
              title: context.localized(
                  'Kuongeza Pesa (M-Pesa)', 'Top Up (M-Pesa)'),
              subtitle:
                  context.localized('Jana, 09:00 AM', 'Yesterday, 09:00 AM'),
              amount: '+ TZS 50,000',
              amountColor: FikaGoColors.forestGreen,
            ),
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
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _transactionTile(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required String amount,
      required Color amountColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FikaGoColors.lightGreen,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: FikaGoColors.charcoal)),
              ],
            ),
          ),
          Text(amount,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, color: amountColor)),
        ],
      ),
    );
  }
}
