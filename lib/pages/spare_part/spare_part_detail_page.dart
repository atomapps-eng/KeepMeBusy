import 'package:flutter/material.dart';
import 'dart:ui';
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
import '../../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class SparePartDetailPage extends StatefulWidget {
  final SparePart part;

  const SparePartDetailPage({super.key, required this.part});

  @override
  State<SparePartDetailPage> createState() => _SparePartDetailPageState();
}

class _SparePartDetailPageState extends State<SparePartDetailPage> {
  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('admin_whitelist')
        .doc(user.email!.toLowerCase())
        .get();

    return doc.exists && doc.data()?['active'] == true;
  }

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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

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

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/spare_part_${widget.part.partCode}.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      final image = await _addTextToImage(
        FileImage(tempFile),
        'Part Code: ${widget.part.partCode}',
      );

      final finalFile = File('${tempDir.path}/share_${widget.part.partCode}.jpg');
      await finalFile.writeAsBytes(image);

      if (mounted) Navigator.pop(context);

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

    final paint = Paint();
    canvas.drawImage(originalImage, Offset.zero, paint);

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);
    
    const overlayHeight = 60.0;
    canvas.drawRect(
      Rect.fromLTWH(
        0, 
        originalImage.height - overlayHeight, 
        originalImage.width.toDouble(),
        overlayHeight
      ),
      overlayPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    
    final dx = (originalImage.width - textPainter.width) / 2;
    final dy = originalImage.height - overlayHeight + (overlayHeight - textPainter.height) / 2;
    
    textPainter.paint(canvas, Offset(dx, dy));

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
    
    final labelFontSize = isMobile ? 12.0 : 13.0;
    final valueFontSize = isMobile ? 14.0 : 15.0;
    final sectionSpacing = isMobile ? 20.0 : 24.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Spare Part Detail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          if (widget.part.imageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareImageWithPartCode,
                tooltip: 'Share with Part Code',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
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

                SizedBox(height: isMobile ? 24 : 32),

                // Basic Info Card
                _buildModernCard(
                  title: 'BASIC INFORMATION',
                  icon: Icons.info_outline,
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

                // Stock Card
                _buildModernCard(
                  title: 'STOCK MANAGEMENT',
                  icon: Icons.inventory_2,
                  children: [
                    _metricRow(
                      'Initial Stock',
                      widget.part.initialStock.toString(),
                      'units',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _metricRow(
                      'Current Stock',
                      widget.part.currentStock.toString(),
                      'units',
                      widget.part.currentStock <= widget.part.minimumStock
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _metricRow(
                      'Minimum Stock',
                      widget.part.minimumStock.toString(),
                      'units',
                      Colors.orange,
                    ),
                  ],
                ),

                SizedBox(height: sectionSpacing),

                // Category & Origin Card
                _buildModernCard(
                  title: 'CLASSIFICATION',
                  icon: Icons.category,
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

                // Specification Card
                _buildModernCard(
                  title: 'SPECIFICATIONS',
                  icon: Icons.settings,
                  children: [
                    _infoRow('Weight', '${widget.part.weight} ${widget.part.weightUnit}',
                        labelFontSize: labelFontSize,
                        valueFontSize: valueFontSize),
                  ],
                ),

                SizedBox(height: sectionSpacing),

                // Price Card
                _buildModernCard(
                  title: 'PRICING',
                  icon: Icons.attach_money,
                  children: [
                    _metricRow(
                      'Base Price',
                      eurFormat.format(widget.part.basePriceEur),
                      'per unit',
                      Colors.green,
                      isCurrency: true,
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 24 : 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: 'Edit',
                        color: const Color(0xFF3B82F6),
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
                              barrierColor: Colors.black.withOpacity(0.35),
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
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditSparePartPage(part: widget.part),
                              ),
                            );
                            if (result == true && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        color: const Color(0xFFEF4444),
                        onPressed: () async {
                          final isAdmin = await _isAdmin();
                          if (!context.mounted) return;

                          if (!isAdmin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You don\'t have access to delete this part'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text('Delete Spare Part'),
                              content: Text(
                                'Are you sure you want to delete "${widget.part.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
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
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, String unit, Color color, {bool isCurrency = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isCurrency ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {required double labelFontSize, required double valueFontSize}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                fontSize: labelFontSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
    );
  }

  final eurFormat = NumberFormat.currency(
    locale: 'en',
    symbol: '€ ',
    decimalDigits: 2,
  );
}

// Detail Image Widget (Modern)
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
    final imageSize = isMobile ? 220.0 : 260.0;

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
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFF5F3EF),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      const Text('Failed to load image'),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF5F3EF),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory, size: 80, color: Colors.grey.shade600),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No image available',
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
                        color: Colors.black.withOpacity(0.5),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Part Code: $partCode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: const Color(0xFFF5F3EF),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF5F3EF),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('Failed to load'),
                              ],
                            ),
                          ),
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
                      color: Colors.black.withOpacity(0.5),
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