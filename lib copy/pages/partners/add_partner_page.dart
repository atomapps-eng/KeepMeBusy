import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/partner_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart'; // gunakan helper yg sama

class AddPartnerPage extends StatefulWidget {
  const AddPartnerPage({super.key});

  @override
  State<AddPartnerPage> createState() => _AddPartnerPageState();
}

class _AddPartnerPageState extends State<AddPartnerPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  

  File? selectedImage;
  final picker = ImagePicker();

  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  // =========================
  // PICK LOGO
  // =========================
  Future<void> pickLogo() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // =========================
  // SAVE PARTNER
  // =========================
  Future<void> savePartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
     String logoUrl = '';

if (selectedImage != null) {
  logoUrl = await CloudinaryService.uploadImage(
    file: selectedImage!,
    folder: 'partners',
    publicId: nameController.text.trim(),
  );
}


      await PartnerService().addPartner(
  name: nameController.text.trim(),
  address: addressController.text.trim(),
  lat: latController.text.isEmpty
      ? null
      : double.tryParse(latController.text),
  lng: lngController.text.isEmpty
      ? null
      : double.tryParse(lngController.text),
  phone: phoneController.text.trim().isEmpty
      ? null
      : phoneController.text.trim(),
  email: emailController.text.trim().isEmpty
      ? null
      : emailController.text.trim(),
  logoUrl: logoUrl,
);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Gagal menyimpan data');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // BACKGROUND
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
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildHeader(context),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLogoPicker(),
                            const SizedBox(height: 20),

                            _input(
                              controller: nameController,
                              label: 'Client Name',
                              required: true,
                            ),
                            _input(
                              controller: addressController,
                              label: 'Address',
                              maxLines: 2,
                            ),
                            _input(
  controller: phoneController,
  label: 'Phone',
  keyboard: TextInputType.phone,
),

_input(
  controller: emailController,
  label: 'Email',
  keyboard: TextInputType.emailAddress,
),


                            Row(
                              children: [
                                Expanded(
                                  child: _input(
                                    controller: latController,
                                    label: 'Latitude',
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _input(
                                    controller: lngController,
                                    label: 'Longitude',
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isSaving ? null : savePartner,
                                child: isSaving
                                    ? const CircularProgressIndicator()
                                    : const Text('Save Partner'),
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
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Add Partner',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LOGO PICKER =================
  Widget _buildLogoPicker() {
    return Center(
      child: GestureDetector(
        onTap: pickLogo,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 140,
            height: 140,
            color: Colors.white.withValues(alpha: 0.4),
            child: selectedImage != null
                ? Image.file(selectedImage!, fit: BoxFit.cover)
                : const Icon(Icons.camera_alt, size: 40),
          ),
        ),
      ),
    );
  }

  // ================= INPUT =================
  Widget _input({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}

