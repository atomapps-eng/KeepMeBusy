import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../attendance/models/attendance_day.dart';
import '../attendance/attendance_summary/attendance_summary_model.dart';
import '../attendance/services/attendance_summary_helper.dart';
import '../attendance/models/activity_entry.dart';

class PdfReportService {
  static Future<Uint8List> generatePdf({
    required String employeeId,
    required String employeeName,
    required String period,
    required List<AttendanceDay> attendanceDays,
    required AttendanceSummaryModel summary,
    required List<ActivityEntry> activities,
  }) async {

    final pdf = pw.Document();

    final logo = await rootBundle.load('assets/images/Atom.png');
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
    
    final effectivePresent = summary.present + summary.traveling;

final attendanceRate =
    totalDays == 0 ? 0 : ((effectivePresent / totalDays) * 100).round();

    final dateFormat = DateFormat('dd MMM yyyy');
    final exportTime = DateFormat('dd MMM yyyy HH:mm')
    .format(DateTime.now());

    pdf.addPage(

  pw.Page(
    pageFormat: PdfPageFormat.a4.landscape,
    theme: pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    ),
    build: (context) => pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Image(
            pw.MemoryImage(logo.buffer.asUint8List()),
            height: 80,
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            "ATTENDANCE REPORT",
            style: pw.TextStyle(
              fontSize: 36,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            period,
            style: const pw.TextStyle(fontSize: 20),
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            employeeName,
            style: pw.TextStyle(
              fontSize: 26,
              font: fontBold,
            ),
          ),
          pw.Text("Employee ID: $employeeId"),
        ],
      ),
    ),
  ),
);

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
                          font: fontBold,
                        ),
                      ),
                      pw.Text(period),
                      pw.Text(
  "Exported: $exportTime",
  style: const pw.TextStyle(fontSize: 10),
),
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
                        font: fontBold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text("Attendance Rate"),
                  ],
                ),
              )
            ],
          ),

          pw.SizedBox(height: 30),

pw.Text(
  "Attendance Overview",
  style: pw.TextStyle(
    font: fontBold,
    fontSize: 14,
  ),
),

pw.SizedBox(height: 10),

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
              _summaryCard("Office", summary.office, PdfColors.blueGrey),
              _summaryCard("Outstation", summary.outstation, PdfColors.deepOrange),
            ],
          ),

          pw.SizedBox(height: 30),

          pw.SizedBox(height: 10),

          pw.SizedBox(height: 30),

          /// TABLE
          pw.Text(
            "Attendance Details",
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
            ),
          ),

          pw.SizedBox(height: 10),

         pw.TableHelper.fromTextArray(
  border: pw.TableBorder.all(color: PdfColors.grey300),
  headerStyle: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 10,
    color: PdfColors.white,
  ),
  headerDecoration: pw.BoxDecoration(
  color: PdfColor.fromHex('#F28C28'),
),
  headerAlignments: {
    0: pw.Alignment.center,
    1: pw.Alignment.center,
    2: pw.Alignment.center,
    3: pw.Alignment.center,
    4: pw.Alignment.center,
    5: pw.Alignment.center,
    6: pw.Alignment.center,
  },
  cellStyle: const pw.TextStyle(
    fontSize: 9,
  ),
   cellAlignments: {
  0: pw.Alignment.center,
  1: pw.Alignment.center,
  2: pw.Alignment.center,
  3: pw.Alignment.center,
  4: pw.Alignment.center,
  5: pw.Alignment.center,
  6: pw.Alignment.center,
},
  columnWidths: {
    0: const pw.FlexColumnWidth(1.5),
    1: const pw.FlexColumnWidth(1.5),
    2: const pw.FlexColumnWidth(1.1),
    3: const pw.FlexColumnWidth(1.8),
    4: const pw.FlexColumnWidth(1.2),
    5: const pw.FlexColumnWidth(1.2),
    6: const pw.FlexColumnWidth(1),
  },

  headers: [
    "Date",
    "Status",
    "Location",
    "Client",
    "Check In",
    "Check Out",
    "Overtime",
  ],

  data: attendanceDays
      .where((d) => d.period == period)
      .map((d) {
    final checkIn = _formatTime(d.checkInHour, d.checkInMinute);
    final checkOut = _formatTime(d.checkOutHour, d.checkOutMinute);
    final isOvertime = AttendanceSummaryHelper.isOvertimeDay(d);

    return [
      dateFormat.format(d.date),
      d.status.label,
      d.location.name.toLowerCase() == "outstation"
          ? "Outstation"
          : "Office",
      d.location.name.toLowerCase() == "outstation"
          ? (d.customerName ?? "-")
          : "-",
      checkIn,
      checkOut,
      isOvertime ? "YES" : "-",
    ];
  }).toList(),
),

