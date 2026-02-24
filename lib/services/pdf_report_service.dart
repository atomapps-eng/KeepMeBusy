import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../attendance/models/attendance_day.dart';
import '../attendance/attendance_summary/attendance_summary_model.dart';

class PdfReportService {
  static Future<void> generateAndPreview({
    required String employeeId,
    required String employeeName,
    required String period,
    required List<AttendanceDay> attendanceDays,
    required AttendanceSummaryModel summary,
  }) async {

    final pdf = pw.Document();

    final logo = await rootBundle.load('assets/images/atom.png');
    final fontRegular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    final totalDays = summary.present +
        summary.off +
        summary.sickLeave +
        summary.annualLeave +
        summary.traveling +
        summary.joinHoliday;

    final attendanceRate =
        totalDays == 0 ? 0 : ((summary.present / totalDays) * 100).round();

    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Confidential - Company Internal Use"),
            pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
            ),
          ],
        ),
        build: (context) => [

          /// HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Image(
                    pw.MemoryImage(logo.buffer.asUint8List()),
                    height: 50,
                  ),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "ATTENDANCE REPORT",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(period),
                    ],
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      "$attendanceRate%",
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text("Attendance Rate"),
                  ],
                ),
              )
            ],
          ),

          pw.SizedBox(height: 25),

          /// EMPLOYEE INFO
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Employee ID: $employeeId"),
                pw.Text("Employee Name: $employeeName"),
                pw.Text("Total Days: $totalDays"),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          /// SUMMARY CARDS
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryCard("Present", summary.present, PdfColors.green),
              _summaryCard("Off", summary.off, PdfColors.grey),
              _summaryCard("Sick", summary.sickLeave, PdfColors.orange),
              _summaryCard("Annual", summary.annualLeave, PdfColors.blue),
              _summaryCard("Travel", summary.traveling, PdfColors.purple),
              _summaryCard("Holiday", summary.joinHoliday, PdfColors.pink),
            ],
          ),

          pw.SizedBox(height: 30),

          /// BAR CHART
          pw.Text(
            "Attendance Distribution",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            children: [
              _bar(summary.present, totalDays, PdfColors.green),
              _bar(summary.off, totalDays, PdfColors.grey),
              _bar(summary.sickLeave, totalDays, PdfColors.orange),
              _bar(summary.annualLeave, totalDays, PdfColors.blue),
              _bar(summary.traveling, totalDays, PdfColors.purple),
              _bar(summary.joinHoliday, totalDays, PdfColors.pink),
            ],
          ),

          pw.SizedBox(height: 30),

          /// TABLE
          pw.Text(
            "Attendance Details",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _header("Date"),
                  _header("Status"),
                  _header("Location"),
                ],
              ),
              ...attendanceDays.map((d) => pw.TableRow(
                    children: [
                      _cell(dateFormat.format(d.date)),
                      _statusCell(d.status.label),
                      _cell(d.location.name),
                    ],
                  )),
            ],
          ),

          pw.SizedBox(height: 50),

          /// SIGNATURE
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    height: 1,
                    width: 200,
                    color: PdfColors.grey600,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text("HR Manager Signature"),
                ],
              )
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _summaryCard(
      String label, int value, PdfColor color) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value.toString(),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(label),
        ],
      ),
    );
  }

  static pw.Widget _bar(int value, int total, PdfColor color) {
  final percent = total == 0 ? 0.0 : value / total;

  return pw.Expanded(
    child: pw.Container(
      height: 20,
      margin: const pw.EdgeInsets.symmetric(horizontal: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: percent * 200, // 200 = max width scale
            height: 20,
            color: color,
          ),
        ],
      ),
    ),
  );
}

  static pw.Widget _header(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text),
    );
  }

  static pw.Widget _statusCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.blue800),
      ),
    );
  }
}