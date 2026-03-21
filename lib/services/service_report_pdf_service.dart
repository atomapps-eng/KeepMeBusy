import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'pdf_io.dart'
    if (dart.library.html) 'pdf_web.dart';

class ServiceReportPdfService {
static Future<void> generatePdf({
  required Map<String, dynamic> data,
}) async {

  final pdf = pw.Document();

  final fontRegular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));

  final fontBold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

  final logoBytes =
      (await rootBundle.load('assets/images/ATOM_INDO.png'))
          .buffer
          .asUint8List();

  final df = DateFormat('dd/MM/yyyy');

  Future<pw.MemoryImage?> loadImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(url));
      return pw.MemoryImage(res.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  final signatureImage = await loadImage(data['signature']);
  final photo1 = await loadImage(data['photo1']);
  final photo2 = await loadImage(data['photo2']);
  final photo3 = await loadImage(data['photo3']);

  final parts = (data['spareParts'] as List?) ?? [];
  final hasSpareParts = parts.isNotEmpty;
final hasAttachments = photo1 != null || photo2 != null || photo3 != null;

  final note = data['noteForCustomer']?.toString().trim();

  final problemShort = safeText(data['problemDescription'], maxChars: 200);
  final activityShort = safeText(data['activity'], maxChars: 200);

  // ================= PAGE 1 =================
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(45, 25, 45, 35),
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      build: (context) {
        return pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [

    pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [

            _buildModernHeader(data, logoBytes, df, fontBold),

            pw.SizedBox(height: 12),

            _buildModernInfoGrid(data),

            pw.SizedBox(height: 12),

            _buildModernDivider(),

            _buildModernMachineSection(data),

            pw.SizedBox(height: 12),

            _buildModernTextSection(
  "PROBLEM DESCRIPTION",
  problemShort,
  fontBold,
  maxLines: 6,
),
            pw.SizedBox(height: 12),

           _buildModernTextSection(
  "WORK CARRIED OUT",
  activityShort,
  fontBold,
  maxLines: 6,
),
            pw.SizedBox(height: 20),
                    ],
      ),
    ),

    _buildModernFooter(data, signatureImage),
          ],
        );
      },
    ),
  );

  // ================= PAGE 2 =================
  if (hasSpareParts || hasAttachments) {
  pdf.addPage(
    pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(45, 30, 45, 40),
    theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    build: (context) => [

      _buildModernHeader(data, logoBytes, df, fontBold),

      pw.SizedBox(height: 20),

      _buildModernSparePartsSection(parts, fontBold),

      if (note != null && note.isNotEmpty) ...[
  pw.SizedBox(height: 20),
  _buildModernNoteSection(data, fontBold),
],

      if (photo1 != null || photo2 != null || photo3 != null) ...[

        pw.SizedBox(height: 20),

        _buildModernAttachmentsHeader(fontBold),

        pw.SizedBox(height: 20),

        pw.Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [

            if (photo1 != null)
              pw.Container(
                width: 240,
                child: _buildModernPhotoCard(photo1, "PHOTO 1"),
              ),

            if (photo2 != null)
              pw.Container(
                width: 240,
                child: _buildModernPhotoCard(photo2, "PHOTO 2"),
              ),

            if (photo3 != null)
              pw.Container(
                width: 240,
                child: _buildModernPhotoCard(photo3, "PHOTO 3"),
              ),
          ],
        ),
      ],
    ],
  ),
);
}

final bytes = await pdf.save();

final sheetId = data['sheetId'] ?? 'service_report';

final rawId = data['sheetId'] ?? 'service_report';

final safeId = rawId
    .toString()
    .replaceAll(RegExp(r'[^\w\-]'), '_');

await openPdf(
  bytes,
  "$safeId.pdf",
);
}

// ================= MODERN UI COMPONENTS =================

static pw.Widget _buildModernHeader(
  Map<String, dynamic> data,
  Uint8List logo,
  DateFormat df,
  pw.Font bold,
) {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  final lightOrange = PdfColor.fromInt(0xFFFFF0E6);
  
  // Format sheet ID agar tampil lengkap
  String sheetId = data['sheetId'] ?? 'NEW';
  if (sheetId.length > 20) {
    sheetId = sheetId.substring(0, 20); // Tampilkan 20 karakter pertama
  }
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        begin: pw.Alignment.centerLeft,
        end: pw.Alignment.centerRight,
        colors: [
          PdfColor.fromInt(0xFFF5F5F5),
          PdfColors.white,
        ],
      ),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    padding: const pw.EdgeInsets.all(12),
    child: pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Image(
                pw.MemoryImage(logo),
                height: 50,
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "SERVICE REPORT",
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 20,
                      color: orangeColor,
                    ),
                  ),
                  pw.Text(
                    "On-Site Service Documentation",
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: lightOrange,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: orangeColor,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    "ID: $sheetId",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: orangeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _buildInfoChip(
              "Technician",
              [
                data['technician1'],
                data['technician2'],
                data['technician3']
              ].where((e) => e != null && e.toString().isNotEmpty).join(", "),
            ),
            pw.SizedBox(width: 16),
            _buildInfoChip(
              "Start",
              _formatDate(data['startDate'], df),
            ),
            pw.SizedBox(width: 16),
            _buildInfoChip(
              "End",
              _formatDate(data['endDate'], df),
            ),
          ],
        ),
      ],
    ),
  );
}

