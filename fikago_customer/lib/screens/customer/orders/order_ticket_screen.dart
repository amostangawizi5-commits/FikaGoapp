import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../home/home_screen.dart';

class OrderTicketScreen extends StatelessWidget {
  const OrderTicketScreen({
    super.key,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.amount,
    required this.items,
    this.deliveryLandmark,
    this.specialInstructions,
    this.paymentMethod,
    this.subtotal,
    this.deliveryFee,
    this.serviceFee,
    this.discount,
  });

  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double amount;
  final List<Map<String, dynamic>> items;
  final String? deliveryLandmark;
  final String? specialInstructions;
  final String? paymentMethod;
  final double? subtotal;
  final double? deliveryFee;
  final double? serviceFee;
  final double? discount;

  Future<void> _downloadTicket(BuildContext context) async {
    final swahili = context.locale.languageCode == 'sw';
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(28),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
                color: const PdfColor.fromInt(0xFF0B6B3A), width: 2),
            borderRadius: pw.BorderRadius.circular(16),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('FikaGo',
                    style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF0B6B3A))),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                  child: pw.Text(swahili
                      ? 'TIKETI YA ODA YA CHAKULA'
                      : 'FOOD ORDER TICKET')),
              pw.Divider(),
              pw.Text('${swahili ? 'Oda' : 'Order'}: $orderNumber',
                  style: pw.TextStyle(
                      fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('${swahili ? 'Mteja' : 'Customer'}: $customerName'),
              pw.Text('${swahili ? 'Simu' : 'Phone'}: $customerPhone'),
              pw.Text('${swahili ? 'Eneo' : 'Location'}: $deliveryAddress'),
              if (deliveryLandmark?.isNotEmpty == true)
                pw.Text('${swahili ? 'Alama' : 'Landmark'}: $deliveryLandmark'),
              if (specialInstructions?.isNotEmpty == true)
                pw.Text('${swahili ? 'Maelekezo' : 'Instructions'}: $specialInstructions'),
              if (paymentMethod?.isNotEmpty == true)
                pw.Text('${swahili ? 'Malipo' : 'Payment'}: ${paymentMethod!.toUpperCase()}'),
              pw.SizedBox(height: 14),
              pw.Text(swahili ? 'VITU VILIVYOAGIZWA' : 'ORDER ITEMS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              ...items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                            child: pw.Text(
                                '${item['quantity']} x ${item['name']}')),
                        pw.Text('TZS ${_money(item['total_price'])}'),
                      ],
                    ),
                  )),
              pw.Divider(),
              if (subtotal != null)
                pw.Text('${swahili ? 'Subtotal' : 'Subtotal'}: TZS ${subtotal!.toStringAsFixed(0)}'),
              if (deliveryFee != null)
                pw.Text('${swahili ? 'Delivery' : 'Delivery'}: TZS ${deliveryFee!.toStringAsFixed(0)}'),
              if (serviceFee != null)
                pw.Text('${swahili ? 'Charges' : 'Charges'}: TZS ${serviceFee!.toStringAsFixed(0)}'),
              if (discount != null)
                pw.Text('${swahili ? 'Discount' : 'Discount'}: - TZS ${discount!.toStringAsFixed(0)}'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(swahili ? 'JUMLA' : 'TOTAL',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('TZS ${amount.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: orderNumber,
                  width: 100,
                  height: 100,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                  child: pw.Text(swahili
                      ? 'Muonyeshe vendor tiketi hii.'
                      : 'Show this ticket to the vendor.')),
            ],
          ),
        ),
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'FikaGo-$orderNumber-ticket.pdf',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.localized('Tiketi haikuweza kupakuliwa.',
                  'Ticket could not be downloaded.'))),
        );
      }
    }
  }

  static String _money(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        title: Text(context.localized('Tiketi ya oda', 'Order ticket'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: FikaGoColors.lightGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FikaGoColors.forestGreen, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle,
                          color: FikaGoColors.forestGreen, size: 48),
                      const SizedBox(height: 8),
                      Text(context.localized('Oda imewekwa', 'Order placed'),
                          style: GoogleFonts.montserrat(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                          context.localized('Muonyeshe vendor tiketi hii.',
                              'Show this ticket to the vendor.'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              color: FikaGoColors.charcoal, fontSize: 12)),
                    ],
                  ),
                ),
                const Divider(height: 28),
                Text(orderNumber,
                    style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: FikaGoColors.forestGreen)),
                const SizedBox(height: 12),
                _detail(context.localized('Jina', 'Name'), customerName),
                _detail(context.localized('Simu', 'Phone'), customerPhone),
                _detail(context.localized('Eneo', 'Location'), deliveryAddress),
                if (deliveryLandmark?.isNotEmpty == true)
                  _detail(context.localized('Alama', 'Landmark'), deliveryLandmark!),
                if (specialInstructions?.isNotEmpty == true)
                  _detail(context.localized('Maelekezo', 'Instructions'), specialInstructions!),
                if (paymentMethod?.isNotEmpty == true)
                  _detail(context.localized('Malipo', 'Payment'), paymentMethod!.toUpperCase()),
                const Divider(height: 28),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${item['quantity']} × ${item['name']}',
                                style: GoogleFonts.montserrat(fontSize: 13)),
                          ),
                          Text('TZS ${_money(item['total_price'])}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                const Divider(height: 28),
                if (subtotal != null)
                  _summary(context.localized('Subtotal', 'Subtotal'), subtotal!),
                if (deliveryFee != null)
                  _summary(context.localized('Delivery', 'Delivery fee'), deliveryFee!),
                if (serviceFee != null)
                  _summary(context.localized('Charges', 'Charges'), serviceFee!),
                if (discount != null)
                  _summary(context.localized('Punguzo', 'Discount'), -discount!),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.localized('JUMLA', 'TOTAL'),
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold)),
                    Text('TZS ${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: FikaGoColors.forestGreen)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _downloadTicket(context),
              icon: const Icon(Icons.download),
              label: Text(
                  context.localized(
                      'Pakua tiketi (PDF)', 'Download ticket (PDF)'),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: FikaGoColors.forestGreen,
                foregroundColor: FikaGoColors.lightGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            ),
            child: Text(context.localized('Rudi FikaGo', 'Back to FikaGo')),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 78,
              child: Text(label,
                  style: GoogleFonts.montserrat(
                      color: FikaGoColors.charcoal, fontSize: 12)),
            ),
            Expanded(
                child: Text(value,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _summary(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.montserrat(fontSize: 12)),
            Text('TZS ${value.toStringAsFixed(0)}',
                style: GoogleFonts.montserrat(fontSize: 12)),
          ],
        ),
      );
}
