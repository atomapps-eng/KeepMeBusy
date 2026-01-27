import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/spare_part_service.dart';
import '../../models/spare_part.dart';
import 'add_spare_part_page.dart';
import 'edit_spare_part_page.dart';
import 'barcode_scanner_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SparePartListPage extends StatefulWidget {
  final bool isCompact;
  final String? searchKeyword;
  final bool selectionMode;
  final ValueChanged<SparePart>? onSelected;


 const SparePartListPage({
  super.key,
  this.isCompact = false,
  this.searchKeyword,
  this.selectionMode = false,
  this.onSelected,
});


  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
void dispose() {
  searchFocusNode.dispose(); // STEP 1
  searchController.dispose(); // sudah ada controller
  super.dispose();
}

  @override
Widget build(BuildContext context) {
  final service = SparePartService();

  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      FocusScope.of(context).unfocus(); // STEP 2
    },
    child: Scaffold(
      floatingActionButton: widget.isCompact
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSparePartPage(),
                  ),
                );
              },
            ),
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
                if (!widget.isCompact)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildHeader(context),
                  ),
                if (!widget.isCompact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSearchBar(context),
                  ),
                if (!widget.isCompact) const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<SparePart>>(
                    stream: service.getSpareParts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final parts = snapshot.data!;
                      final keyword = widget.isCompact
                          ? (widget.searchKeyword ?? '').toLowerCase()
                          : searchController.text.toLowerCase();

                      final filteredParts = parts.where((part) {
                        return part.partCode.toLowerCase().contains(keyword) ||
                            part.name.toLowerCase().contains(keyword) ||
                            part.nameEn.toLowerCase().contains(keyword) ||
                            part.location.toLowerCase().contains(keyword);
                      }).toList();

                      if (filteredParts.isEmpty) {
                        return const Center(child: Text('No data'));
                      }

                      return ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredParts.length,
                        itemBuilder: (context, index) {
                          final part = filteredParts[index];

                          return GestureDetector(
                            onTap: () {
  if (widget.selectionMode) {
    Navigator.pop(context, part);
    return;
  }

  if (!widget.isCompact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSparePartPage(part: part), // ⬅️ DETAIL
      ),
    );
  }
},


                            child: _GlassCard(
                              child: widget.isCompact
                                  ? _CompactItem(part: part)
                                  : _FullscreenItem(part: part),
                            ),
                          );
                        },
                      );
                    },
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


  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha:0.35)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
  widget.selectionMode
      ? 'Select Spare Part'
      : 'Spare Part Database',
),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha:0.35)),
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode, // ✅ STEP 1
            decoration: InputDecoration(
              hintText: 'Search spare part...',
              border: InputBorder.none,
              icon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerPage(),
                    ),
                  );
                  if (result != null && result is String) {
                    searchController.text = result;
                    setState(() {});
                  }
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// COMPACT ITEM (FLOATING) — TIDAK DIUBAH
// =====================================================
class _CompactItem extends StatelessWidget {
  final SparePart part;

  const _CompactItem({required this.part});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.partCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                part.nameEn,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Stock: ${part.currentStock}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  part.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// =====================================================
// FULLSCREEN ITEM — UPDATED
// =====================================================
class _FullscreenItem extends StatelessWidget {
  final SparePart part;

  const _FullscreenItem({required this.part});

  @override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT DATA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.partCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(part.name),
                Text(
                  part.nameEn,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stock: ${part.currentStock}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      part.location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // RIGHT THUMBNAIL (TETAP)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(6),
              color: const Color.fromARGB(0, 244, 234, 221).withValues(alpha: 0.4),
              child: part.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: part.imageUrl,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.inventory, size: 28),
            ),
          ),
        ],
      ),
    ],
  );
}

}

// =====================================================
// GLASS CARD
// =====================================================
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha:0.35)),
      ),
      child: child,
    );
  }
}
