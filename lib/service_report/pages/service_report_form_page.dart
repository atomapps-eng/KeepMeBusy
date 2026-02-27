import 'package:flutter/material.dart';
import '../services/service_report_firestore.dart';
import '../../core/session/company_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import 'dart:io'; // Untuk File
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'signature_page.dart';
import '../../main.dart';

class ServiceReportFormPage extends StatefulWidget {
  final String? reportId; // Jika null berarti create baru, jika ada berarti edit
  
  const ServiceReportFormPage({super.key, this.reportId});

  @override
  State<ServiceReportFormPage> createState() => _ServiceReportFormPageState();
}

class _ServiceReportFormPageState
    extends State<ServiceReportFormPage> {
      bool _isSaving = false;
      bool _isLoading = false;
      String? _currentReportId;
  // BASIC
  DateTime? startDate;
  DateTime? endDate;
  String? factory;
  String? endCustomer;
  final customerCodeController = TextEditingController();

  // MACHINE
  final machineController = TextEditingController();
  final serialController = TextEditingController();
  final assetController = TextEditingController();

  // DESCRIPTION
  final problemController = TextEditingController();
  final activityController = TextEditingController();
  final noteController = TextEditingController();

  // TECHNICIAN
  String? tech1;
  String? tech2;
  String? tech3;

  // CUSTOMER
  final customerNameController = TextEditingController();

  // SPARE PART
  List<Map<String, dynamic>> spareParts = [];

  // DUMMY DATA
  final partners = ["PT ORISOL", "PT POUCHEN", "PT ATOM"];
  final technicians = ["Basuki", "Agus", "Rudi"];

  // MEDIA
XFile? _photo1; // Ubah dari File? menjadi XFile?
XFile? _photo2;
XFile? _photo3;
XFile? _video;
XFile? _signature;
String? _signatureUrl;
String? _photo1Url; // Ubah nama dari PublicId ke Url
String? _photo2Url;
String? _photo3Url;
String? _videoUrl;
bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentReportId = widget.reportId;
    if (_currentReportId != null) {
      _loadReportData();
    }
  }
  
  // Di dalam class _ServiceReportFormPageState

