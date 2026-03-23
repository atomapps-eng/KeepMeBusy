import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/spare_part.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/services/company_firestore.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditSparePartPage extends StatefulWidget {
  final SparePart part;

  const EditSparePartPage({super.key, required this.part});

  @override
  State<EditSparePartPage> createState() => _EditSparePartPageState();
}

class _EditSparePartPageState extends State<EditSparePartPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController partCodeController;
  late TextEditingController nameController;
  late TextEditingController nameEnController;
  late TextEditingController locationController;
  late TextEditingController stockController;
  late TextEditingController weightController;
  late TextEditingController basePriceController;
  late SparePartCategory _selectedCategory;
  late SparePartOrigin _selectedOrigin;
  late TextEditingController currentStockController;

  bool isSuperAdmin = false;
  bool isLoadingRole = true;

  String formatLocation(String input) {
    String value = input
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('.', '-');

    final match = RegExp(r'^([A-Z]\d+)(\d+)$').firstMatch(value);
    if (match != null) {
      value = '${match.group(1)}-${match.group(2)}';
    }

    return value;
  }

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

  String weightUnit = 'Kg';
  File? selectedImage;
  final picker = ImagePicker();
  late String currentImageUrl;

  // Cloudinary config
  final String cloudName = 'djl2sukor';
  final String uploadPreset = 'spare_parts_images';
  final String apiKey = '379534721643839';
  final String apiSecret = 'LzsTB5Cq5ycrkZ2mGEkdyD7y6Ho';

  bool isUploadingImage = false;
  bool imageLoaded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    partCodeController = TextEditingController(text: widget.part.partCode);
    nameController = TextEditingController(text: widget.part.name);
    nameEnController = TextEditingController(text: widget.part.nameEn);
    locationController = TextEditingController(
      text: formatLocation(widget.part.location),
    );

    stockController = TextEditingController(text: widget.part.stock.toString());
    currentStockController = TextEditingController(text: widget.part.currentStock.toString());
    weightController = TextEditingController(text: widget.part.weight.toString());
    weightUnit = widget.part.weightUnit;
    basePriceController = TextEditingController(
  text: widget.part.basePriceEur.toString(),
);
    _selectedCategory = widget.part.category;
    _selectedOrigin = widget.part.origin;

    currentImageUrl = widget.part.imageUrl;

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

     _loadRole();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    partCodeController.dispose();
    nameController.dispose();
    nameEnController.dispose();
    locationController.dispose();
    stockController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  void showFullScreenImage() {
    if (selectedImage == null && currentImageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: selectedImage != null
                  ? Image.file(selectedImage!)
                  : Image.network(currentImageUrl),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 65,
      maxWidth: 1280,
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        imageLoaded = false;
      });
    }
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
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
    if (selectedImage == null) return currentImageUrl;

    setState(() {
      isUploadingImage = true;
    });

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'spare_parts';
    final uniqueId = '${partCode}_${DateTime.now().millisecondsSinceEpoch}';
    request.fields['public_id'] = uniqueId;

    request.files.add(
      await http.MultipartFile.fromPath('file', selectedImage!.path),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = json.decode(resBody);

    if (mounted) {
      setState(() {
        isUploadingImage = false;
      });
    }

    if (response.statusCode == 200) {
      final baseUrl = data['secure_url'];
      final ts = DateTime.now().millisecondsSinceEpoch;
      final previewUrl = '$baseUrl?ts=$ts';

      setState(() {
        currentImageUrl = previewUrl;
        selectedImage = null;
      });

      _fadeController.reset();
      _fadeController.forward();

      return baseUrl;
    } else {
      showMessage('Upload image failed');
      return currentImageUrl;
    }
  }

  Future<void> safeDeleteCloudinaryImage(String oldUrl, String newUrl) async {
    if (oldUrl.isEmpty) return;
    if (oldUrl == newUrl) return;

    final cleanUrl = oldUrl.split('?').first;
    if (!cleanUrl.contains('/spare_parts/')) return;

    try {
      final parts = cleanUrl.split('/upload/');
      if (parts.length < 2) return;

      final path = parts[1];
      final pathWithoutVersion = path.replaceFirst(RegExp(r'^v\d+/'), '');
      final publicId = pathWithoutVersion.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final signatureBase = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(signatureBase)).toString();

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );

      await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );
    } catch (e) {
      debugPrint('Cloudinary delete error: $e');
    }
  }

  Future<void> updateData() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final oldImageUrl = widget.part.imageUrl;
    final String name = nameController.text.trim();
    final String nameEn = nameEnController.text.trim();
    final String location = locationController.text.trim();
    final String inputWeight = weightController.text.replaceAll(',', '.');
    double basePrice =
    double.tryParse(basePriceController.text.replaceAll(',', '.')) ?? 0.0;

    if (name.isEmpty || nameEn.isEmpty) {
      showMessage('Name dan Name (English) wajib diisi');
      return;
    }

    final oldLocationKey = normalizeLocation(widget.part.location);
    final newLocationKey = normalizeLocation(location);

    if (oldLocationKey != newLocationKey) {
      final available = await isLocationAvailable(location);
      if (!available) {
        showMessage('Location sudah digunakan oleh spare part lain');
        return;
      }
    }

    int stock = int.tryParse(stockController.text) ?? 0;
    double weight = double.tryParse(inputWeight) ?? 0.0;

    final newImageUrl = await uploadImageToCloudinary(widget.part.partCode);
    await safeDeleteCloudinaryImage(oldImageUrl, newImageUrl);

    // 🔥 STEP 7B — BUILD PAYLOAD (HARUS DI LUAR)
