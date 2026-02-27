import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/spare_part_service.dart';
import '../../models/spare_part.dart';
import 'add_spare_part_page.dart';
import 'barcode_scanner_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'spare_part_detail_page.dart';
import '../../core/widgets/draggable_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';


class SparePartListPage extends StatefulWidget {
  final bool isCompact;
  final String? searchKeyword;
  final bool selectionMode;
  final ValueChanged<SparePart>? onSelected;
  final bool selectMode;


 const SparePartListPage({
  super.key,
  this.isCompact = false,
  this.searchKeyword,
  this.selectionMode = false,
  this.onSelected,
  this.selectMode = false,
});


  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // ================= SEARCH STATE =================
  List<SparePart> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String _currentSearchKeyword = ''; // Tambahkan ini

  // ===== PAGINATION STATE =====
  final ScrollController _scrollController = ScrollController();
  List<SparePart> _parts = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false; // Tambahkan ini untuk loading indicator
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    print("ACTIVE COMPANY (LIST PAGE): ${CompanySession.selectedCompanyId}");
    
    // Cek apakah ada searchKeyword dari parameter
    if (widget.searchKeyword != null && widget.searchKeyword!.isNotEmpty) {
      searchController.text = widget.searchKeyword!;
      _performSearch(widget.searchKeyword!);
    } else {
      _loadInitialData();
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          !_isLoadingMore &&
          _hasMore) {
        
        // Tentukan data mana yang akan di-load more
        if (_isSearching && _currentSearchKeyword.isNotEmpty) {
          _loadMoreSearchResults();
        } else {
          _loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    searchFocusNode.dispose();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===============================
  // SEARCH FUNCTION
  // ===============================
  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _currentSearchKeyword = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _currentSearchKeyword = keyword;
      _searchResults.clear(); // Reset hasil pencarian sebelumnya
    });

    final service = SparePartService();
    final results = await service.searchSpareParts(keyword);
    if (!mounted || _isDisposed) return;

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  // ===============================
  // LOAD MORE SEARCH RESULTS
  // ===============================
  Future<void> _loadMoreSearchResults() async {
    if (_currentSearchKeyword.isEmpty || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final service = SparePartService();
      // Anda perlu mengimplementasikan method search dengan pagination
      final moreResults = await service.searchSparePartsMore(
        keyword: _currentSearchKeyword,
        lastDoc: _lastDocument,
      );

      if (!mounted || _isDisposed) return;

      if (moreResults.isNotEmpty) {
        setState(() {
          _searchResults.addAll(moreResults);
        });
      }
    } catch (e) {
      print('Error loading more search results: $e');
    } finally {
     if (!mounted || _isDisposed) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // ===============================
  // INITIAL LOAD
  // ===============================
  Future<void> _loadInitialData() async {
  setState(() {
    _isLoading = true;
    _parts.clear();
    _lastDocument = null;
    _hasMore = true;
  });

  try {
    final service = SparePartService();
    final snapshot = await service.fetchSpareParts();

     if (!mounted || _isDisposed) return;

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      _parts = snapshot.docs
          .map((doc) => SparePart.fromFirestore(doc))
          .toList();
    }

    _hasMore = snapshot.docs.length == 50;
  } catch (e) {
    print('Error loading initial data: $e');
  } finally {
if (!mounted || _isDisposed) return;
   setState(() => _isLoading = false);
  }
}

  // ===============================
  // LOAD MORE
  // ===============================
  Future<void> _loadMore() async {
    if (_lastDocument == null || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final service = SparePartService();
      final snapshot = await service.fetchSpareParts(
        lastDoc: _lastDocument,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _parts.addAll(
          snapshot.docs.map(
            (doc) => SparePart.fromFirestore(doc),
          ),
        );
      }

      _hasMore = snapshot.docs.length == 50;
    } catch (e) {
      print('Error loading more: $e');
    } finally {
      if (!mounted || _isDisposed) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
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
                    child: _buildPartsList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsList() {
    // Tentukan data yang akan ditampilkan
    final displayList = _isSearching ? _searchResults : _parts;
    
    // Tentukan apakah masih ada data untuk di-load
    final hasMoreData = _isSearching ? false : _hasMore; // Sesuaikan dengan kebutuhan

    if (displayList.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (displayList.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.inventory,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No results found' : 'No spare parts available',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: displayList.length + (hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator di bawah
        if (hasMoreData && index == displayList.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final part = displayList[index];

        return GestureDetector(
  onTap: () {
    // ✅ SELECT MODE
    if (widget.selectionMode) {
      Navigator.pop(context, part);
      return;
    }

    // Normal mode
    if (widget.isCompact) return;

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "SparePartDetail",
        barrierColor: Colors.black.withOpacity(0.35),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) {
          return DraggableResizableWindow(
            title: "Spare Part Detail",
            headerColor: Colors.blueGrey,
            child: SparePartDetailPage(part: part),
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SparePartDetailPage(part: part),
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
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
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
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
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
                    _performSearch(result);
                  }
                },
              ),
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                _performSearch(value.trim());
              });
            },
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
          Hero(
            tag: 'spare-part-image-${part.partCode}',
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
