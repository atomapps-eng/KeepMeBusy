import 'package:flutter/material.dart';
import '../../models/spare_part.dart';
import '../../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'edit_spare_part_page.dart';
import '../../core/widgets/draggable_window.dart';
import '../../services/spare_part_service.dart';

class SparePartDetailPageDesktop extends StatelessWidget {
  final SparePart part;

  const SparePartDetailPageDesktop({
    super.key,
    required this.part,
  });

  @override
  Widget build(BuildContext context) {
    final eurFormat = NumberFormat.currency(
      locale: 'en',
      symbol: '€ ',
      decimalDigits: 2,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= LEFT PANEL =================
              SizedBox(
                width: 320,
                child: _LeftPanel(part: part),
              ),

              const SizedBox(width: 24),

              // ================= RIGHT PANEL =================
              Expanded(
                child: _RightPanel(
                  part: part,
                  eurFormat: eurFormat,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final SparePart part;

  const _LeftPanel({required this.part});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== IMAGE =====
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color.fromARGB(255, 243, 228, 172),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: part.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: part.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, size: 60),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.inventory, size: 60),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // ===== PART CODE =====
        Text(
          part.partCode,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // ===== NAME =====
        Text(
          part.name,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 24),

        // ===== QUICK INFO =====
        _info("Location", part.location),
        _info("Category", part.category.name.replaceAll('_', ' ')),
        _info("Origin", part.origin.name.replaceAll('_', ' ')),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatefulWidget {
  final SparePart part;
  final NumberFormat eurFormat;

  const _RightPanel({
    required this.part,
    required this.eurFormat,
  });

  @override
  State<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<_RightPanel> {
  late SparePart part;

  @override
  void initState() {
    super.initState();
    part = widget.part;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== HEADER =====
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Spare Part Detail",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            Row(
              children: [
                // ===== EDIT BUTTON =====
                ElevatedButton.icon(
                  onPressed: () async {
                    if (isDesktop) {
                      final result = await showGeneralDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: "EditSparePart",
                        barrierColor:
                            Colors.black.withValues(alpha: 0.35),
                        transitionDuration:
                            const Duration(milliseconds: 200),
                        pageBuilder: (_, _, _) {
                          return DraggableResizableWindow(
                            title: "Edit Spare Part",
                            headerColor: Colors.blueGrey,
                            child: EditSparePartPage(part: part),
                          );
                        },
                      );

                      // 🔥 REFRESH DATA TANPA TUTUP DETAIL
                      if (result == true && mounted) {
                        final service = SparePartService();
                        final updated =
                            await service.getByPartCode(part.partCode);

                        if (updated != null) {
                          setState(() {
                            part = updated;
                          });
                        }
                      }
                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditSparePartPage(part: part),
                        ),
                      );

                      if (result == true && mounted) {
                        final service = SparePartService();
                        final updated =
                            await service.getByPartCode(part.partCode);

                        if (updated != null) {
                          setState(() {
                            part = updated;
                          });
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                ),

                const SizedBox(width: 8),

                // ===== DELETE BUTTON (optional nanti kita isi) =====
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text("Delete"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            )
          ],
        ),

        const SizedBox(height: 24),

        // ===== CONTENT =====
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _sectionCard(
                  title: "GENERAL",
                  children: [
                    _row("Part Code", part.partCode),
                    _row("Name", part.name),
                    _row("Name (EN)", part.nameEn),
                  ],
                ),
                _sectionCard(
                  title: "STOCK",
                  children: [
                    _row("Initial", part.initialStock.toString()),
                    _row("Current", part.currentStock.toString()),
                    _row("Minimum", part.minimumStock.toString()),
                  ],
                ),
                _sectionCard(
                  title: "SPECIFICATION",
                  children: [
                    _row(
                      "Weight",
                      "${part.weight} ${part.weightUnit}",
                    ),
                  ],
                ),
                _sectionCard(
                  title: "PRICE",
                  children: [
                    _row(
                      "Base Price",
                      widget.eurFormat.format(part.basePriceEur),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= CARD =================
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ================= ROW =================
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}