static pw.Widget _buildInfoChip(String label, String value) {
  return pw.Row(
    children: [
      pw.Container(
        width: 4,
        height: 4,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFFF6A13),
          shape: pw.BoxShape.circle,
        ),
      ),
      pw.SizedBox(width: 4),
      pw.Text(
        "$label: ",
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
      pw.Text(
        value.isEmpty ? "-" : value,
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey900,
        ),
      ),
    ],
  );
}

static pw.Widget _buildModernInfoGrid(Map<String, dynamic> data) {
  final lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: lightGrey,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    ),
    padding: const pw.EdgeInsets.all(12),
    child: pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: _buildInfoColumn(
  "CUSTOMER",
  [
    _buildInfoRow("Name", data['factory']),
    _buildInfoRow("Address", data['factoryAddress']),
    _buildInfoRow("End Customer", data['endCustomer']),
    _buildInfoRow("City/Country", _formatCityCountry(data)),
    _buildInfoRow("Customer Code", data['customerCode']),
  ],
),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              flex: 1,
              child: _buildInfoColumn(
                "ON BEHALF OF",
                [
                  _buildInfoRow("Name", "PT. ATOM INDONESIA RAYA"),
                  _buildInfoRow("Address", "Plaza Niaga 1 Blok B No.2, Sentul City, Kel. Citaringgul, Kec. Babakan-Madang, Kab. Bogor, West Java, Indonesia, Pstal Code 16810"),
                  _buildInfoRow("Phone", "+62 21 87962621"),
                  _buildInfoRow("VAT No.", "94.729.653.9-403.000"),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
      ],
    ),
  );
}

static String _formatCityCountry(Map<String, dynamic> data) {
  final city = data['factoryCity'] ?? '';
  final country = data['factoryCountry'] ?? '';
  if (city.isEmpty && country.isEmpty) return "-";
  return "$city${country.isNotEmpty ? ' / $country' : ''}";
}

static pw.Widget _buildInfoColumn(String title, List<pw.Widget> rows) {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: orangeColor,
        ),
      ),
      pw.SizedBox(height: 6),
      ...rows,
    ],
  );
}

static pw.Widget _buildInfoRow(String label, String? value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 70,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.Text(
          ":",
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            value?.isNotEmpty == true ? value! : "-",
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _buildModernMachineSection(Map<String, dynamic> data) {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  final lightOrange = PdfColor.fromInt(0xFFFFF0E6);
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        colors: [
          lightOrange,
          PdfColors.white,
        ],
      ),
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    ),
    padding: const pw.EdgeInsets.all(12),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildMachineSpec("Machine Type", data['machine'], orangeColor),
        _buildVerticalDivider(),
        _buildMachineSpec("Serial Number", data['serialNumber'], orangeColor),
        _buildVerticalDivider(),
        _buildMachineSpec("Asset Number", data['assetNumber'], orangeColor),
      ],
    ),
  );
}

static pw.Widget _buildMachineSpec(String label, String? value, PdfColor orangeColor) {
  return pw.Expanded(
    child: pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value?.isNotEmpty == true ? value! : "-",
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: orangeColor,
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _buildVerticalDivider() {
  return pw.Container(
    height: 30,
    width: 1,
    color: PdfColors.grey300,
    margin: const pw.EdgeInsets.symmetric(horizontal: 8),
  );
}

static pw.Widget _buildModernProblemSection(Map<String, dynamic> data, pw.Font bold) {
  return _buildModernTextSection(
    "PROBLEM DESCRIPTION",
    data['problemDescription'],
    bold,
  );
}

static pw.Widget _buildModernActivitySection(Map<String, dynamic> data, pw.Font bold) {
  return _buildModernTextSection(
    "WORK CARRIED OUT",
    data['activity'],
    bold,
  );
}

static pw.Widget _buildModernTextSection(
  String title,
  String? text,
  pw.Font bold, {
  int? maxLines,
}) {
  final lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    ),
    padding: const pw.EdgeInsets.all(12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 16,
              color: orangeColor,
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              title,
              style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                color: orangeColor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: lightGrey,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
  text ?? "-",
  style: pw.TextStyle(
    fontSize: 9,
    height: 1.5,
  ),
  maxLines: maxLines,
),
        ),
      ],
    ),
  );
}

static pw.Widget _buildModernSparePartsSection(List parts, pw.Font bold) {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  final lightOrange = PdfColor.fromInt(0xFFFFF0E6);
  final lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  
  if (parts.isEmpty) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Text(
        "No spare parts used",
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  return pw.Container(
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: lightOrange,
            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 16,
                color: orangeColor,
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                "SPARE PARTS USED",
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 10,
                  color: orangeColor,
                ),
              ),
            ],
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: orangeColor,
              ),
              children: [
                _buildModernTableHeader("PART CODE"),
                _buildModernTableHeader("DESCRIPTION"),
                _buildModernTableHeader("QTY"),
              ],
            ),
            ...parts.map(
              (p) => pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                ),
                children: [
                  _buildModernTableCell(p['partCode'] ?? "-"),
                  _buildModernTableCell(p['name'] ?? "-"),
                  _buildModernTableCell("${p['qty'] ?? 1}", alignment: pw.Alignment.center),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

static pw.Widget _buildModernTableHeader(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );
}

