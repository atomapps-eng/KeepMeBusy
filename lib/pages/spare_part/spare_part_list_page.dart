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

  const SparePartListPage({
    super.key,
    this.isCompact = false,
    this.searchKeyword,
  });

  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Sinkron keyword dari floating / fullscreen
    if (widget.searchKeyword != null &&
        widget.searchKeyword!.isNotEmpty) {
      searchController.text = widget.searchKeyword!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = SparePartService();

    return Scaffold(
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
          // ===== BACKGROUND =====
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
                // ===== HEADER (HANYA FULLSCREEN) =====
                if (!widget.isCompact)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha:0.25),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white
                                  .withValues(alpha:0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.arrow_back),
                                onPressed: () =>
                                    Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Spare Part Database',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ===== SEARCH BAR (HANYA FULLSCREEN) =====
                if (!widget.isCompact)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha:0.25),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white
                                  .withValues(alpha:0.35),
                            ),
                          ),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Search spare part...',
                              border: InputBorder.none,
                              icon:
                                  const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                    Icons.qr_code_scanner),
                                onPressed: () async {
                                  final result =
                                      await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const BarcodeScannerPage(),
                                    ),
                                  );

                                  if (result != null &&
                                      result is String) {
                                    searchController.text =
                                        result;
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            onChanged: (_) =>
                                setState(() {}),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!widget.isCompact)
                  const SizedBox(height: 12),

                // ===== LIST =====
                Expanded(
                  child: StreamBuilder<List<SparePart>>(
                    stream: service.getSpareParts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading data'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final parts = snapshot.data!;
                      final keyword = widget.isCompact
    ? (widget.searchKeyword ?? '').toLowerCase()
    : searchController.text.toLowerCase();
                      final filteredParts = parts.where(
                        (part) {
                          return part.partCode
                                  .toLowerCase()
                                  .contains(keyword) ||
                              part.name
                                  .toLowerCase()
                                  .contains(keyword) ||
                              part.nameEn
                                  .toLowerCase()
                                  .contains(keyword);
                        },
                      ).toList();

                      if (filteredParts.isEmpty) {
                        return const Center(
                          child: Text('No data'),
                        );
                      }

                      return ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(
                                16, 0, 16, 16),
                        itemCount: filteredParts.length,
                        itemBuilder: (context, index) {
                          final part =
                              filteredParts[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditSparePartPage(
                                          part: part),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 8,
                                  sigmaY: 8,
                                ),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(
                                          bottom: 12),
                                  padding:
                                      const EdgeInsets.all(
                                          12),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha:0.25),
                                    borderRadius:
                                        BorderRadius
                                            .circular(14),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha:.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    10),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          color: Colors
                                              .white
                                              .withValues(
                                                  alpha:0.4),
                                          child: part
                                                  .imageUrl
                                                  .isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      part.imageUrl,
                                                  fit:
                                                      BoxFit
                                                          .cover,
                                                  placeholder:
                                                      (_, _) =>
                                                          const Center(
                                                    child:
                                                        SizedBox(
                                                      width:
                                                          18,
                                                      height:
                                                          18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth:
                                                            2,
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (_, _, _) =>
                                                          const Icon(
                                                    Icons
                                                        .inventory,
                                                    size:
                                                        28,
                                                    color:
                                                        Colors
                                                            .blueGrey,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons
                                                      .inventory,
                                                  size:
                                                      28,
                                                  color:
                                                      Colors
                                                          .blueGrey,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              part.name,
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: 4),
                                            Text(
                                              part.partCode,
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    12,
                                                color: Colors
                                                    .black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Stock: ${part.currentStock}',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
    );
  }
}
