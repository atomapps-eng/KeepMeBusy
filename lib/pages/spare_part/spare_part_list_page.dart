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
import '../../theme/app_theme.dart';
import 'spare_part_detail_page_desktop.dart';
import '../../core/cache/spare_part_cache.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';

class SparePartListPage extends StatefulWidget {
  final bool isCompact;
  final String? searchKeyword;
  final bool selectionMode;
  final ValueChanged<SparePart>? onSelected;
  final bool selectMode;
  final bool isWindow;

  const SparePartListPage({
    super.key,
    this.isCompact = false,
    this.searchKeyword,
    this.selectionMode = false,
    this.onSelected,
    this.selectMode = false,
    this.isWindow = false,
  });

  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage>
    with AutomaticKeepAliveClientMixin {
  static const int _limit = 50;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
bool get wantKeepAlive => true;

  List<SparePart> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String _currentSearchKeyword = '';

  final ScrollController _scrollController = ScrollController();
  List<SparePart> _parts = [];
  bool _showLowStockOnly = false;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isFetchingMore = false;
  bool _isDisposed = false;
  bool _isGeneratingPdf = false;
double _pdfProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    
    if (widget.searchKeyword != null && widget.searchKeyword!.isNotEmpty) {
  searchController.text = widget.searchKeyword!;
  _performSearch(widget.searchKeyword!);
} else {
  _loadFromCache(); // 🔥 hanya ini
}

    _scrollController.addListener(() {
  if (_isFetchingMore) return;

  if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500 &&
      !_isLoading &&
      !_isLoadingMore &&
      _hasMore) {
    
    _isFetchingMore = true;

    if (_isSearching && _currentSearchKeyword.isNotEmpty) {
      _loadMoreSearchResults().then((_) {
        _isFetchingMore = false;
      });
    } else {
      _loadMore().then((_) {
        _isFetchingMore = false;
      });
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

  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) {
  setState(() {
    _isSearching = false;
    _searchResults.clear();
    _currentSearchKeyword = '';
    _lastDocument = null;
    _hasMore = true;
  });

  await _loadInitialData();
  return;
}

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _currentSearchKeyword = keyword;
      _searchResults.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    final service = SparePartService();
    final snapshot = await service.searchSpareParts(keyword: keyword);

    if (!mounted || _isDisposed) return;

    setState(() {
      _searchResults = snapshot.docs
          .map((doc) => SparePart.fromFirestore(doc))
          .toList();
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length == _limit;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreSearchResults() async {
    if (_currentSearchKeyword.isEmpty || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final service = SparePartService();
      final snapshot = await service.searchSpareParts(
        keyword: _currentSearchKeyword,
        lastDoc: _lastDocument,
      );

      if (!mounted || _isDisposed) return;

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _searchResults.addAll(
            snapshot.docs.map((doc) => SparePart.fromFirestore(doc)),
          );
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _limit;
        });
      } else {
        _hasMore = false;
      }
    } catch (e) {
    } finally {
      if (!mounted || _isDisposed) return;
      setState(() => _isLoadingMore = false);
    }
  }

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
        _parts = snapshot.docs.map((doc) => SparePart.fromFirestore(doc)).toList();
        await SparePartCache().save(_parts);
      }
      _hasMore = snapshot.docs.length == _limit;
    } catch (e) {
    } finally {
      if (!mounted || _isDisposed) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLowStockData() async {
  setState(() {
    _isLoading = true;
    _parts.clear();
    _lastDocument = null;
    _hasMore = true;
  });

  try {
    final service = SparePartService();
    final snapshot = await service.fetchLowStockParts();

    if (!mounted || _isDisposed) return;

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      _parts = snapshot.docs
          .map((doc) => SparePart.fromFirestore(doc))
          .toList();
    }

    _hasMore = snapshot.docs.length == _limit;
  } catch (e) {
  } finally {
    if (!mounted || _isDisposed) return;
    setState(() => _isLoading = false);
  }
}

