import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceReportPdfService {
static Future<Uint8List> generatePdf({
  required Map<String, dynamic> data,
}) async {
  final pdf = pw.Document();

  final fontRegular = pw.Font.ttf(
  await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
);

final fontBold = pw.Font.ttf(
  await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
);

  final logoBytes =
      (await rootBundle.load('assets/images/ATOM_INDO.png')).buffer.asUint8List();

  final df = DateFormat('dd/MM/yyyy');

  // ================= IMAGES =================

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

  // ================= SAFETY LIMITS =================

  String safeText(String? text, {int maxChars = 600}) {
    if (text == null) return "-";
    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars) + "...";
  }

  final parts = (data['spareParts'] as List?) ?? [];
  final limitedParts = parts.take(8).toList(); // max 8 rows page 1

  // ================= PAGE 1 (FIXED) =================

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(45, 25, 45, 35),
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      build: (context) {
  return pw.Stack(
    children: [

      // ================= CONTENT AREA =================
      pw.Positioned.fill(
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 150), 
          // <<< reserve space untuk signature block
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              _buildHeader(data, logoBytes, df, fontBold),

              pw.SizedBox(height: 8),
              _customerCompanyGrid(data),

              pw.SizedBox(height: 8),
              pw.Divider(),

              _machineRow(data),

              pw.SizedBox(height: 8),

              _sectionTitle("Problem Description", fontBold),
              pw.Text(
                safeText(data['problemDescription'], maxChars: 400),
                style: pw.TextStyle(fontSize: 10),
              ),

              pw.SizedBox(height: 8),

              _sectionTitle("Description of the work carried out", fontBold),
              pw.Text(
                safeText(data['activity'], maxChars: 500),
                style: pw.TextStyle(fontSize: 10),
              ),

              pw.SizedBox(height: 8),

              _sectionTitle("Spare Parts Used", fontBold),
              _sparePartTableLimited(limitedParts),

              pw.SizedBox(height: 8),

              _sectionTitle("Note For Customer", fontBold),
              pw.Text(
                safeText(data['noteForCustomer'], maxChars: 250),
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),

      // ================= FIXED BOTTOM AREA =================
      pw.Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Created By : ${data['createdByName'] ?? data['createdBy'] ?? '-'}",
                    style: pw.TextStyle(fontSize:10),
                  ),
                  pw.Text(
                    "Submitted By : ${data['submittedByName'] ?? data['submittedBy'] ?? '-'}",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(),

              pw.SizedBox(height: 8),

              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Confirmed that the technician had spent the time and use the parts above indicated",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        "Customer Signature",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        height: 60,
                        decoration: signatureImage == null
                            ? pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: PdfColors.grey400),
                              )
                            : null,
                        child: signatureImage != null
                            ? pw.Image(signatureImage,
                                fit: pw.BoxFit.contain)
                            : null,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        data['customerName'] ?? '-',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
    ),
  );

  // ================= PAGE 2 (ATTACHMENTS ONLY) =================

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 50, 50, 40),
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      build: (_) => [

        _sectionTitle("ATTACHMENTS", fontBold),
        pw.SizedBox(height: 15),

        if (photo1 != null) ...[
  pw.Image(photo1, height: 180, fit: pw.BoxFit.contain),
  pw.SizedBox(height: 12),
],

if (photo2 != null) ...[
  pw.Image(photo2, height: 180, fit: pw.BoxFit.contain),
  pw.SizedBox(height: 12),
],

if (photo3 != null) ...[
  pw.Image(photo3, height: 180, fit: pw.BoxFit.contain),
  pw.SizedBox(height: 12),
],

        pw.SizedBox(height: 10),

        pw.Text(
          "VIDEO DOCUMENTING FINDINGS DURING SERVICE",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),

        pw.SizedBox(height: 4),

        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Text(
            data['video'] ?? "-",
            style: pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

static pw.Widget _sparePartTableLimited(List parts) {
  if (parts.isEmpty) {
    return pw.Text("-", style: pw.TextStyle(fontSize: 10));
  }

 return pw.Table(
  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),

  columnWidths: {
    0: const pw.FixedColumnWidth(65),     // PART CODE lebih sempit
    1: const pw.FlexColumnWidth(3),       // DESCRIPTION fleksibel & dominan
    2: const pw.FixedColumnWidth(35),     // QTY kecil
  },

  children: [
    pw.TableRow(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFF6A13),
      ),
      children: [
        _tableHeaderCell("PART CODE"),
        _tableHeaderCell("PART DESCRIPTION"),
        pw.Center(child: _tableHeaderCell("QTY")),
      ],
    ),

    ...parts.map(
      (p) => pw.TableRow(
        children: [
          _tableCell(p['partCode'] ?? "-", false),
          _tableCell(p['name'] ?? "-", false),

          // QTY rata tengah
          pw.Center(
            child: _tableCell("${p['qty'] ?? 1}", false),
          ),
        ],
      ),
    ),
  ],
);
}

  // ================= HEADER =================