pw.SizedBox(height: 30),

pw.Text(
  "Overnight Details",
  style: pw.TextStyle(
    font: fontBold,
    fontSize: 14,
  ),
),

pw.SizedBox(height: 10),

summary.overnights.isEmpty
    ? pw.Text("No overnight records")
    : pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2),
          4: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F28C28'),
            ),
            children: [
              _headerCell("Location"),
              _headerCell("Customer"),
              _headerCell("Start Date"),
              _headerCell("End Date"),
              _headerCell("Nights"),
            ],
          ),

          ...summary.overnights.map((o) {
            return pw.TableRow(
              children: [
                _cell(o.location),
                _cell(o.customer),
                _cell(dateFormat.format(o.startDate)),
                _cell(dateFormat.format(o.endDate)),
                _cell(o.nights.toString()),
              ],
            );
          }),
        ],
      ),

      pw.SizedBox(height: 30),

..._buildActivityTable(activities),

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
        pw.Text("General Admin"),
      ],
    )
  ],
),
        ],
      ),
    );
    return pdf.save();
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
    child: pw.Center(
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    ),
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
  static String _formatTime(int? h, int? m) {
  if (h == null) return "-";
  return "${h.toString().padLeft(2, '0')}:${(m ?? 0).toString().padLeft(2, '0')}";
}

static String _buildLocationText(AttendanceDay d) {
  if (d.location.name.toLowerCase() == "outstation") {
    if (d.customerName != null && d.customerName!.isNotEmpty) {
      return "Outstation - ${d.customerName}";
    }
    return "Outstation";
  }

  return "Office";
}

static pw.Widget _headerCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
    ),
  );
}

static List<pw.Widget> _buildActivityTable(List<ActivityEntry> activities) {
  if (activities.isEmpty) {
    return [
      pw.SizedBox(height: 30),
      pw.Text(
        "Activity List",
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Center(
          child: pw.Text(
            "No activity data",
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    ];
  }

  return [
    pw.SizedBox(height: 30),
    pw.Text(
      "Activity List",
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
    pw.SizedBox(height: 10),

    pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
  color: PdfColor.fromHex('#F28C28'),
),
      cellStyle: const pw.TextStyle(
        fontSize: 9,
      ),
      columnWidths: {
  0: const pw.FlexColumnWidth(1.2),  // Date
  1: const pw.FlexColumnWidth(1.3),  // Activity
  2: const pw.FlexColumnWidth(1.5),  // Client
  3: const pw.FlexColumnWidth(1.5),  // Machine
  4: const pw.FlexColumnWidth(1.4),    // 🔥 Serial Number (diperkecil)
  5: const pw.FlexColumnWidth(2.5),  // Description
  6: const pw.FlexColumnWidth(2),    // Note
},
      headers: [
        "Date",
        "Activity",
        "Client",
        "Machine",
        "Serial Number",
        "Description",
        "Note",
      ],
      data: activities.map((a) {
  final dateFormat = DateFormat('dd/MM/yyyy');

  return [
    _centerText(dateFormat.format(a.date)),
    _centerText(a.activityType ?? '-'),
    _centerText(a.factoryClient ?? '-'),
    _centerText(a.machine ?? '-'),
    _centerText(a.serialNumber ?? '-'),
    _centerText((a.description?.isEmpty ?? true) ? "-" : a.description!),
    _centerText((a.note?.isEmpty ?? true) ? "-" : a.note!),
  ];
}).toList(),
    ),
  ];
}

static pw.Widget _centerText(String text) {
  return pw.Center(
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
    ),
  );
}

}