Map<String, dynamic> updatePayload = {
  'name': name,
  'nameEn': nameEn,
  'location': location,
  'stock': stock,
  'weight': weight,
  'weightUnit': weightUnit,
  'imageUrl': newImageUrl,
  'category': _selectedCategory.name.toUpperCase(),
  'origin': _selectedOrigin.name.toUpperCase(),
  'updatedAt': Timestamp.now(),
};

// 🔥 hanya super_admin boleh update base price
if (isSuperAdmin) {
  updatePayload['basePriceEur'] = basePrice;
}

// 🔥 BARU panggil update
await CompanyFirestore
    .collection('spare_parts')
    .doc(widget.part.partCode)
    .update(updatePayload);

// 🔥 hanya super_admin boleh update base price
if (isSuperAdmin) {
  updatePayload['basePriceEur'] = basePrice;
}

// 🔥 FINAL UPDATE
await CompanyFirestore
    .collection('spare_parts')
    .doc(widget.part.partCode)
    .update(updatePayload);

    if (oldLocationKey != newLocationKey) {
      await CompanyFirestore
          .collection('locations')
          .doc(oldLocationKey)
          .delete();

      await CompanyFirestore
          .collection('locations')
          .doc(newLocationKey)
          .set({
        'partCode': widget.part.partCode,
        'createdAt': Timestamp.now(),
      });
    }

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Data berhasil diupdate')),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    navigator.pop();
  }

  Future<void> deleteData() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final locationKey = normalizeLocation(widget.part.location);

    await CompanyFirestore
        .collection('spare_parts')
        .doc(widget.part.partCode)
        .delete();

    await CompanyFirestore
        .collection('locations')
        .doc(locationKey)
        .delete();

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Spare part berhasil dihapus')),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    navigator.pop();
  }

  Future<void> showDeleteDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Spare Part'),
        content: Text('Yakin ingin menghapus part "${widget.part.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deleteData();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // =========================
// IMPROVED IMAGE SECTION WITH SIDE CAMERA BUTTON
// =========================
Widget _buildImageSection() {
  final isDesktop = MediaQuery.of(context).size.width >= 900;
  final isMobile = MediaQuery.of(context).size.width < 600;
  final imageSize = isDesktop ? 180.0 : (isMobile ? 140.0 : 160.0);

  return Container(
    margin: EdgeInsets.only(bottom: isMobile ? 24 : 32),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image
        GestureDetector(
          onTap: showFullScreenImage,
          child: Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color.fromARGB(255, 243, 228, 172),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image content
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: selectedImage != null
                          ? Image.file(
                              selectedImage!,
                              fit: BoxFit.contain,
                            )
                          : (currentImageUrl.isNotEmpty
                              ? Image.network(
                                  currentImageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: isMobile ? 36 : 48,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Gambar error',
                                          style: TextStyle(
                                            fontSize: isMobile ? 11 : 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory,
                                      size: isMobile ? 48 : 64,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tidak ada gambar',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                )),
                    ),

                    // Zoom indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.zoom_out_map,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),

                    // Upload overlay
                    if (isUploadingImage)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Camera button beside image
        const SizedBox(width: 16),
        
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: isUploadingImage ? null : showImageSourceDialog,
            backgroundColor: Colors.blueGrey,
            mini: isMobile,
            child: Icon(
              Icons.camera_alt,
              color: isUploadingImage ? Colors.grey.shade400 : Colors.white,
            ),
            tooltip: 'Ganti Foto',
          ),
        ),
      ],
    ),
  );
}

  // =========================
  // FORM FIELDS WITH CONSISTENT STYLING
  // =========================
  Widget _buildFormFields() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part Code (readonly)
        _buildTextField(
          controller: partCodeController,
          label: 'Part Code',
          enabled: false,
          isMobile: isMobile,
        ),

        const SizedBox(height: 16),

        // Name
        _buildTextField(
          controller: nameController,
          label: 'Name',
          required: true,
          isMobile: isMobile,
        ),

        const SizedBox(height: 16),

        // Name (English)
        _buildTextField(
          controller: nameEnController,
          label: 'Name (English)',
          required: true,
          isMobile: isMobile,
        ),

        const SizedBox(height: 16),

        // Location
        _buildTextField(
          controller: locationController,
          label: 'Location',
          helperText: 'Contoh: A1-2 atau C9-8',
          isMobile: isMobile,
        ),

        const SizedBox(height: 16),

        // Stock Info Row
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: stockController,
                label: 'Initial Stock',
                enabled: false,
                isMobile: isMobile,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: currentStockController,
                label: 'Current Stock',
                enabled: false,
                isMobile: isMobile,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Weight and Unit
        Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      flex: 3,
      child: _buildTextField(
        controller: weightController,
        label: 'Weight',
        keyboardType: TextInputType.number,
        isMobile: isMobile,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Unit',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: isMobile ? 48 : 52, // Sama tinggi dengan TextField
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: weightUnit,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey.shade400),
                items: ['Kg', 'g', 'lb'].map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => weightUnit = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),