  Future<void> _loadMore() async {
   if (_lastDocument == null || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final service = SparePartService();
      final snapshot = await service.fetchSpareParts(lastDoc: _lastDocument);

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _parts.addAll(
  snapshot.docs.map((doc) => SparePart.fromFirestore(doc)),
);

await SparePartCache().save(_parts);
      }
     _hasMore = snapshot.docs.length == _limit;
    } catch (e) {
    } finally {
      if (!mounted || _isDisposed) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
Widget build(BuildContext context) {
  super.build(context);
    final content = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient,
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
    );

    if (widget.isWindow) {
      return content;
    }

    return Scaffold(
      floatingActionButton: widget.isCompact
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Spare Part'),
              onPressed: () {
                final isDesktop = MediaQuery.of(context).size.width >= 900;
                if (isDesktop) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.transparent,
                    builder: (context) {
                      return DraggableResizableWindow(
                        title: "Add Spare Part",
                        headerColor: Colors.blueGrey,
                        child: const AddSparePartPage(isWindow: true),
                      );
                    },
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddSparePartPage(),
                    ),
                  );
                }
              },
            ),
      body: content,
    );
  }

  Widget _buildPartsList() {
    List<SparePart> displayList;

if (_isSearching) {
  displayList = _searchResults;
} else if (_showLowStockOnly) {
  displayList = _parts.where((p) => p.currentStock <= 0).toList();
} else {
  displayList = _parts;
}
    final hasMoreData = _hasMore;

    if (displayList.isEmpty && _isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading spare parts...'),
          ],
        ),
      );
    }

    if (displayList.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSearching ? Icons.search_off : Icons.inventory,
                size: 64,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No results found' : 'No spare parts available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Try adjusting your search'
                  : 'Get started by adding your first spare part',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (!_isSearching) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final isDesktop = MediaQuery.of(context).size.width >= 900;
                  if (isDesktop) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.transparent,
                      builder: (context) {
                        return DraggableResizableWindow(
                          title: "Add Spare Part",
                          headerColor: Colors.blueGrey,
                          child: const AddSparePartPage(isWindow: true),
                        );
                      },
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSparePartPage(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Spare Part'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: displayList.length + (hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
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
          onTap: () async {
            if (widget.selectionMode) {
              if (widget.onSelected != null) {
                widget.onSelected!(part);
              } else {
                Navigator.pop(context, part);
              }
              return;
            }

            if (widget.isCompact) return;

            final isDesktop = MediaQuery.of(context).size.width >= 900;

            if (isDesktop) {
              final result = await showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "SparePartDetail",
                barrierColor: Colors.black.withOpacity(0.35),
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (_, _, _) {
                  return DraggableResizableWindow(
                    title: "Spare Part Detail",
                    headerColor: Colors.blueGrey,
                    child: SparePartDetailPageDesktop(part: part),
                  );
                },
              );

              if (result == true) {
                _loadInitialData();
              }
            } else {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SparePartDetailPage(part: part),
                ),
              );

              if (result == true && mounted) {
                if (_isSearching && _currentSearchKeyword.isNotEmpty) {
                  await _performSearch(_currentSearchKeyword);
                } else {
                  await _loadInitialData();
                }
              }
            }
          },
          child: _ModernCard(
            part: part,
            isCompact: widget.isCompact,
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
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
  children: [
    Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    const SizedBox(width: 8),
    Text(
      widget.selectionMode
          ? 'Select Spare Part'
          : 'Spare Part Database',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    const Spacer(),

    // 🔥 LOW STOCK ICON
    GestureDetector(
  onTap: () async {
    setState(() {
      _showLowStockOnly = !_showLowStockOnly;
    });

    if (_showLowStockOnly) {
      await _loadLowStockData();
    } else {
      await _loadInitialData();
    }
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _showLowStockOnly
          ? Colors.red.withOpacity(0.2)
          : Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: _showLowStockOnly ? Colors.red : Colors.black87,
        ),
        const SizedBox(width: 6),
        Text(
          'Low Stock',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _showLowStockOnly ? Colors.red : Colors.black87,
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(width: 8),

GestureDetector(
  onTap: () async {
  final confirm = await _confirmPrintPdf();
  if (!confirm) return;

  await _generateLowStockPdf();
},
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: const [
        Icon(Icons.picture_as_pdf, size: 18),
        SizedBox(width: 6),
        Text(
          'PDF',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
),

  ],
)
        ),
      ),
    );
  }

  void _showProgressDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Generating PDF'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _pdfProgress),
                const SizedBox(height: 12),
                Text('${(_pdfProgress * 100).toStringAsFixed(0)} %'),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search spare part by code or name...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB)),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 400), () {
            _performSearch(value.trim());
          });
        },
      ),
    );
  }

  Future<void> _loadFromCache() async {
  final cache = SparePartCache();

  final cachedData = await cache.load();
  final isExpired = await cache.isExpired();

  if (cachedData.isNotEmpty) {
    setState(() {
      _parts = cachedData;
    });
  }

  // 🔥 hanya fetch kalau expired
  if (isExpired) {
    _loadInitialData();
  }
}

