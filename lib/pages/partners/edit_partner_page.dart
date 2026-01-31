import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/partner.dart';
import '../../services/partner_service.dart';
import '../../services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

class EditPartnerPage extends StatefulWidget {
  final Partner partner;

  const EditPartnerPage({super.key, required this.partner});

  @override
  State<EditPartnerPage> createState() => _EditPartnerPageState();
}

class _EditPartnerPageState extends State<EditPartnerPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController latController;
  late TextEditingController lngController;
  late TextEditingController phoneController;
  late TextEditingController emailController;


  File? selectedImage;
  late String currentLogoUrl;

  bool isSaving = false;

  final picker = ImagePicker();
  final service = PartnerService();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.partner.name);
    addressController = TextEditingController(text: widget.partner.address);
    latController =
        TextEditingController(text: widget.partner.lat.toString());
    lngController =
        TextEditingController(text: widget.partner.lng.toString());
    currentLogoUrl = widget.partner.logoUrl;
    phoneController =
    TextEditingController(text: widget.partner.phone ?? '');
    emailController =
    TextEditingController(text: widget.partner.email ?? '');

  } 

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    phoneController.dispose();
    emailController.dispose();
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
  // UPDATE PARTNER
  // =========================
  Future<void> updatePartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      String logoUrl = currentLogoUrl;

      if (selectedImage != null) {
        logoUrl = await CloudinaryService.uploadImage(
          file: selectedImage!,
          folder: 'partners',
          publicId: nameController.text.trim(),
        );
      }

      await service.updatePartner(
        id: widget.partner.id,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        category: widget.partner.category,
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
      _showMessage('Gagal update data');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // =========================
  // DELETE PARTNER
  // =========================
  Future<void> deletePartner() async {
    await service.deletePartner(widget.partner.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
                          children: [
                            _buildLogo(),
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

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        isSaving ? null : updatePartner,
                                    child: const Text('Update'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: deletePartner,
                                    child: const Text('Delete'),
                                  ),
                                ),
                              ],
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                'Edit Partner',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LOGO =================
  Widget _buildLogo() {
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
                : (currentLogoUrl.isNotEmpty
                    ? Image.network(currentLogoUrl, fit: BoxFit.cover)
                    : const Icon(Icons.business, size: 40)),
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
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
