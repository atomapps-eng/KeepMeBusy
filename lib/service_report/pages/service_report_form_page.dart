// lib/pages/service_report_form_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/service_report_firestore.dart';
import '../../core/session/company_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'signature_page.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../pages/common/app_background_wrapper.dart';
import '../services/company_collection_resolver.dart';
import '../../pages/spare_part/spare_part_list_page.dart';
import '../../models/spare_part.dart';

class ServiceReportFormPage extends StatefulWidget {
  final String? reportId;
  
  const ServiceReportFormPage({super.key, this.reportId});

  @override
  State<ServiceReportFormPage> createState() => _ServiceReportFormPageState();
}

class _ServiceReportFormPageState extends State<ServiceReportFormPage> {
  bool _isSaving = false;
  bool _isLoading = false;
  String? _currentReportId;

  List<String> partnerList = [];
  bool _isLoadingPartners = true; 
  
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

  List<String> technicianList = [];
  bool _isLoadingTechnicians = true;

  // CUSTOMER
  final customerNameController = TextEditingController();

  // SPARE PART
  List<Map<String, dynamic>> spareParts = [];
  List<Map<String, dynamic>> sparePartMaster = [];
  bool _isLoadingSpareParts = true;

  // DUMMY DATA
  
  final technicians = ["Basuki", "Agus", "Rudi"];

  // MEDIA
  XFile? _photo1;
  XFile? _photo2;
  XFile? _photo3;
  XFile? _video;
  XFile? _signature;
  String? _signatureUrl;
  String? _photo1Url;
  String? _photo2Url;
  String? _photo3Url;
  String? _videoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadPartners();
     _loadTechnicians();
      _loadSpareParts();
    _currentReportId = widget.reportId;
    if (_currentReportId != null) {
      _loadReportData();
    }
  }

  Future<void> _loadPartners() async {
  try {
    final snapshot = await CompanyCollectionResolver
        .partners()
        .orderBy('name')
        .get();

    final data = snapshot.docs
        .map((doc) => doc.data()['name'] as String)
        .toList();

    setState(() {
      partnerList = data;
      _isLoadingPartners = false;
    });
  } catch (e) {
    print("Error loading partners: $e");
    setState(() {
      _isLoadingPartners = false;
    });
  }
}