Future<void> _loadReportData() async {
  if (_currentReportId == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    // Ambil data dari Firestore
    final doc = await ServiceReportFirestore.getReport(_currentReportId!);
    
    if (!mounted) return;

    final data = doc.data();
    if (data == null) return;

    // Isi semua controller dan variable dengan data yang ada
    setState(() {
      // BASIC INFO
      if (data['startDate'] != null) {
        startDate = (data['startDate'] as Timestamp).toDate();
      }
      if (data['endDate'] != null) {
        endDate = (data['endDate'] as Timestamp).toDate();
      }
      factory = data['factory'];
      endCustomer = data['endCustomer'];
      customerCodeController.text = data['customerCode'] ?? '';

      // MACHINE
      machineController.text = data['machine'] ?? '';
      serialController.text = data['serialNumber'] ?? '';
      assetController.text = data['assetNumber'] ?? '';

      // DESCRIPTION
      problemController.text = data['problemDescription'] ?? '';
      activityController.text = data['activity'] ?? '';

      // NOTE
      noteController.text = data['noteForCustomer'] ?? '';

      // TECHNICIAN
      tech1 = data['technician1'];
      tech2 = data['technician2'];
      tech3 = data['technician3'];

      // CUSTOMER
      customerNameController.text = data['customerName'] ?? '';

      // SPARE PARTS
      if (data['spareParts'] != null) {
        spareParts = List<Map<String, dynamic>>.from(data['spareParts']);
      }

      // MEDIA
_photo1Url = data['photo1'];
_photo2Url = data['photo2'];
_photo3Url = data['photo3'];
_videoUrl = data['video'];
_signatureUrl = data['signature'];


// File lokal dikosongkan karena sudah terupload
_photo1 = null;
_photo2 = null;
_photo3 = null;
_video = null;
_signature = null;
      // TODO: SIGNATURE (nanti di step digital signature)

      _isLoading = false;
    });

  } catch (e) {
    print("Error loading report data: $e");
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error loading data: $e"),
        backgroundColor: Colors.red,
      ),
    );
    
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {

  if (_isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Service Report Form")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _card(_basicInfo(isDesktop)),
                const SizedBox(height: 20),
                _card(_machineSection(isDesktop)),
                const SizedBox(height: 20),
                _card(_descriptionSection()),
                const SizedBox(height: 20),
                _card(_sparePartSection()),
                const SizedBox(height: 20),
                _card(_noteSection()),
                const SizedBox(height: 20),
                _card(_technicianSection()),
                const SizedBox(height: 20),
                _card(_signatureSection()),
                const SizedBox(height: 20),
                _card(_mediaSection()),
                const SizedBox(height: 30),
                _actionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(Widget child) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  // ================= BASIC INFO =================

  Widget _basicInfo(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("BASIC INFORMATION",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        isDesktop
            ? Row(
                children: [
                  Expanded(child: _datePicker("Start Date", true)),
                  const SizedBox(width: 16),
                  Expanded(child: _datePicker("End Date", false)),
                ],
              )
            : Column(
                children: [
                  _datePicker("Start Date", true),
                  _datePicker("End Date", false),
                ],
              ),
        const SizedBox(height: 16),
        DropdownButtonFormField(
          value: factory,
          items: partners
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => factory = val),
          decoration: const InputDecoration(labelText: "Factory"),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField(
          value: endCustomer,
          items: partners
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) =>
              setState(() => endCustomer = val),
          decoration:
              const InputDecoration(labelText: "End Customer"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: customerCodeController,
          decoration:
              const InputDecoration(labelText: "Customer Code"),
        ),
      ],
    );
  }

  Widget _datePicker(String label, bool isStart) {
    return TextButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              startDate = picked;
            } else {
              endDate = picked;
            }
          });
        }
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$label: ${isStart ? startDate ?? '-' : endDate ?? '-'}",
        ),
      ),
    );
  }

  // ================= MACHINE =================

  Widget _machineSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MACHINE INFORMATION",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: machineController,
          decoration:
              const InputDecoration(labelText: "Machine"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: serialController,
          decoration:
              const InputDecoration(labelText: "Serial Number"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: assetController,
          decoration:
              const InputDecoration(labelText: "Asset Number"),
        ),
      ],
    );
  }

  // ================= DESCRIPTION =================

  Widget _descriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PROBLEM DESCRIPTION",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: problemController,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        const Text("ACTIVITY",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: activityController,
          maxLines: 4,
        ),
      ],
    );
  }

  // ================= SPARE PART =================

  Widget _sparePartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SPARE PART DURING SERVICE",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addSparePartDialog,
          child: const Text("+ Add Spare Part"),
        ),
        const SizedBox(height: 16),
        ...spareParts.map((part) => ListTile(
              title: Text(part["name"]),
              subtitle:
                  Text("Qty: ${part["qty"]}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    spareParts.remove(part);
                  });
                },
              ),
            ))
      ],
    );
  }

  void _addSparePartDialog() {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Spare Part"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("RAM Module"),
            TextField(
              controller: qtyController,
              decoration:
                  const InputDecoration(labelText: "Qty"),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                spareParts.add({
                  "name": "RAM Module",
                  "qty": qtyController.text
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // ================= TECHNICIAN =================

  Widget _technicianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TECHNICIANS",
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        DropdownButtonFormField(
          value: tech1,
          items: technicians
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) =>
              setState(() => tech1 = val),
          decoration:
              const InputDecoration(labelText: "Technician 1"),
        ),
        if (tech1 != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField(
            value: tech2,
            items: technicians
                .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) =>
                setState(() => tech2 = val),
            decoration: const InputDecoration(
                labelText: "Technician 2"),
          ),
        ],
        if (tech2 != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField(
            value: tech3,
            items: technicians
                .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) =>
                setState(() => tech3 = val),
            decoration: const InputDecoration(
                labelText: "Technician 3"),
          ),
        ],
      ],
    );
  }

  // ================= SIGNATURE =================

  // ================= SIGNATURE =================
// ================= SIGNATURE =================
Widget _signatureSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "CUSTOMER SIGNATURE",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 12),
      Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildSignaturePreview(),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_signature == null && _signatureUrl == null)
            ElevatedButton.icon(
              onPressed: _openSignaturePad,
              icon: const Icon(Icons.edit),
              label: const Text("Add Signature"),
            ),
          if (_signature != null || _signatureUrl != null)
            TextButton.icon(
              onPressed: _clearSignature,
              icon: const Icon(Icons.clear, color: Colors.red),
              label: const Text("Clear", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ],
  );
}

