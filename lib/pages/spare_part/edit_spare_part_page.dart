import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/spare_part.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';


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

  String formatLocation(String input) {
  String value = input
      .toUpperCase()
      .replaceAll(' ', '')
      .replaceAll('.', '-');

  // Heuristik: A11 → A1-1
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
  final locationKey = normalizeLocation(location);

  final doc = await FirebaseFirestore.instance
      .collection('locations')
      .doc(locationKey)
      .get();

  return !doc.exists;
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

  // ===== UPLOAD ANIMATION STATE =====
  bool isUploadingImage = false;
  double uploadProgress = 0.0;
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
    weightController =
        TextEditingController(text: widget.part.weight.toString());
    weightUnit = widget.part.weightUnit;

    currentImageUrl = widget.part.imageUrl;

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
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


  // =========================
  // FULLSCREEN IMAGE PREVIEW
  // =========================
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

  // =========================
  // PICK IMAGE
  // =========================
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

  // =========================
  // IMAGE SOURCE DIALOG
  // =========================
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

  // =========================
  // UPLOAD TO CLOUDINARY + ANIMATION
  // =========================
  Future<String> uploadImageToCloudinary(String partCode) async {
  if (selectedImage == null) return currentImageUrl;

  setState(() {
    isUploadingImage = true;
    uploadProgress = 0.0;
  });

  // Smooth fake progress animation
  Future.doWhile(() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!isUploadingImage) return false;

    setState(() {
      uploadProgress += 0.04;
      if (uploadProgress > 0.9) uploadProgress = 0.9;
    });

    return true;
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
      uploadProgress = 1.0;
    });
  }

  if (response.statusCode == 200) {
    final baseUrl = data['secure_url']; // ✅ untuk Firestore
    final ts = DateTime.now().millisecondsSinceEpoch;
    final previewUrl = '$baseUrl?ts=$ts'; // ✅ untuk UI refresh

    // ✅ refresh foto di Edit Page
    setState(() {
      currentImageUrl = previewUrl;
      selectedImage = null;
    });

    _fadeController.reset();
    _fadeController.forward();

    return baseUrl; // ⚠️ SIMPAN KE FIRESTORE TANPA timestamp
  } else {
    showMessage('Upload image failed');
    return currentImageUrl;
  }
}

Future<void> safeDeleteCloudinaryImage(String oldUrl, String newUrl) async {
  if (oldUrl.isEmpty) return;
  if (oldUrl == newUrl) return;

  // ✅ bersihkan query string (?ts=...)
  final cleanUrl = oldUrl.split('?').first;

  // ✅ pastikan berasal dari folder spare_parts
  if (!cleanUrl.contains('/spare_parts/')) {
    debugPrint('Skip delete: not spare_parts image');
    return;
  }

  try {
    // ✅ extract public_id dengan aman
    final parts = cleanUrl.split('/upload/');
    if (parts.length < 2) return;

    final path = parts[1];

    // hapus version prefix (v123456789/)
    final pathWithoutVersion = path.replaceFirst(RegExp(r'^v\d+/'), '');

    // hapus extension (.jpg, .png, dll)
    final publicId = pathWithoutVersion.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    debugPrint('Deleting Cloudinary public_id: $publicId');

    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    final signatureBase =
        'public_id=$publicId&timestamp=$timestamp$apiSecret';

    final signature = sha1.convert(utf8.encode(signatureBase)).toString();

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
    );

    final response = await http.post(
      url,
      body: {
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      },
    );

    debugPrint('Cloudinary delete response: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('✅ Old image deleted successfully');
    } else {
      debugPrint('❌ Delete failed');
    }
  } catch (e) {
    debugPrint('❌ Cloudinary delete error: $e');
  }
}


