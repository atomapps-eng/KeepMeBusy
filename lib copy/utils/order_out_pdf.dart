import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class OrderOutPdfGenerator {
  static Future<Uint8List> generate({
    required Map<String, dynamic> data,
  }) async {
    // ===== LOAD LOGO =====
    final logoBytes =
        await rootBundle.load('assets/images/Atom.png');
    final logoImage =
        pw.MemoryImage(logoBytes.buffer.asUint8List());

    final pdf = pw.Document();

    final items = data['items'] as List<dynamic>? ?? [];

    final totalItem = items.length;
    final totalQty = items.fold<int>(
      0,
      (sum, item) => sum + (item['qty'] as int),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // ==================================================
          // HEADER
          // ==================================================
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: LOGO + TITLE
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(
                    logoImage,
                    width: 48,
                    height: 48,
                    fit: pw.BoxFit.contain,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    'ORDER OUT',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // RIGHT: DATE
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Order Date',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(_formatDate(data['orderDate'])),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // ==================================================
          // ORDER INFO (ALIGN COLON)
          // ==================================================
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FixedColumnWidth(8),
              2: pw.FlexColumnWidth(3),
            },
            children: [
              _infoRow('PO Number', data['poNumber']),
              _infoRow('Client', data['client']),
              if (data['createdBy'] != null)
                _infoRow('Created By', data['createdBy']),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // ==================================================
          // ITEM TABLE
          // ==================================================
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey400,
            ),
            columnWidths: const {
              0: pw.FixedColumnWidth(30),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
              3: pw.FlexColumnWidth(2),
              4: pw.FixedColumnWidth(40),
            },
            children: [
              // HEADER
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.orange800,
                ),
                children: [
                  _headerCell('No'),
                  _headerCell('Part Code'),
                  _headerCell('Name'),
                  _headerCell('Location'),
                  _headerCell('Qty'),
                ],
              ),

              // ROWS
              ...List.generate(items.length, (index) {
                final item = items[index];
                return pw.TableRow(
                  children: [
                    _cell('${index + 1}', alignCenter: true),
                    _cell(item['partCode'] ?? '-'),
                    _cell(item['nameEn'] ?? '-'),
                    _cell(item['location'] ?? '-'),
                    _cell(
                      item['qty'].toString(),
                      alignCenter: true,
                    ),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(),

          // ==================================================
          // SUMMARY
          // ==================================================
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Total Item : $totalItem'),
          pw.Text('Total Qty  : $totalQty'),
        ],
      ),
    );

    return pdf.save();
  }

  // ======================================================
  // HELPERS
  // ======================================================
  static pw.TableRow _infoRow(String label, dynamic value) {
    return pw.TableRow(
      children: [
        pw.Text(label),
        pw.Text(':'),
        pw.Text(value?.toString() ?? '-'),
      ],
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool alignCenter = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign:
            alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static String _formatDate(dynamic ts) {
    if (ts == null) return '-';
    try {
      final date = ts.toDate();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return '-';
    }
  }
}
