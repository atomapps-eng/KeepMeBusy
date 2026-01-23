import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/spare_part.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  String weightUnit = 'Kg';

  File? selectedImage;
  final picker = ImagePicker();
  late String currentImageUrl;

  // Cloudinary config
  final String cloudName = 'djl2sukor';
  final String uploadPreset = 'spare_parts_images';

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
    locationController = TextEditingController(text: widget.part.location);
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

  // Smooth fake progress animation (UX friendly)
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
    // ✅ CACHE BUSTING (KUNCI UTAMA)
    final baseUrl = data['secure_url'];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newUrl = '$baseUrl?v=$timestamp';

    // ✅ update image langsung di edit page
    setState(() {
      currentImageUrl = newUrl;
      selectedImage = null; // reset local file preview
    });

    _fadeController.reset();
    _fadeController.forward();

    return newUrl;
  } else {
    showMessage('Upload image failed');
    return currentImageUrl;
  }
}


  // =========================
  // UPDATE DATA
  // =========================
  Future<void> updateData() async {
    String name = nameController.text.trim();
    String nameEn = nameEnController.text.trim();
    String location = locationController.text.trim();
    String inputWeight = weightController.text.replaceAll(',', '.');

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

    String imageUrl = await uploadImageToCloudinary(widget.part.partCode);

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
      'imageUrl': imageUrl,
      'updatedAt': Timestamp.now(),
    });

    showMessage('Data berhasil diupdate');

    await Future.delayed(const Duration(milliseconds: 600));
    Navigator.pop(context);
  }

  // =========================
  // DELETE DATA
  // =========================
  Future<void> deleteData() async {
    await FirebaseFirestore.instance
        .collection('spare_parts')
        .doc(widget.part.partCode)
        .delete();

    Navigator.pop(context);
    Navigator.pop(context);

    showMessage('Spare part berhasil dihapus');
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
            onPressed: deleteData,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: selectedImage != null
                    ? Image.file(
  selectedImage!,
  fit: BoxFit.cover,
  key: ValueKey(selectedImage!.path),
)


                    : (currentImageUrl.isNotEmpty
                        ? Image.network(
  currentImageUrl,
  fit: BoxFit.cover,
  key: ValueKey(currentImageUrl), // ✅ PAKSA REFRESH
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  },
)


                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.camera_alt, size: 50),
                            ),
                          )),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Camera button
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: isUploadingImage ? null : showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: isUploadingImage ? Colors.grey : Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              // Upload overlay
              if (isUploadingImage)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${(uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 140,
                            child: LinearProgressIndicator(
                              value: uploadProgress,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
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
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Stock'),
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