Widget _buildSignaturePreview() {
  if (_signature != null) {
    // Preview dari file lokal
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: _signature!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
            );
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    } else {
      return Image.file(
        File(_signature!.path),
        fit: BoxFit.contain,
      );
    }
  } else if (_signatureUrl != null) {
    // Preview dari Cloudinary
    return Image.network(
      _signatureUrl!,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(child: Text("Failed to load signature")),
    );
  } else {
    // Placeholder
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.draw, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text("No signature", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Di bagian method _openSignaturePad, ubah menjadi:

// Di service_report_form_page.dart, ganti method _openSignaturePad

// Di service_report_form_page.dart, ganti method _openSignaturePad

Future<void> _openSignaturePad() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SignaturePage(
        onSave: (Uint8List bytes) async {
          if (!mounted) return;

          setState(() {
            _isUploading = true;
          });

          try {
            final companyId = CompanySession.selectedCompanyId;
            if (companyId == null) {
              throw Exception("Company not selected");
            }

            final xfile = XFile.fromData(
              bytes,
              name: 'signature_${DateTime.now().millisecondsSinceEpoch}.png',
              mimeType: 'image/png',
            );

            final uploadedUrl = await CloudinaryService.uploadFile(
              file: xfile,
              folder: 'service_reports/$companyId/signatures',
            );

            if (!mounted) return;

            setState(() {
              _signatureUrl = uploadedUrl;
              _signature = null;
              _isUploading = false;
            });

            if (uploadedUrl != null) {
             rootScaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text("Signature uploaded successfully"),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              rootScaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text("Failed to upload signature"),
                  backgroundColor: Colors.orange,
                ),
              );
            }

          } catch (e) {
            if (!mounted) return;

            setState(() {
              _isUploading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    ),
  );
}

void _clearSignature() {
  setState(() {
    _signature = null;
    _signatureUrl = null;
  });
}

  // ================= MEDIA =================
Widget _mediaSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "MEDIA",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 12),
      
      // Photo 1
      // Photo 1
_mediaItem(
  title: "Photo 1",
  file: _photo1,
  publicId: _photo1Url, // Gunakan _photo1Url, bukan _photo1
  onPick: () => _pickImage(1),
  onClear: () => _clearImage(1),
),
const SizedBox(height: 12),

// Photo 2
_mediaItem(
  title: "Photo 2",
  file: _photo2,
  publicId: _photo2Url, // Gunakan _photo2Url
  onPick: () => _pickImage(2),
  onClear: () => _clearImage(2),
),
const SizedBox(height: 12),

// Photo 3
_mediaItem(
  title: "Photo 3",
  file: _photo3,
  publicId: _photo3Url, // Gunakan _photo3Url
  onPick: () => _pickImage(3),
  onClear: () => _clearImage(3),
),
const SizedBox(height: 12),

// Video
_mediaItem(
  title: "Video",
  file: _video,
  publicId: _videoUrl, // Gunakan _videoUrl
  onPick: _pickVideo,
  onClear: _clearVideo,
  isVideo: true,
),
      
      if (_isUploading)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: LinearProgressIndicator(),
        ),
    ],
  );
}

Widget _mediaItem({
  required String title,
  XFile? file,
  String? publicId,
  required VoidCallback onPick,
  required VoidCallback onClear,
  bool isVideo = false,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        // Preview
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
          ),
          child: _buildPreview(file, publicId, isVideo),
        ),
        
        // Info & buttons
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                if (file != null || publicId != null)
                  Text(
                    file != null ? "File selected" : "Uploaded",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  )
                else
                  Text(
                    "No file",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Buttons
        Row(
          children: [
            if (file == null && publicId == null)
              IconButton(
                icon: const Icon(Icons.add_photo_alternate),
                onPressed: onPick,
                tooltip: "Add $title",
              ),
            if (file != null || publicId != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: onClear,
                tooltip: "Remove",
              ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPreview(XFile? file, String? url, bool isVideo) {
  if (url != null) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
  
  if (file != null) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: file.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      return Image.file(File(file.path), fit: BoxFit.cover);
    }
  }
  
  return Icon(
    isVideo ? Icons.videocam : Icons.image,
    color: Colors.grey[400],
  );
}

  // ================= ACTION =================

 // Di ServiceReportFormPage, tambahkan di bagian action buttons
Widget _actionButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      if (_isSaving)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        )
      else ...[
        ElevatedButton(
          onPressed: _saveDraft,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Text("Save Draft"),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Submit"),
        ),
      ],
    ],
  );
}

