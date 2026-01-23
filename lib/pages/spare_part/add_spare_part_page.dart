import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddSparePartPage extends StatefulWidget {
  const AddSparePartPage({super.key});

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

  File? selectedImage;
  final picker = ImagePicker();

  String weightUnit = 'Kg';

  // 🔥 Cloudinary config
  final String cloudName = 'djl2sukor';
  final String uploadPreset = 'spare_parts_images';

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  // =========================
  // PICK IMAGE (CAMERA / GALLERY)
  // =========================
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

  // =========================
  // DIALOG PILIH SUMBER FOTO
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
  // UPLOAD IMAGE TO CLOUDINARY
  // =========================
  Future<String> uploadImageToCloudinary(String partCode) async {
    if (selectedImage == null) return '';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'spare_parts';
    final uniqueId = '${partCode}_${DateTime.now().millisecondsSinceEpoch}';
request.fields['public_id'] = uniqueId;
 // 🔥 nama file berdasarkan partCode

    request.files.add(
      await http.MultipartFile.fromPath('file', selectedImage!.path),
    );

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

  // =========================
  // SAVE DATA
  // =========================
  Future<void> saveData() async {
    String partCode = partCodeController.text.trim();
    String name = nameController.text.trim();
    String nameEn = nameEnController.text.trim();
    String location = locationController.text.trim();
    String inputWeight = weightController.text.replaceAll(',', '.');

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

    int stock = int.tryParse(stockController.text) ?? 0;
    double weight = double.tryParse(inputWeight) ?? 0.0;

    // CEK DUPLIKAT PART CODE
    final doc = await FirebaseFirestore.instance
        .collection('spare_parts')
        .doc(partCode)
        .get();

    if (doc.exists) {
      showMessage('Part Code sudah ada!');
      return;
    }

    // 🔥 UPLOAD IMAGE KE CLOUDINARY
    String imageUrl = await uploadImageToCloudinary(partCode);

    // 🔥 SIMPAN KE FIRESTORE
    await FirebaseFirestore.instance.collection('spare_parts').doc(partCode).set({
      'partCode': partCode,
      'name': name,
      'nameEn': nameEn,
      'location': location,
      'stock': stock,
      'weight': weight,
      'weightUnit': weightUnit,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
    });

    showMessage('Spare part berhasil ditambahkan');

    await Future.delayed(const Duration(milliseconds: 800));
    Navigator.pop(context);
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Add Spare Part',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        GestureDetector(
                          onTap: showImageSourceDialog,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: selectedImage == null
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, size: 40, color: Colors.blueGrey),
                                        SizedBox(height: 8),
                                        Text('Tap to add image',
                                            style: TextStyle(color: Colors.blueGrey)),
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      selectedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                          ),
                        ),

                        TextField(
                          controller: partCodeController,
                          decoration: const InputDecoration(labelText: 'Part Code'),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: nameEnController,
                          decoration: const InputDecoration(labelText: 'Name (English)'),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: locationController,
                          decoration: const InputDecoration(labelText: 'Location'),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock'),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Weight'),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          initialValue: weightUnit,
                          items: ['Kg', 'g', 'Ton']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => weightUnit = v!),
                          decoration: const InputDecoration(labelText: 'Weight Unit'),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: saveData,
                          child: const Text('Save'),
                        ),
                      ],
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
}
