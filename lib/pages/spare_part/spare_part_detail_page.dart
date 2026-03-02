import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/widgets/draggable_window.dart';
import '../../models/spare_part.dart';
import 'edit_spare_part_page.dart';
import '../../core/services/company_firestore.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class SparePartDetailPage extends StatefulWidget {
  final SparePart part;

  const SparePartDetailPage({super.key, required this.part});

  @override
  State<SparePartDetailPage> createState() => _SparePartDetailPageState();
}

class _SparePartDetailPageState extends State<SparePartDetailPage> {
  // =========================
  // ADMIN CHECK
  // =========================
  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('admin_whitelist')
        .doc(user.email!.toLowerCase())
        .get();

    return doc.exists && doc.data()?['active'] == true;
  }

  // =========================
  // SHARE IMAGE WITH PART CODE
  // =========================
  Future<void> _shareImageWithPartCode() async {
    if (widget.part.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada gambar untuk di-share'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Download image
      final response = await http.get(Uri.parse(widget.part.imageUrl));
      if (response.statusCode != 200) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunduh gambar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Simpan ke temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/spare_part_${widget.part.partCode}.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Buat gambar dengan overlay part code
      final image = await _addTextToImage(
        FileImage(tempFile),
        'Part Code: ${widget.part.partCode}',
      );

      // Simpan gambar yang sudah diberi text
      final finalFile = File('${tempDir.path}/share_${widget.part.partCode}.jpg');
      await finalFile.writeAsBytes(image);

      if (mounted) Navigator.pop(context); // Tutup loading

      // Share file
      final xFile = XFile(finalFile.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Spare Part: ${widget.part.partCode} - ${widget.part.name}',
      );

    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
// ADD TEXT TO IMAGE - DIPERBAIKI
// =========================
Future<Uint8List> _addTextToImage(ImageProvider imageProvider, String text) async {
  final Completer<ui.Image> completer = Completer();
  
  final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
  stream.addListener(
    ImageStreamListener(
      (ImageInfo info, bool _) {
        completer.complete(info.image);
      },
    ),
  );
  
  final ui.Image originalImage = await completer.future;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Gambar original
  final paint = Paint();
  canvas.drawImage(originalImage, Offset.zero, paint);

  // Tambah overlay hitam transparan di bagian bawah
  final overlayPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.6);
  
  const overlayHeight = 60.0; // sudah double
  canvas.drawRect(
    Rect.fromLTWH(
      0, 
      originalImage.height - overlayHeight, 
      originalImage.width.toDouble(), // Konversi ke double
      overlayHeight
    ),
    overlayPaint,
  );

  // Tambah text part code
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();
  
  final dx = (originalImage.width - textPainter.width) / 2;
  final dy = originalImage.height - overlayHeight + (overlayHeight - textPainter.height) / 2;
  
  textPainter.paint(canvas, Offset(dx, dy));

  // Convert ke PNG
  final picture = recorder.endRecording();
  final img = await picture.toImage(
    originalImage.width, 
    originalImage.height
  );
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  return byteData!.buffer.asUint8List();
}

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Ukuran font yang konsisten berdasarkan device
    final labelFontSize = isMobile ? 13.0 : 14.0;
    final valueFontSize = isMobile ? 14.0 : 15.0;
    final sectionSpacing = isMobile ? 20.0 : 24.0;

    return Container(
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                children: [
                  if (!isDesktop)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: isMobile ? 20 : 24,
                    ),
                  if (!isDesktop) const SizedBox(width: 8),
                  
                  const Spacer(),
                  
                  // Tombol Share
                  if (widget.part.imageUrl.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        size: isMobile ? 20 : 24,
                        color: Colors.blueGrey,
                      ),
                      onPressed: _shareImageWithPartCode,
                      tooltip: 'Share foto dengan Part Code',
                    ),
                ],
              ),

              SizedBox(height: isMobile ? 12 : 20),

              // ===== HERO IMAGE =====
              Center(
                child: Hero(
                  tag: 'spare-part-image-${widget.part.partCode}',
                  child: _DetailImage(
                    imageUrl: widget.part.imageUrl,
                    isMobile: isMobile,
                    partCode: widget.part.partCode,
                  ),
                ),
              ),

              SizedBox(height: isMobile ? 16 : 24),

              // ===== INFO SECTIONS =====
              _buildInfoSection(
                children: [
                  _infoRow('Part Code', widget.part.partCode,
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                  _infoRow('Name', widget.part.name,
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                  _infoRow('Name (EN)', widget.part.nameEn,
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                  _infoRow('Location', widget.part.location,
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                ],
              ),

              SizedBox(height: sectionSpacing),

              _buildInfoSection(
                title: 'STOK',
                children: [
                  _infoRow('Initial Stock', widget.part.initialStock.toString(),
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                  _infoRow('Current Stock', widget.part.currentStock.toString(),
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                  _infoRow('Minimum Stock', widget.part.minimumStock.toString(),
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                ],
              ),

              SizedBox(height: sectionSpacing),

              _buildInfoSection(
                title: 'KATEGORI',
                children: [
                  _infoRow('Category',
                      widget.part.category.name.replaceAll('_', ' '),
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                  _infoRow('Origin', widget.part.origin.name.replaceAll('_', ' '),
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                ],
              ),

              SizedBox(height: sectionSpacing),

              _buildInfoSection(
                title: 'SPESIFIKASI',
                children: [
                  _infoRow('Weight', '${widget.part.weight} ${widget.part.weightUnit}',
                      labelFontSize: labelFontSize,
                      valueFontSize: valueFontSize),
                ],
              ),

              SizedBox(height: isMobile ? 24 : 28),

              // ===== ACTIONS =====
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                      label: Text(
                        'Edit',
                        style: TextStyle(fontSize: isMobile ? 13 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 10 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        final isDesktop = MediaQuery.of(context).size.width >= 900;

                        if (isDesktop) {
                          final parentContext = context;

                          Navigator.pop(parentContext);

                          await Future.delayed(const Duration(milliseconds: 200));

                          showGeneralDialog(
                            context: parentContext,
                            barrierDismissible: false,
                            barrierLabel: "EditSparePart",
                            barrierColor: Colors.black.withValues(alpha: 0.35),
                            transitionDuration: const Duration(milliseconds: 200),
                            pageBuilder: (_, _, _) {
                              return DraggableResizableWindow(
                                title: "Edit Spare Part",
                                headerColor: Colors.blueGrey,
                                child: EditSparePartPage(part: widget.part),
                              );
                            },
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditSparePartPage(part: widget.part),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete, size: isMobile ? 16 : 18),
                      label: Text(
                        'Hapus',
                        style: TextStyle(fontSize: isMobile ? 13 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 10 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        final isAdmin = await _isAdmin();
                        if (!context.mounted) return;

                        if (!isAdmin) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Anda tidak memiliki hak akses untuk menghapus data ini',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus Spare Part'),
                            content: Text(
                              'Yakin ingin menghapus "${widget.part.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        await CompanyFirestore
                            .collection('spare_parts')
                            .doc(widget.part.partCode)
                            .delete();

                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    String? title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ),
        ],
        ...children,
      ],
    );
  }

  Widget _infoRow(String label, String value,
      {required double labelFontSize, required double valueFontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
                fontSize: labelFontSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// IMAGE WITH ZOOM AND PART CODE
// =========================
class _DetailImage extends StatelessWidget {
  final String imageUrl;
  final bool isMobile;
  final String partCode;

  const _DetailImage({
    required this.imageUrl,
    required this.isMobile,
    required this.partCode,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = isMobile ? 200.0 : 220.0;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: const Color.fromARGB(255, 243, 228, 172),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color.fromARGB(255, 243, 228, 172),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 60,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Gambar tidak tersedia',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color.fromARGB(255, 243, 228, 172),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory,
                                      size: 80,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tidak ada gambar',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        iconSize: 24,
                      ),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Part Code: $partCode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: isMobile ? 16 : 24,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          child: Container(
            color: const Color.fromARGB(255, 243, 228, 172),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
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
                        )
                      : Icon(
                          Icons.inventory,
                          size: isMobile ? 48 : 56,
                          color: Colors.grey.shade600,
                        ),
                ),
                
                Positioned(
                  bottom: 8,
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
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}