// ================= NOTE SECTION =================
Widget _noteSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "NOTE FOR CUSTOMER",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: noteController,
        maxLines: 4,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Write note for customer...",
        ),
      ),
    ],
  );
}

// ================= SAVE DRAFT =================
// ================= SAVE DRAFT =================
Future<void> _saveDraft() async {
  // Validasi company
  final companyId = CompanySession.selectedCompanyId;
  if (companyId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a company first"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Validasi field mandatory
  if (machineController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Machine is required"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    // Upload media jika ada file baru
    // Upload media jika ada file baru
if (_photo1 != null) {
  setState(() => _isUploading = true);
  _photo1Url = await CloudinaryService.uploadFile(
    file: _photo1!,
    folder: 'service_reports/$companyId',
  );
}

if (_photo2 != null) {
  _photo2Url = await CloudinaryService.uploadFile(
    file: _photo2!,
    folder: 'service_reports/$companyId',
  );
}

if (_photo3 != null) {
  _photo3Url = await CloudinaryService.uploadFile(
    file: _photo3!,
    folder: 'service_reports/$companyId',
  );
}

if (_video != null) {
  _videoUrl = await CloudinaryService.uploadFile(
    file: _video!,
    folder: 'service_reports/$companyId',
  );
}

    setState(() => _isUploading = false);

    // Kumpulkan semua data
    final Map<String, dynamic> reportData = {
      // BASIC INFO
      "startDate": startDate != null ? Timestamp.fromDate(startDate!) : null,
      "endDate": endDate != null ? Timestamp.fromDate(endDate!) : null,
      "factory": factory,
      "endCustomer": endCustomer,
      "customerCode": customerCodeController.text,

      // MACHINE
      "machine": machineController.text,
      "serialNumber": serialController.text,
      "assetNumber": assetController.text,

      // DESCRIPTION
      "problemDescription": problemController.text,
      "activity": activityController.text,

      // NOTE
      "noteForCustomer": noteController.text,

      // TECHNICIAN
      "technician1": tech1,
      "technician2": tech2,
      "technician3": tech3,

      // CUSTOMER
      "customerName": customerNameController.text,

      // SPARE PARTS
      "spareParts": spareParts,

      // MEDIA (gunakan publicId dari upload)
      "photo1": _photo1Url,
"photo2": _photo2Url,
"photo3": _photo3Url,
"video": _videoUrl,

      // SIGNATURE (sementara null)
     "signature": _signatureUrl,

      // METADATA
      "updatedAt": FieldValue.serverTimestamp(),
    };

    // CEK: Apakah ini EDIT atau CREATE BARU?
    if (_currentReportId == null) {
      // CREATE BARU
      final generatedSheetId = await ServiceReportFirestore.createServiceReport(data: reportData);
      print("Created new report with Sheet ID: $generatedSheetId");
    } else {
      // EDIT (UPDATE) - pakai method updateServiceReport
      await ServiceReportFirestore.updateServiceReport(_currentReportId!, reportData);
      print("Updated existing report with ID: $_currentReportId");
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _currentReportId == null 
            ? "Service Report saved as Draft" 
            : "Service Report updated successfully"
        ),
        backgroundColor: Colors.green[700],
      ),
    );

    // Kembali ke list page dengan result true
    Navigator.pop(context, true);

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ),
    );

    print("Error saving draft: $e");
    
    setState(() {
      _isSaving = false;
      _isUploading = false;
    });
  }
}