static pw.Widget _buildModernTableCell(String text, {pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Align(
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8),
      ),
    ),
  );
}

static pw.Widget _buildModernNoteSection(Map<String, dynamic> data, pw.Font bold) {
  final note = data['noteForCustomer'];
  if (note == null || note.toString().isEmpty) {
    return pw.SizedBox.shrink();
  }

  final lightGreen = PdfColor.fromInt(0xFFE8F5E9);
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        colors: [
          lightGreen,
          PdfColors.white,
        ],
      ),
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.green200, width: 0.5),
    ),
    padding: const pw.EdgeInsets.all(12),
    child: pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 40,
          color: PdfColors.green700,
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "NOTE FOR CUSTOMER",
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 9,
                  color: PdfColors.green700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                safeText(note, maxChars: 200),
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _buildModernFooter(Map<String, dynamic> data, pw.MemoryImage? signatureImage) {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  final lightOrange = PdfColor.fromInt(0xFFFFF0E6);
  final lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  
  return pw.Container(
    decoration: pw.BoxDecoration(
  color: PdfColors.white,
),
    padding: const pw.EdgeInsets.all(12),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildPersonInfo("Created By", data['createdByName'] ?? data['createdBy']),
            _buildPersonInfo("Submitted By", data['submittedByName'] ?? data['submittedBy']),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            "Confirmed that all work performed and materials used are documented in this service report.",
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
  width: 220,
  decoration: pw.BoxDecoration(
    border: pw.Border.all(
      color: PdfColors.grey400,
      width: 0.7,
    ),
    borderRadius: pw.BorderRadius.circular(6),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: lightOrange,
                    borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
                  ),
                  child: pw.Text(
                    "CUSTOMER SIGNATURE",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: orangeColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  height: 60,
                  padding: const pw.EdgeInsets.all(8),
                  child: signatureImage != null
                      ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                      : pw.Center(
                          child: pw.Text(
                            "No Signature",
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey500,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ),
                ),
                pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.all(6),
  child: pw.Text(
                    data['customerName'] ?? '-',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _buildPersonInfo(String label, String? name) {
  return pw.Row(
    children: [
      pw.Container(
        width: 20,
        height: 20,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFFFF0E6),
          shape: pw.BoxShape.circle,
        ),
        child: pw.Center(
          child: pw.Text(
            "U",
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFFFF6A13),
            ),
          ),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            name?.isNotEmpty == true ? name! : "-",
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

static pw.Widget _buildModernAttachmentsHeader(pw.Font bold) {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  
  return pw.Row(
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: orangeColor,
          shape: pw.BoxShape.circle,
        ),
        child: pw.Text(
          "A",
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
      pw.SizedBox(width: 12),
      pw.Text(
        "ATTACHMENTS & DOCUMENTATION",
        style: pw.TextStyle(
          font: bold,
          fontSize: 14,
          color: orangeColor,
        ),
      ),
    ],
  );
}

static pw.Widget _buildModernPhotoCard(pw.MemoryImage image, String label) {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  final lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: PdfColors.grey300, width: 1),
    ),
    child: pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: lightGrey,
            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(12)),
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: orangeColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Image(image, height: 200, fit: pw.BoxFit.contain),
        ),
      ],
    ),
  );
}

static pw.Widget _buildModernVideoSection(String? videoUrl, pw.Font bold) {
  if (videoUrl == null || videoUrl.isEmpty) return pw.SizedBox.shrink();
  
  final lightBlue = PdfColor.fromInt(0xFFE3F2FD);
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        colors: [
          lightBlue,
          PdfColors.white,
        ],
      ),
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: PdfColors.blue200, width: 1),
    ),
    padding: const pw.EdgeInsets.all(16),
    child: pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Text(
                "V",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              "VIDEO DOCUMENTATION",
              style: pw.TextStyle(
                font: bold,
                fontSize: 11,
                color: PdfColors.blue700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  videoUrl,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blue700,
                  ),
                  maxLines: 2,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  "LINK",
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _buildModernDivider() {
  final orangeColor = PdfColor.fromInt(0xFFFF6A13);
  
  return pw.Container(
    height: 1,
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        colors: [
          PdfColors.white,
          orangeColor,
          PdfColors.white,
        ],
      ),
    ),
  );
}

// ================= ORIGINAL HELPER METHODS =================

static String safeText(String? text, {int maxChars = 600}) {
  if (text == null) return "-";
  if (text.length <= maxChars) return text;
  return text.substring(0, maxChars) + "...";
}

static String _formatDate(dynamic date, DateFormat df) {
  if (date == null) return "-";
  if (date is Timestamp) {
    return df.format(date.toDate());
  }
  if (date is DateTime) {
    return df.format(date);
  }
  return "-";
}
}