Future<void> _generateLowStockPdf() async {
  setState(() {
    _isGeneratingPdf = true;
    _pdfProgress = 0.0;
  });

  _showProgressDialog();

  final service = SparePartService();

  final snapshot = await service.fetchLowStockParts();

  final parts = snapshot.docs
      .map((doc) => SparePart.fromFirestore(doc))
      .toList();

  final tableData = <List<String>>[];

for (int i = 0; i < parts.length; i++) {
  final p = parts[i];

  tableData.add([
    (i + 1).toString(), // 🔥 nomor
    p.partCode,
    p.name,
    p.currentStock.toString(),
    p.location,
  ]);

  // 🔥 progress tetap jalan
  _pdfProgress = (i + 1) / parts.length;
  setState(() {});
  await Future.delayed(const Duration(milliseconds: 5));
}

  final pdf = pw.Document();

  final regularFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );

  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
  );

  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/Atom.png'))
        .buffer
        .asUint8List(),
  );

  _pdfProgress = 0.2;
  setState(() {});

  pdf.addPage(
    pw.MultiPage(
      build: (context) {
        _pdfProgress = 0.5;
        return [
          pw.Row(
            children: [
              pw.Image(logo, width: 40, height: 40),
              pw.SizedBox(width: 10),
              pw.Text(
                'Low Stock Report',
                style: pw.TextStyle(font: boldFont, fontSize: 20),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Table.fromTextArray(
  headers: ['No', 'Code', 'Name', 'Stock', 'Location'],

  data: tableData,

  headerStyle: pw.TextStyle(
    font: boldFont,
    color: PdfColors.white,
  ),

  headerDecoration: const pw.BoxDecoration(
    color: PdfColors.orange,
  ),

  cellStyle: pw.TextStyle(
    font: regularFont,
    fontSize: 10,
  ),

  columnWidths: {
    0: const pw.FixedColumnWidth(30), // No
    1: const pw.FlexColumnWidth(2),   // Code
    2: const pw.FlexColumnWidth(4),   // Name
    3: const pw.FlexColumnWidth(2),   // Stock
    4: const pw.FlexColumnWidth(3),   // Location
  },
),
        ];
      },
    ),
  );

  _pdfProgress = 0.8;
  setState(() {});

  final bytes = await pdf.save();

  if (kIsWeb) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "low_stock_report.pdf")
      ..click();

    html.Url.revokeObjectUrl(url);
  } else {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/low_stock_report.pdf');

    await file.writeAsBytes(bytes);

    await OpenFilex.open(file.path);
  }

  _pdfProgress = 1.0;
  setState(() {});

  Navigator.pop(context); // close progress dialog

  setState(() {
    _isGeneratingPdf = false;
  });
}

Future<bool> _confirmPrintPdf() async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Generate PDF'),
        content: const Text(
          'Do you want to generate a low stock report as PDF?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
  
}

// =====================================================
// MODERN CARD
// =====================================================
class _ModernCard extends StatelessWidget {
  final SparePart part;
  final bool isCompact;

  const _ModernCard({
    required this.part,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.partCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                part.nameEn,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: part.currentStock > 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Stock: ${part.currentStock}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: part.currentStock > 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  part.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
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

  Widget _buildFullLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Thumbnail
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF1F5F9),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: part.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: part.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.inventory, size: 32, color: Color(0xFF94A3B8)),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.inventory, size: 32, color: Color(0xFF94A3B8)),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      part.partCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: part.currentStock > 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stock: ${part.currentStock}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: part.currentStock > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                part.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                part.nameEn,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    part.location,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.category, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    part.category.name.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}