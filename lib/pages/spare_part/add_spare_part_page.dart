import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/spare_part.dart';
import '../../core/services/company_firestore.dart';
import '../../theme/app_theme.dart';

class AddSparePartPage extends StatefulWidget {
  final bool isWindow;

  const AddSparePartPage({
    super.key,
    this.isWindow = false,
  });

  @override
  State<AddSparePartPage> createState() => _AddSparePartPageState();
}

class _AddSparePartPageState extends State<AddSparePartPage> {
  final partCodeController = TextEditingController();
  final nameController = TextEditingController();
  final nameEnController = TextEditingController();
  final locationController = TextEditingController();
  final stockController = TextEditingController();
  final weightController = TextEditingController();
  final minimumStockController = TextEditingController();
  final basePriceController = TextEditingController();
  SparePartCategory _selectedCategory = SparePartCategory.autoCutting;
  SparePartOrigin _selectedOrigin = SparePartOrigin.local;

  String normalizeLocation(String location) {
    return location
        .trim()
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('.', '-');
  }

  Future<bool> isLocationAvailable(String location) async {
    final normalized = normalizeLocation(location);
    final snapshot = await CompanyFirestore
        .collection('spare_parts')
        .where('locationKey', isEqualTo: normalized)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty;
  }

  File? selectedImage;
  final picker = ImagePicker();
  String weightUnit = 'Kg';

  // Cloudinary config
  final String cloudName = 'djl2sukor';
  final String uploadPreset = 'spare_parts_images';

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1024,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > 200 * 1024) {
        showMessage('Ukuran foto maksimal 200 KB');
        return;
      }

      setState(() {
        selectedImage = file;
      });
    }
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2563EB)),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> uploadImageToCloudinary(String partCode) async {
    if (selectedImage == null) return '';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'spare_parts';
    final uniqueId = '${partCode}_${DateTime.now().millisecondsSinceEpoch}';
    request.fields['public_id'] = uniqueId;
    request.files.add(await http.MultipartFile.fromPath('file', selectedImage!.path));
    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = json.decode(resBody);
    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      showMessage('Upload image failed');
      return '';
    }
  }

  Future<void> saveData() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    String partCode = partCodeController.text.trim();
    String name = nameController.text.trim();
    String nameEn = nameEnController.text.trim();
    String location = locationController.text.trim();
    final locationKey = normalizeLocation(location);
    String inputWeight = weightController.text.replaceAll(',', '.');
    double basePrice = double.tryParse(basePriceController.text.replaceAll(',', '.')) ?? 0.0;

    if (partCode.isEmpty) {
      showMessage('Part Code wajib diisi');
      return;
    }
    if (name.isEmpty) {
      showMessage('Name wajib diisi');
      return;
    }
    if (nameEn.isEmpty) {
      showMessage('Name (English) wajib diisi');
      return;
    }

    int minimumStock = int.tryParse(minimumStockController.text) ?? 0;
    int stock = int.tryParse(stockController.text) ?? 0;
    double weight = double.tryParse(inputWeight) ?? 0.0;

    final doc = await CompanyFirestore.collection('spare_parts').doc(partCode).get();
    if (doc.exists) {
      showMessage('Part Code sudah ada!');
      return;
    }
    if (location.isEmpty) {
      showMessage('Location wajib diisi');
      return;
    }

    final locationAvailable = await isLocationAvailable(location);
    if (!locationAvailable) {
      showMessage('Location sudah digunakan oleh spare part lain');
      return;
    }

    String imageUrl = await uploadImageToCloudinary(partCode);

    await CompanyFirestore.collection('spare_parts').doc(partCode).set({
  'partCode': partCode,
  'partCode_lower': partCode.toLowerCase(),

  'name': name,
  'name_lower': name.toLowerCase(),

  'nameEn': nameEn,

  'location': location,
  'locationKey': locationKey,
  'initialStock': stock,
  'currentStock': stock,
  'stock': stock,
  'minimumStock': minimumStock,
  'weight': weight,
  'weightUnit': weightUnit,
  'basePriceEur': basePrice,
  'imageUrl': imageUrl,
  'category': _selectedCategory.name.toUpperCase(),
  'origin': _selectedOrigin.name.toUpperCase(),
  'createdAt': Timestamp.now(),
});

    await CompanyFirestore.doc('spare_parts', partCode).get();
    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Spare part berhasil ditambahkan')),
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildModernHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Spare Part Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Image Picker
                          _buildModernImagePicker(),
                          const SizedBox(height: 24),

                          // Part Code
                          _buildModernInput(
                            controller: partCodeController,
                            label: 'Part Code',
                            icon: Icons.code_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 16),

                          // Name
                          _buildModernInput(
                            controller: nameController,
                            label: 'Name',
                            icon: Icons.text_fields_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 16),

                          // Name English
                          _buildModernInput(
                            controller: nameEnController,
                            label: 'Name (English)',
                            icon: Icons.translate_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 16),

                          // Location
                          _buildModernInput(
                            controller: locationController,
                            label: 'Location',
                            icon: Icons.location_on_outlined,
                            required: true,
                          ),
                          const SizedBox(height: 16),

                          // Stock & Minimum Stock Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernInput(
                                  controller: stockController,
                                  label: 'Stock',
                                  icon: Icons.inventory_outlined,
                                  keyboard: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModernInput(
                                  controller: minimumStockController,
                                  label: 'Minimum Stock',
                                  icon: Icons.warning_amber_outlined,
                                  keyboard: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Weight & Weight Unit Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernInput(
                                  controller: weightController,
                                  label: 'Weight',
                                  icon: Icons.scale_outlined,
                                  keyboard: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModernWeightUnitDropdown(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Base Price
                          _buildModernInput(
                            controller: basePriceController,
                            label: 'Base Price (EUR)',
                            icon: Icons.euro_outlined,
                            keyboard: const TextInputType.numberWithOptions(decimal: true),
                            prefix: '€ ',
                          ),
                          const SizedBox(height: 16),

                          // Category Dropdown
                          _buildModernCategoryDropdown(),
                          const SizedBox(height: 16),

                          // Origin Dropdown
                          _buildModernOriginDropdown(),
                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF64748B),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: saveData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Save Spare Part'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.isWindow) {
      return content;
    }

    return Scaffold(
      body: content,
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Add Spare Part',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernImagePicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: showImageSourceDialog,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add image',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      )
                    : Image.file(selectedImage!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Part Image',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String prefix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixText: prefix.isNotEmpty ? prefix : null,
          ),
        ),
      ],
    );
  }

  Widget _buildModernWeightUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.scale_outlined, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            const Text(
              'Weight Unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String>(
            value: weightUnit,
            items: ['Kg', 'g', 'Ton'].map((e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            )).toList(),
            onChanged: (v) => setState(() => weightUnit = v!),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category_outlined, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<SparePartCategory>(
            value: _selectedCategory,
            items: SparePartCategory.values.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernOriginDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.public_outlined, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            const Text(
              'Origin',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<SparePartOrigin>(
            value: _selectedOrigin,
            items: SparePartOrigin.values.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedOrigin = value);
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}