static pw.Widget _buildHeader(
  Map<String, dynamic> data,
  Uint8List logo,
  DateFormat df,
  pw.Font bold,
) {
  return pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [

    // ===== ROW 1: LOGO + SHEET ID =====
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(
          pw.MemoryImage(logo),
          height: 55, // logo lebih kecil
        ),
        pw.Spacer(),
        pw.Text(
          "Sheet Id : ${data['sheetId'] ?? '-'}",
          style: pw.TextStyle(
            font: bold,
            fontSize: 10,
          ),
        ),
      ],
    ),

    pw.SizedBox(height: 4),   // <<< diperkecil
    pw.Divider(thickness: 0.8),
    pw.SizedBox(height: 4),   // <<< diperkecil

    // ===== ROW 2: ON SITE AREA =====
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        // Accent bar lebih pendek
        pw.Container(
          width: 3,
          height: 28,
          color: PdfColor.fromInt(0xFFFF6A13),
        ),

        pw.SizedBox(width: 6),

        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Text(
              "ON-SITE SERVICES",
              style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                color: PdfColor.fromInt(0xFFFF6A13),
              ),
            ),

            pw.SizedBox(height: 2),

            pw.Row(
              children: [
                pw.Text(
                  "Technician : ",
                  style: pw.TextStyle(font: bold, fontSize: 10),
                ),
                pw.Text(
                  [
                    data['technician1'],
                    data['technician2'],
                    data['technician3']
                  ]
                      .where((e) => e != null && e.toString().isNotEmpty)
                      .join(", ")
                      .isEmpty
                      ? "-"
                      : [
                          data['technician1'],
                          data['technician2'],
                          data['technician3']
                        ]
                            .where((e) =>
                                e != null && e.toString().isNotEmpty)
                            .join(", "),
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),

        pw.Spacer(),

        pw.Row(
          children: [
            pw.Text(
              "Start : ",
              style: pw.TextStyle(font: bold, fontSize: 10),
            ),
            pw.Text(
              _formatDate(data['startDate'], df),
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              "End : ",
              style: pw.TextStyle(font: bold, fontSize: 10),
            ),
            pw.Text(
              _formatDate(data['endDate'], df),
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    ),

    pw.SizedBox(height: 4),  // <<< diperkecil
    pw.Divider(thickness: 0.8),
  ],
);
}

  // ================= GRID =================

  static pw.Widget _customerCompanyGrid(Map<String, dynamic> data) {
  return pw.Table(
    columnWidths: {
      0: const pw.FlexColumnWidth(1.2),
      1: const pw.FixedColumnWidth(10),
      2: const pw.FlexColumnWidth(1.8),
      3: const pw.FlexColumnWidth(1.2),
      4: const pw.FixedColumnWidth(10),
      5: const pw.FlexColumnWidth(1.8),
    },
    children: [

  // Row 1
  _gridRow(
    "Customer Name",
    data['factory'],
    "Company Name",
    "PT. ATOM INDONESIA RAYA",
  ),

  // Row 2
  _gridRow(
  "Address",
  data['factoryAddress'],
  "Address",
  "Plaza Niaga 1 Blok B No.2, Sentul City, Kel. Citaringgul, Kec. Babakan Madang, Kab. Bogor, West Java, Indonesia 16810",
  justifyLeft: true,
  justifyRight: true,
),

  // Row 3
  _gridRow(
    "End Customer",
    data['endCustomer'],
    "Phone",
    "+62 21 87962621",
  ),

  // Row 4
  _gridRow(
    "City / Country",
    "${data['factoryCity'] ?? ''}${data['factoryCountry'] != null ? ' / ${data['factoryCountry']}' : ''}".isEmpty
        ? "-"
        : "${data['factoryCity'] ?? ''}${data['factoryCountry'] != null ? ' / ${data['factoryCountry']}' : ''}",
    "VAT No.",
    "94.729.653.9-403.000",
  ),

  // Row 5
  pw.TableRow(
    children: [
      _gridCell("Customer Code", true),
      _gridCell(":", true),
      _gridCell(data['customerCode'] ?? "-", false),

      _gridCell("", true),
      _gridCell("", true),
      _gridCell("", false),
    ],
  ),
],
  );
}

  static pw.TableRow _gridRow(
  String l1,
  String? v1,
  String l2,
  String? v2, {
  bool justifyLeft = false,
  bool justifyRight = false,
}) {
  return pw.TableRow(
    children: [
      _gridCell(l1, true),
      _gridCell(":", true),
      _gridCell(v1 ?? "-", false, justify: justifyLeft),

      _gridCell(l2, true),
      _gridCell(":", true),
      _gridCell(v2 ?? "-", false, justify: justifyRight),
    ],
  );
}

  static pw.Widget _gridCell(
  String text,
  bool isLabel, {
  bool justify = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Text(
      text,
      textAlign: justify ? pw.TextAlign.justify : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight:
            isLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

  // ================= MACHINE =================

  static pw.Widget _machineRow(Map<String, dynamic> data) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [

        _machineItem("Machine Type", data['machine']),
        _machineItem("Serial Number", data['serialNumber']),
        _machineItem("Asset Number", data['assetNumber']),

      ],
    ),
  );
}

static pw.Widget _machineItem(String label, String? value) {
  return pw.Row(
    children: [
      pw.Text(
        "$label : ",
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.Text(
        value ?? "-",
        style: pw.TextStyle(fontSize: 10),
      ),
    ],
  );
}

  // ================= SPARE PART =================

  static pw.Widget _sparePartTable(Map<String, dynamic> data) {
    final parts = data['spareParts'] as List?;
    if (parts == null || parts.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Text("-", style: const pw.TextStyle(fontSize: 10)),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
      children: [
       pw.TableRow(
  decoration: pw.BoxDecoration(
    color: PdfColor.fromInt(0xFFFF6A13), // orange corporate
  ),
  children: [
    _tableHeaderCell("PART CODE"),
    _tableHeaderCell("PART DESCRIPTION"),
    _tableHeaderCell("QTY"),
  ],
),
        ...parts.map(
          (p) => pw.TableRow(
            children: [
              _tableCell(p['partCode'] ?? "-", false),
              _tableCell(p['name'] ?? "-", false),
              _tableCell("${p['qty'] ?? 1}", false),
            ],
          ),
        ),
      ],
    );
  }

 static pw.Widget _tableCell(String text, bool bold) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

static pw.Widget _tableHeaderCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white, // kontras dengan orange
      ),
    ),
  );
}

static pw.Widget _sectionTitle(String title, pw.Font bold) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      "$title:",
      style: pw.TextStyle(
        font: bold,
        fontSize: 10, // <<< sama dengan Customer Name / Company Name
      ),
    ),
  );
}

  static pw.Widget _divider() {
    return pw.Container(height: 1, color: PdfColors.grey500);
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