Future<void> _loadTechnicians() async {
  try {
    final companyId = CompanySession.selectedCompanyId;

    if (companyId == null) {
      throw Exception("Company not selected");
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('companyIds', arrayContains: companyId)
        .where('position', isEqualTo: 'technician')
        .where('active', isEqualTo: true)
        .get();

    final data = snapshot.docs
    .map((doc) => doc.data()['username'])
    .where((name) => name != null && name.toString().isNotEmpty)
    .map((name) => name.toString())
    .toList();

        print("Technician snapshot count: ${snapshot.docs.length}");
        print("Mapped technician list: $data");

    setState(() {
      technicianList = data;
      _isLoadingTechnicians = false;
    });
  } catch (e) {
    print("Error loading technicians: $e");
    setState(() {
      _isLoadingTechnicians = false;
    });
    print("Technician list final: $technicianList");
  }
}

Future<void> _loadSpareParts() async {
  try {
    final snapshot = await CompanyCollectionResolver
        .spareParts()
        .orderBy('name')
        .get();

    final data = snapshot.docs
        .map((doc) => doc.data())
        .toList();

    setState(() {
      sparePartMaster = data;
      _isLoadingSpareParts = false;
    });
  } catch (e) {
    print("Error loading spare parts: $e");
    setState(() {
      _isLoadingSpareParts = false;
    });
  }
}

  Future<void> _loadReportData() async {
    if (_currentReportId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await ServiceReportFirestore.getReport(_currentReportId!);
      
      if (!mounted) return;

      final data = doc.data();
      if (data == null) return;

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

        _photo1 = null;
        _photo2 = null;
        _photo3 = null;
        _video = null;
        _signature = null;

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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (_isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Service Report Form',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: AppBackgroundWrapper(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _currentReportId == null ? 'Create Report' : 'Edit Report',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            if (isDesktop) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR - FORM NAVIGATION
        Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDesktopNavigationCard(),
                const SizedBox(height: 16),
                _buildDesktopInfoCard(),
                const SizedBox(height: 16),
                _buildDesktopMediaSummary(),
              ],
            ),
          ),
        ),

        // RIGHT CONTENT - FORM FIELDS
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDesktopBasicInfo(),
                const SizedBox(height: 16),
                _buildDesktopMachineSection(),
                const SizedBox(height: 16),
                _buildDesktopDescriptionSection(),
                const SizedBox(height: 16),
                _buildDesktopSparePartSection(),
                const SizedBox(height: 16),
                _buildDesktopNoteSection(),
                const SizedBox(height: 16),
                _buildDesktopTechnicianSection(),
                const SizedBox(height: 16),
                _buildDesktopSignatureSection(),
                const SizedBox(height: 16),
                _buildDesktopMediaSection(),
                const SizedBox(height: 24),
                _buildDesktopActionButtons(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNavigationCard() {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Form Sections',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNavItem('Basic Information', Icons.info, 0),
          _buildNavItem('Machine', Icons.precision_manufacturing, 1),
          _buildNavItem('Description', Icons.description, 2),
          _buildNavItem('Spare Parts', Icons.build, 3),
          _buildNavItem('Note', Icons.note, 4),
          _buildNavItem('Technicians', Icons.engineering, 5),
          _buildNavItem('Signature', Icons.draw, 6),
          _buildNavItem('Media', Icons.photo_library, 7),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    return InkWell(
      onTap: () {
        // Scroll ke section tertentu
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInfoCard() {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Fields marked with * are required for submission.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, size: 14, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save Draft to continue later. Submit when complete.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMediaSummary() {
    int mediaCount = 0;
    if (_photo1 != null || _photo1Url != null) mediaCount++;
    if (_photo2 != null || _photo2Url != null) mediaCount++;
    if (_photo3 != null || _photo3Url != null) mediaCount++;
    if (_video != null || _videoUrl != null) mediaCount++;

    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo,
                  color: Colors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Media Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mediaCountItem(Icons.photo, 'Photos', mediaCount > 0 ? mediaCount - (_video != null ? 1 : 0) : 0),
                _mediaCountItem(Icons.videocam, 'Videos', _video != null || _videoUrl != null ? 1 : 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaCountItem(IconData icon, String label, int count) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildDesktopBasicInfo() {
    return _formSection(
      'BASIC INFORMATION',
      Icons.info,
      Colors.blue,
      Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDatePicker('Start Date *', startDate, (date) => setState(() => startDate = date))),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePicker('End Date', endDate, (date) => setState(() => endDate = date))),
            ],
          ),
          const SizedBox(height: 16),
         _isLoadingPartners
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Factory *',
        factory,
        partnerList,
        (val) => setState(() => factory = val),
      ),
          const SizedBox(height: 16),
          _isLoadingPartners
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'End Customer',
        endCustomer,
        partnerList,
        (val) => setState(() => endCustomer = val),
      ),
          const SizedBox(height: 16),
          _buildTextField(customerCodeController, 'Customer Code'),
        ],
      ),
    );
  }

  Widget _buildDesktopMachineSection() {
    return _formSection(
      'MACHINE INFORMATION',
      Icons.precision_manufacturing,
      Colors.purple,
      Column(
        children: [
          _buildTextField(machineController, 'Machine *'),
          const SizedBox(height: 16),
          _buildTextField(serialController, 'Serial Number'),
          const SizedBox(height: 16),
          _buildTextField(assetController, 'Asset Number'),
        ],
      ),
    );
  }

  Widget _buildDesktopDescriptionSection() {
    return _formSection(
      'PROBLEM DESCRIPTION & ACTIVITY',
      Icons.description,
      Colors.orange,
      Column(
        children: [
          _buildTextField(problemController, 'Problem Description *', maxLines: 4),
          const SizedBox(height: 16),
          _buildTextField(activityController, 'Activity *', maxLines: 4),
        ],
      ),
    );
  }

  Widget _buildDesktopSparePartSection() {
    return _formSection(
      'SPARE PARTS',
      Icons.build,
      Colors.deepOrange,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _openSparePartSelector,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              elevation: 0,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Spare Part'),
          ),
          const SizedBox(height: 16),
          if (spareParts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No spare parts added', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...spareParts.map((part) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Qty: ${part['qty']}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        spareParts.remove(part);
                      });
                    },
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildDesktopNoteSection() {
    return _formSection(
      'NOTE FOR CUSTOMER',
      Icons.note,
      Colors.teal,
      _buildTextField(noteController, 'Write note for customer...', maxLines: 4),
    );
  }

  Widget _buildDesktopTechnicianSection() {
    return _formSection(
      'TECHNICIANS',
      Icons.engineering,
      Colors.brown,
      Column(
        children: [
          _isLoadingTechnicians
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Technician 1 *',
        tech1,
        technicianList,
        (val) => setState(() => tech1 = val),
      ),
          if (tech1 != null) ...[
            const SizedBox(height: 16),
            _isLoadingTechnicians
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Technician 2',
        tech2,
        technicianList,
        (val) => setState(() => tech2 = val),
      ),
          ],
          if (tech2 != null) ...[
            const SizedBox(height: 16),
            _isLoadingTechnicians
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Technician 3',
        tech3,
        technicianList,
        (val) => setState(() => tech3 = val),
      ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopSignatureSection() {
    return _formSection(
      'CUSTOMER SIGNATURE',
      Icons.draw,
      Colors.indigo,
      Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildSignaturePreview(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_signature == null && _signatureUrl == null)
                ElevatedButton.icon(
                  onPressed: _openSignaturePad,
                  icon: const Icon(Icons.edit),
                  label: const Text("Add Signature"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade50,
                    foregroundColor: Colors.indigo,
                  ),
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
      ),
    );
  }

  Widget _buildDesktopMediaSection() {
    return _formSection(
      'MEDIA',
      Icons.photo_library,
      Colors.pink,
      Column(
        children: [
          _buildMediaItem('Photo 1', _photo1, _photo1Url, () => _pickImage(1), () => _clearImage(1)),
          const SizedBox(height: 12),
          _buildMediaItem('Photo 2', _photo2, _photo2Url, () => _pickImage(2), () => _clearImage(2)),
          const SizedBox(height: 12),
          _buildMediaItem('Photo 3', _photo3, _photo3Url, () => _pickImage(3), () => _clearImage(3)),
          const SizedBox(height: 12),
          _buildMediaItem('Video', _video, _videoUrl, _pickVideo, _clearVideo, isVideo: true),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(String title, XFile? file, String? url, VoidCallback onPick, VoidCallback onClear, {bool isVideo = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
            child: _buildPreview(file, url, isVideo),
          ),
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
                  Text(
                    file != null ? "File selected" : (url != null ? "Uploaded" : "No file"),
                    style: TextStyle(
                      fontSize: 12,
                      color: file != null || url != null ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (file == null && url == null)
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: onPick,
                  tooltip: "Add $title",
                ),
              if (file != null || url != null)
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

  Widget _buildDesktopActionButtons() {
    return _glass(
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else ...[
            ElevatedButton.icon(
              onPressed: _saveDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.save),
              label: const Text("Save Draft"),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.send),
              label: const Text("Submit Report"),
            ),
          ],
        ],
      ),
    );
  }

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _glass(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Report Form',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentReportId == null ? 'Create new report' : 'Edit report',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BASIC INFORMATION
          _buildMobileSection(
            'BASIC INFORMATION',
            Icons.info,
            Colors.blue,
            Column(
              children: [
                _buildMobileDatePicker('Start Date *', startDate, (date) => setState(() => startDate = date)),
                const SizedBox(height: 12),
                _buildMobileDatePicker('End Date', endDate, (date) => setState(() => endDate = date)),
                const SizedBox(height: 12),
                _isLoadingPartners
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Factory *',
        factory,
        partnerList,
        (val) => setState(() => factory = val),
      ),
                const SizedBox(height: 12),
                _isLoadingPartners
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'End Customer',
        endCustomer,
        partnerList,
        (val) => setState(() => endCustomer = val),
      ),
                const SizedBox(height: 12),
                _buildTextField(customerCodeController, 'Customer Code'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // MACHINE INFORMATION
          _buildMobileSection(
            'MACHINE INFORMATION',
            Icons.precision_manufacturing,
            Colors.purple,
            Column(
              children: [
                _buildTextField(machineController, 'Machine *'),
                const SizedBox(height: 12),
                _buildTextField(serialController, 'Serial Number'),
                const SizedBox(height: 12),
                _buildTextField(assetController, 'Asset Number'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // DESCRIPTION
          _buildMobileSection(
            'PROBLEM DESCRIPTION & ACTIVITY',
            Icons.description,
            Colors.orange,
            Column(
              children: [
                _buildTextField(problemController, 'Problem Description *', maxLines: 3),
                const SizedBox(height: 12),
                _buildTextField(activityController, 'Activity *', maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SPARE PARTS
          _buildMobileSection(
            'SPARE PARTS',
            Icons.build,
            Colors.deepOrange,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _addSparePartDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Spare Part'),
                ),
                const SizedBox(height: 12),
                if (spareParts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('No spare parts added', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...spareParts.map((part) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
  "${part['partCode']} - ${part['name']}",
  style: const TextStyle(fontWeight: FontWeight.w600),
),
                              Text('Qty: ${part['qty']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              spareParts.remove(part);
                            });
                          },
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // NOTE
          _buildMobileSection(
            'NOTE FOR CUSTOMER',
            Icons.note,
            Colors.teal,
            _buildTextField(noteController, 'Write note for customer...', maxLines: 3),
          ),
          const SizedBox(height: 12),

          // TECHNICIANS
          _buildMobileSection(
            'TECHNICIANS',
            Icons.engineering,
            Colors.brown,
            Column(
              children: [
                _isLoadingTechnicians
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Technician 1 *',
        tech1,
        technicianList,
        (val) => setState(() => tech1 = val),
      ),
                if (tech1 != null) ...[
                  const SizedBox(height: 12),
                  _isLoadingTechnicians
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Technician 2',
        tech2,
        technicianList,
        (val) => setState(() => tech2 = val),
      ),
                ],
                if (tech2 != null) ...[
                  const SizedBox(height: 12),
                  _isLoadingTechnicians
    ? const CircularProgressIndicator()
    : _buildDropdownField(
        'Technician 3',
        tech3,
        technicianList,
        (val) => setState(() => tech3 = val),
      ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SIGNATURE
          _buildMobileSection(
            'CUSTOMER SIGNATURE',
            Icons.draw,
            Colors.indigo,
            Column(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildSignaturePreview(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_signature == null && _signatureUrl == null)
                      ElevatedButton.icon(
                        onPressed: _openSignaturePad,
                        icon: const Icon(Icons.edit),
                        label: const Text("Add Signature"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade50,
                          foregroundColor: Colors.indigo,
                        ),
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
            ),
          ),
          const SizedBox(height: 12),

          // MEDIA
          _buildMobileSection(
            'MEDIA',
            Icons.photo_library,
            Colors.pink,
            Column(
              children: [
                _buildMobileMediaItem('Photo 1', _photo1, _photo1Url, () => _pickImage(1), () => _clearImage(1)),
                const SizedBox(height: 8),
                _buildMobileMediaItem('Photo 2', _photo2, _photo2Url, () => _pickImage(2), () => _clearImage(2)),
                const SizedBox(height: 8),
                _buildMobileMediaItem('Photo 3', _photo3, _photo3Url, () => _pickImage(3), () => _clearImage(3)),
                const SizedBox(height: 8),
                _buildMobileMediaItem('Video', _video, _videoUrl, _pickVideo, _clearVideo, isVideo: true),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ACTION BUTTONS
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveDraft,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text("Save Draft"),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Report"),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMobileSection(String title, IconData icon, Color color, Widget child) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMobileMediaItem(String title, XFile? file, String? url, VoidCallback onPick, VoidCallback onClear, {bool isVideo = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
            child: _buildPreview(file, url, isVideo),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  Text(
                    file != null ? "File selected" : (url != null ? "Uploaded" : "No file"),
                    style: TextStyle(fontSize: 10, color: file != null || url != null ? Colors.green.shade700 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          if (file == null && url == null)
            IconButton(icon: const Icon(Icons.add_photo_alternate, size: 20), onPressed: onPick),
          if (file != null || url != null)
            IconButton(icon: const Icon(Icons.clear, color: Colors.red, size: 20), onPressed: onClear),
        ],
      ),
    );
  }

  // ================= COMMON FORM WIDGETS =================
  Widget _formSection(String title, IconData icon, Color color, Widget child) {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onSelected) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: date ?? DateTime.now(),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              date != null ? '${date.day}/${date.month}/${date.year}' : label,
              style: TextStyle(
                color: date != null ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDatePicker(String label, DateTime? date, Function(DateTime) onSelected) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: date ?? DateTime.now(),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              date != null ? '${date.day}/${date.month}/${date.year}' : label,
              style: TextStyle(
                color: date != null ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(XFile? file, String? url, bool isVideo) {
    if (url != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      );
    }
    
    if (file != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: file.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
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
        return ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
          child: Image.file(File(file.path), fit: BoxFit.cover),
        );
      }
    }
    
    return Icon(
      isVideo ? Icons.videocam : Icons.image,
      color: Colors.grey[400],
    );
  }

  Widget _buildSignaturePreview() {
    if (_signature != null) {
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
      return Image.network(
        _signatureUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(child: Text("Failed to load signature")),
      );
    } else {
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

  // ================= DIALOGS =================
  void _addSparePartDialog() {
  final qtyController = TextEditingController();
  String? selectedPart;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Add Spare Part"),
      content: _isLoadingSpareParts
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPart,
                  items: sparePartMaster
                      .map((e) => DropdownMenuItem<String>(
                            value: e['name'],
                            child: Text(e['name']),
                          ))
                      .toList(),
                  onChanged: (val) {
                    selectedPart = val;
                  },
                  decoration:
                      const InputDecoration(labelText: "Spare Part"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyController,
                  decoration:
                      const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number,
                )
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedPart == null) return;

            setState(() {
              spareParts.add({
                "name": selectedPart,
                "qty": qtyController.text,
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

Future<void> _openSparePartSelector() async {
  final selectedPart = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SparePartListPage(
        selectionMode: true,
      ),
    ),
  );

  if (selectedPart == null) return;

  _showQtyDialog(selectedPart);
}

void _showQtyDialog(SparePart part) {
  final qtyController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Add ${part.partCode}"),
      content: TextField(
        controller: qtyController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Quantity",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final qty = int.tryParse(qtyController.text);
            if (qty == null || qty <= 0) return;

            setState(() {
              spareParts.add({
                "partCode": part.partCode,
                "name": part.name,
                "qty": qty,
              });
            });

            Navigator.pop(context);
          },
          child: const Text("Add"),
        ),
      ],
    ),
  );
}

  // ================= EXISTING METHODS (TIDAK DIUBAH) =================
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

  // ================= EXISTING SAVE/SUBMIT METHODS (TIDAK DIUBAH) =================
  Future<void> _saveDraft() async {
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
        "startDate": startDate != null ? Timestamp.fromDate(startDate!) : null,
        "endDate": endDate != null ? Timestamp.fromDate(endDate!) : null,
        "factory": factory,
        "endCustomer": endCustomer,
        "customerCode": customerCodeController.text,
        "machine": machineController.text,
        "serialNumber": serialController.text,
        "assetNumber": assetController.text,
        "problemDescription": problemController.text,
        "activity": activityController.text,
        "noteForCustomer": noteController.text,
        "technician1": tech1,
        "technician2": tech2,
        "technician3": tech3,
        "customerName": customerNameController.text,
        "spareParts": spareParts,
        "photo1": _photo1Url,
        "photo2": _photo2Url,
        "photo3": _photo3Url,
        "video": _videoUrl,
        "signature": _signatureUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (_currentReportId == null) {
        await ServiceReportFirestore.createServiceReport(data: reportData);
      } else {
        await ServiceReportFirestore.updateServiceReport(_currentReportId!, reportData);
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
        "startDate": startDate != null ? Timestamp.fromDate(startDate!) : null,
        "endDate": endDate != null ? Timestamp.fromDate(endDate!) : null,
        "factory": factory,
        "endCustomer": endCustomer,
        "customerCode": customerCodeController.text,
        "machine": machineController.text,
        "serialNumber": serialController.text,
        "assetNumber": assetController.text,
        "problemDescription": problemController.text,
        "activity": activityController.text,
        "noteForCustomer": noteController.text,
        "technician1": tech1,
        "technician2": tech2,
        "technician3": tech3,
        "customerName": customerNameController.text,
        "spareParts": spareParts,
        "photo1": _photo1Url,
        "photo2": _photo2Url,
        "photo3": _photo3Url,
        "video": _videoUrl,
        "signature": _signatureUrl,
      };

      if (_currentReportId == null) {
        await ServiceReportFirestore.createServiceReport(data: {
          ...reportData,
          "status": "Submitted",
        });
      } else {
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
}

// ================= UI HELPERS =================
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: child,
      ),
    ),
  );
}