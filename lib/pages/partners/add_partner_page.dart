import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/partner_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart'; // gunakan helper yg sama

class AddPartnerPage extends StatefulWidget {
  final bool isWindow;

  const AddPartnerPage({
    super.key,
    this.isWindow = false,
  });

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
  final cityController = TextEditingController();
  final countryController = TextEditingController();
  String category = 'domestic';

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
    cityController.dispose();
    countryController.dispose();
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
      String? logoUrl = '';

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
        category: category,
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
        city: cityController.text.trim().isEmpty
            ? null
            : cityController.text.trim(),
        country: countryController.text.trim().isEmpty
            ? null
            : countryController.text.trim(),
        logoUrl: logoUrl ?? '',
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
    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFFF8FAFC),
                  Color(0xFFEFF6FF),
                  Color(0xFFF8FAFC),
                ],
              ),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section with Icon
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.business_center_outlined,
                                      size: 20,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Partner Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Logo Picker
                              _buildModernLogoPicker(),
                              const SizedBox(height: 24),

                              // Name Field (Required)
                              _buildModernInput(
                                controller: nameController,
                                label: 'Client Name',
                                required: true,
                                icon: Icons.business,
                              ),
                              const SizedBox(height: 16),

                              // Address Field
                              _buildModernInput(
                                controller: addressController,
                                label: 'Address',
                                maxLines: 2,
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 16),

                              // City & Country Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernInput(
                                      controller: cityController,
                                      label: 'City',
                                      icon: Icons.location_city,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernInput(
                                      controller: countryController,
                                      label: 'Country',
                                      icon: Icons.public,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Phone & Email Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernInput(
                                      controller: phoneController,
                                      label: 'Phone',
                                      icon: Icons.phone_outlined,
                                      keyboard: TextInputType.phone,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernInput(
                                      controller: emailController,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      keyboard: TextInputType.emailAddress,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Category Dropdown
                              _buildModernDropdown(),
                              const SizedBox(height: 16),

                              // Latitude & Longitude Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernInput(
                                      controller: latController,
                                      label: 'Latitude',
                                      icon: Icons.gps_fixed,
                                      keyboard: TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernInput(
                                      controller: lngController,
                                      label: 'Longitude',
                                      icon: Icons.gps_not_fixed,
                                      keyboard: TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : savePartner,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Save Partner',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isWindow) {
      return scaffold.body!;
    }

    return scaffold;
  }

  // ================= MODERN HEADER =================
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
            'Add Partner',
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

  // ================= MODERN LOGO PICKER =================
  Widget _buildModernLogoPicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: pickLogo,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 2,
                ),
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
                child: selectedImage != null
                    ? Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_center,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload logo',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Company Logo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MODERN INPUT =================
  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    IconData? icon,
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
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
          ),
        ),
      ],
    );
  }

  // ================= MODERN DROPDOWN =================
  Widget _buildModernDropdown() {
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: category,
            decoration: InputDecoration(
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
            ),
            items: const [
              DropdownMenuItem(
                value: 'domestic',
                child: Row(
                  children: [
                    Icon(Icons.home, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Domestic'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'overseas',
                child: Row(
                  children: [
                    Icon(Icons.flight, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Overseas'),
                  ],
                ),
              ),
            ],
            onChanged: (v) => setState(() => category = v!),
          ),
        ),
      ],
    );
  }
}