const SizedBox(height: 16),

_buildTextField(
  controller: basePriceController,
  label: 'Base Price (EUR)',
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  enabled: !isLoadingRole && isSuperAdmin,
  isMobile: isMobile,
),

        const SizedBox(height: 16),

        // Category Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SparePartCategory>(
              value: _selectedCategory,
              isExpanded: true,
              hint: const Text('Pilih Category'),
              items: SparePartCategory.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.name.replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Origin Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SparePartOrigin>(
              value: _selectedOrigin,
              isExpanded: true,
              hint: const Text('Pilih Origin'),
              items: SparePartOrigin.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.name.replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedOrigin = value);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: updateData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 14 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Update Data'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: showDeleteDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 14 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Hapus'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    bool required = false,
    TextInputType? keyboardType,
    String? helperText,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: Colors.grey.shade600,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isMobile ? 12 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blueGrey.shade400),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            filled: !enabled,
            fillColor: !enabled ? Colors.grey.shade50 : null,
          ),
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
  gradient: AppTheme.backgroundGradient,
),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      iconSize: isMobile ? 20 : 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Spare Part',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    children: [
                      // Image Section
                      _buildImageSection(),
                      
                      // Form Fields
                      _buildFormFields(),
                      
                      SizedBox(height: isMobile ? 16 : 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _isSuperAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid) // 🔥 PAKAI UID
      .get();

  final role = (doc.data()?['role'] ?? '').toString().trim();

  return doc.exists && role == 'super_admin';
}

// 🔥 STEP TAMBAHAN 3
Future<void> _loadRole() async {
  final result = await _isSuperAdmin();
  if (!mounted) return;

  setState(() {
    isSuperAdmin = result;
     isLoadingRole = false;
  });
}

}