Future<void> _submitReport() async {
  // Validasi company
  final companyId = CompanySession.selectedCompanyId;
  if (companyId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a company first"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Validasi field mandatory lebih ketat untuk submit
  if (machineController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Machine is required"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (tech1 == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("At least one technician is required"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (factory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Factory is required"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Tampilkan dialog konfirmasi
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Submit Service Report"),
      content: const Text(
        "After submission, this report cannot be edited. "
        "Are you sure you want to submit?"
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: const Text("SUBMIT"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  setState(() {
    _isSaving = true;
  });

  try {
    // Upload media jika ada file baru (sama seperti di _saveDraft)
    if (_photo1 != null) {
      setState(() => _isUploading = true);
      _photo1Url = await CloudinaryService.uploadFile(
        file: _photo1!,
        folder: 'service_reports/$companyId',
      );
    }

    if (_photo2 != null) {
      _photo2Url = await CloudinaryService.uploadFile(
        file: _photo2!,
        folder: 'service_reports/$companyId',
      );
    }

    if (_photo3 != null) {
      _photo3Url = await CloudinaryService.uploadFile(
        file: _photo3!,
        folder: 'service_reports/$companyId',
      );
    }

    if (_video != null) {
      _videoUrl = await CloudinaryService.uploadFile(
        file: _video!,
        folder: 'service_reports/$companyId',
      );
    }

    setState(() => _isUploading = false);

    final Map<String, dynamic> reportData = {
      // BASIC INFO
      "startDate": startDate != null ? Timestamp.fromDate(startDate!) : null,
      "endDate": endDate != null ? Timestamp.fromDate(endDate!) : null,
      "factory": factory,
      "endCustomer": endCustomer,
      "customerCode": customerCodeController.text,

      // MACHINE
      "machine": machineController.text,
      "serialNumber": serialController.text,
      "assetNumber": assetController.text,

      // DESCRIPTION
      "problemDescription": problemController.text,
      "activity": activityController.text,

      // NOTE
      "noteForCustomer": noteController.text,

      // TECHNICIAN
      "technician1": tech1,
      "technician2": tech2,
      "technician3": tech3,

      // CUSTOMER
      "customerName": customerNameController.text,

      // SPARE PARTS
      "spareParts": spareParts,

      // MEDIA
      "photo1": _photo1Url,
"photo2": _photo2Url,
"photo3": _photo3Url,
"video": _videoUrl,

      // SIGNATURE
      "signature": null,
    };

    if (_currentReportId == null) {
      // CREATE BARU + SUBMIT
      final sheetId = await ServiceReportFirestore.createServiceReport(data: {
        ...reportData,
        "status": "Submitted",
      });
      print("Report submitted with Sheet ID: $sheetId");
    } else {
      // UPDATE + SUBMIT
      await ServiceReportFirestore.updateServiceReport(_currentReportId!, {
        ...reportData,
        "status": "Submitted",
        "submittedAt": FieldValue.serverTimestamp(),
      });
      await ServiceReportFirestore.submitServiceReport(_currentReportId!);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Service Report submitted successfully"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error submitting: $e"),
        backgroundColor: Colors.red,
      ),
    );

    print("Error submitting report: $e");
    
    setState(() {
      _isSaving = false;
      _isUploading = false;
    });
  }
}

// ================= MEDIA METHODS =================
Future<void> _pickImage(int number) async {
  final source = await showDialog<ImageSource>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Choose Image Source"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ImageSource.camera),
          child: const Text("Camera"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ImageSource.gallery),
          child: const Text("Gallery"),
        ),
      ],
    ),
  );
  
  if (source == null) return;
  
  final XFile? pickedFile = source == ImageSource.camera
      ? await CloudinaryService.pickImageFromCamera()
      : await CloudinaryService.pickImageFromGallery();
  
  if (pickedFile != null) {
    setState(() {
      switch (number) {
        case 1:
          _photo1 = pickedFile;
          _photo1Url = null;
          break;
        case 2:
          _photo2 = pickedFile;
          _photo2Url = null;
          break;
        case 3:
          _photo3 = pickedFile;
          _photo3Url = null;
          break;
      }
    });
  }
}

Future<void> _pickVideo() async {
  final XFile? pickedFile = await CloudinaryService.pickVideoFromGallery();
  
  if (pickedFile != null) {
    setState(() {
      _video = pickedFile;
      _videoUrl = null;
    });
  }
}

void _clearImage(int number) {
  setState(() {
    switch (number) {
      case 1:
        _photo1 = null;
        _photo1Url = null;
        break;
      case 2:
        _photo2 = null;
        _photo2Url = null;
        break;
      case 3:
        _photo3 = null;
        _photo3Url = null;
        break;
    }
  });
}

void _clearVideo() {
  setState(() {
    _video = null;
    _videoUrl = null;
  });
}
    }