Future<void> deleteCloudinaryImage(String imageUrl) async {
  if (imageUrl.isEmpty) return;

  try {
    // Ambil public_id dari URL Cloudinary
    final uriPart = imageUrl.split('/upload/').last;
    final publicId = uriPart.split('.').first; // tanpa extension

    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    final signatureBase =
        'public_id=$publicId&timestamp=$timestamp$apiSecret';

    final signature = sha1.convert(utf8.encode(signatureBase)).toString();

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
    );

    final response = await http.post(
      url,
      body: {
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      },
    );

    if (response.statusCode == 200) {
      debugPrint('Old image deleted: $publicId');
    } else {
      debugPrint('Failed to delete old image: ${response.body}');
    }
  } catch (e) {
    debugPrint('Cloudinary delete error: $e');
  }
}

  // =========================
  // UPDATE DATA
  // =========================
Future<void> updateData() async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final oldImageUrl = widget.part.imageUrl;

  final String name = nameController.text.trim();
  final String nameEn = nameEnController.text.trim();
  final String location = locationController.text.trim();
  final String inputWeight = weightController.text.replaceAll(',', '.');

  if (name.isEmpty) {
    showMessage('Name wajib diisi');
    return;
  }

  if (nameEn.isEmpty) {
    showMessage('Name (English) wajib diisi');
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

  final newImageUrl =
      await uploadImageToCloudinary(widget.part.partCode);

  await safeDeleteCloudinaryImage(oldImageUrl, newImageUrl);

  await FirebaseFirestore.instance
      .collection('spare_parts')
      .doc(widget.part.partCode)
      .update({
    'name': name,
    'nameEn': nameEn,
    'location': location,
    'stock': stock,
    'weight': weight,
    'weightUnit': weightUnit,
    'imageUrl': newImageUrl,
    'updatedAt': Timestamp.now(),
  });

  if (oldLocationKey != newLocationKey) {
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(oldLocationKey)
        .delete();

    await FirebaseFirestore.instance
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


  // =========================
  // DELETE DATA
  // =========================
  Future<void> deleteData() async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final locationKey = normalizeLocation(widget.part.location);

  await FirebaseFirestore.instance
      .collection('spare_parts')
      .doc(widget.part.partCode)
      .delete();

  await FirebaseFirestore.instance
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
// kembali ke list
}


  // =========================
  // DELETE DIALOG
  // =========================
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
    Navigator.pop(context); // ✅ TUTUP DIALOG
    await deleteData();     // ✅ DELETE + POP PAGE
  },
  child: const Text('Hapus'),
),

        ],
      ),
    );
  }

  // =========================
  // IMAGE WIDGET (PRO)
  // =========================
  Widget _buildImage() {
  return GestureDetector(
    onTap: showFullScreenImage,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.36), // shadow tipis
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: const Color.fromARGB(255, 252, 227, 139),
          child: AspectRatio(
            aspectRatio: 1, // 3/3 → 1:1
            child: Stack(
              children: [
                // ===== IMAGE =====
                Positioned.fill(
                  child: FadeTransition(
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
                              )
                            : const Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.black45,
                                ),
                              )),
                  ),
                ),

                // ===== CAMERA BUTTON =====
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap:
                        isUploadingImage ? null : showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: isUploadingImage
                            ? Colors.grey
                            : Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // ===== UPLOAD OVERLAY =====
                if (isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha:0.45),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE0B2),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Colors.blueGrey),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.only(
                        top: 50,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Center(child: _buildImage()),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      TextField(
                        controller: partCodeController,
                        decoration:
                            const InputDecoration(labelText: 'Part Code'),
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameEnController,
                        decoration:
                            const InputDecoration(labelText: 'Name (English)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
  controller: stockController,
  enabled: false, // 🔒 KUNCI EDIT
  decoration: const InputDecoration(
    labelText: 'Stock (Auto)',
  ),
),

                      const SizedBox(height: 12),
                      TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Weight'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: weightUnit,
                        items: ['Kg', 'g', 'Ton']
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => weightUnit = v!),
                        decoration: const InputDecoration(
                            labelText: 'Weight Unit'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: updateData,
                              child: const Text('Update'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: showDeleteDialog,
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
