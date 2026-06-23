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
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;

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
  final Map<String, List<SparePart>> _searchCache = {};
  bool _isSearching = false;
  Timer? _debounce;
  Timer? _syncTimer;
  String _currentSearchKeyword = '';
  int _searchRequestId = 0;

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
  bool _isFabOpen = false;
  bool _isMultiSelectMode = false;
  final Map<String, SparePart> _selectedParts = {};
  double _pdfProgress = 0.0;

  final Duration _fabAnimDuration = const Duration(milliseconds: 220);
  final Curve _fabAnimCurve = Curves.easeOut;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _scrollController.addListener(() {
      if (_isFetchingMore) return;

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 500 &&
          !_isLoading &&
          !_isLoadingMore &&
          !_isSearching &&
          _hasMore) {
        _isFetchingMore = true;

        if (!_isSearching) {
          _loadMore().then((_) {
            _isFetchingMore = false;
          });
        } else {
          _isFetchingMore = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _syncTimer?.cancel();
    searchFocusNode.dispose();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    final trimmedKeyword = keyword.trim();
    final normalizedKeyword = _normalizeSearchText(trimmedKeyword);
    final requestId = ++_searchRequestId;

    if (normalizedKeyword.isEmpty) {
      setState(() {
        _isSearching = false;
        _isLoading = false;
        _searchResults.clear();
        _currentSearchKeyword = '';
      });
      _resetListScroll(requestId);
      return;
    }

    final localResults = _sortSearchResults(
      _parts.where((part) => _matchesSearch(part, normalizedKeyword)).toList(),
      normalizedKeyword,
    );
    debugPrint('TOTAL PARTS LOADED = ${_parts.length}');
debugPrint('LOCAL SEARCH RESULT = ${localResults.length}');
    if (localResults.isNotEmpty) {
      _searchCache[normalizedKeyword] = List<SparePart>.unmodifiable(
        localResults,
      );
    }

    setState(() {
      _isSearching = true;
      _isLoading = localResults.isEmpty && normalizedKeyword.length >= 2;
      _currentSearchKeyword = normalizedKeyword;
      _searchResults = localResults;
    });
    _resetListScroll(requestId);

    // Satu karakter dicari hanya dari cache agar tidak membuat query yang luas.
    if (normalizedKeyword.length < 2 || localResults.isNotEmpty) return;

    final cachedResults = _searchCache[normalizedKeyword];
    if (cachedResults != null) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResults = cachedResults;
        _isLoading = false;
      });
      _resetListScroll(requestId);
      return;
    }

    final service = SparePartService();
    try {
      final snapshot = await service.searchSpareParts(
        keyword: trimmedKeyword,
        limit: 25,
      );

      final remoteResults = snapshot.docs
          .map((doc) => SparePart.fromFirestore(doc))
          .where((part) => _matchesSearch(part, normalizedKeyword))
          .toList();
      final resultsById = <String, SparePart>{
        for (final part in localResults) part.id: part,
        for (final part in remoteResults) part.id: part,
      };
      final combinedResults = _sortSearchResults(
        resultsById.values.toList(),
        normalizedKeyword,
      );

      _searchCache[normalizedKeyword] = combinedResults;

      if (!mounted || _isDisposed || requestId != _searchRequestId) return;

      setState(() {
        _searchResults = combinedResults;
        _isLoading = false;
      });
      _resetListScroll(requestId);
    } catch (_) {
      if (!mounted || _isDisposed || requestId != _searchRequestId) return;
      setState(() => _isLoading = false);
    }
  }

  void _resetListScroll(int requestId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isDisposed ||
          requestId != _searchRequestId ||
          !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(0);
    });
  }

  Future<void> _initializeData() async {
    await _loadFromCache();
    _syncTimer?.cancel();

_syncTimer = Timer.periodic(
  const Duration(minutes: 1),
  (_) {
    _checkForServerUpdates();
  },
);
    if (!mounted || _isDisposed) return;

    final initialKeyword = widget.searchKeyword?.trim() ?? '';
    if (initialKeyword.isNotEmpty) {
      searchController.text = initialKeyword;
      await _performSearch(initialKeyword);
    }
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  bool _matchesSearch(SparePart part, String normalizedKeyword) {
    final searchableText = _normalizeSearchText(
      [
        part.partCode,
        part.name,
        part.nameEn,
        part.location,
        part.category.toString(),
        part.origin.toString(),
      ].join(' '),
    );

    return searchableText.contains(normalizedKeyword);
  }

  List<SparePart> _sortSearchResults(
    List<SparePart> results,
    String normalizedKeyword,
  ) {
    int score(SparePart part) {
      final code = _normalizeSearchText(part.partCode);
      final name = _normalizeSearchText('${part.name} ${part.nameEn}');
      if (code == normalizedKeyword) return 0;
      if (code.startsWith(normalizedKeyword)) return 1;
      if (name.startsWith(normalizedKeyword)) return 2;
      return 3;
    }

    results.sort((a, b) {
      final scoreComparison = score(a).compareTo(score(b));
      if (scoreComparison != 0) return scoreComparison;
      return a.partCode.compareTo(b.partCode);
    });
    return results;
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
      final snapshot = await service.fetchAllSpareParts();

      if (!mounted || _isDisposed) return;

      if (snapshot.docs.isNotEmpty) {
  _lastDocument = snapshot.docs.last;

  _parts = snapshot.docs
      .map((doc) => SparePart.fromFirestore(doc))
      .toList();

      debugPrint(
  'FULL SYNC LOADED = ${_parts.length}',
);

  final cache = SparePartCache();

  await cache.save(_parts);

  final latestServerTime =
      await service.getLatestServerUpdateTime();

  if (latestServerTime != null) {
    await cache.saveServerSyncTime(
      latestServerTime,
    );
  }
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
        _parts.addAll(snapshot.docs.map((doc) => SparePart.fromFirestore(doc)));

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
            decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
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
                Expanded(child: _buildPartsList()),
                if (_isMultiSelectMode) _buildMultiSelectBar(),
              ],
            ),
          ),
          if (_isFabOpen)
            Positioned.fill(
              child: Stack(
                children: [
                  // 🔥 1. BLOCK TAP KE BAWAH
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.2),
                  ),

                  // 🔥 2. BLUR
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: Colors.transparent),
                  ),

                  // 🔥 3. TAP UNTUK CLOSE
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _isFabOpen = false;
                      });
                    },
                    child: Container(color: Colors.transparent),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      floatingActionButton: widget.isCompact || _isMultiSelectMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 🔥 CHILD BUTTONS (muncul kalau open)
                ...[
                  _buildAnimatedFabItem(
                    index: 0,
                    child: FloatingActionButton.extended(
                      heroTag: "low_stock",
                      backgroundColor: _showLowStockOnly
                          ? Colors.green
                          : Colors.red,
                      foregroundColor: Colors.white,
                      elevation: _showLowStockOnly ? 6 : 2,
                      icon: Icon(
                        _showLowStockOnly
                            ? Icons.list
                            : Icons.warning_amber_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _showLowStockOnly ? 'Show All Stock' : 'Show Low Stock',
                      ),
                      onPressed: () async {
                        setState(() {
                          _showLowStockOnly = !_showLowStockOnly;
                          _isFabOpen = false;
                        });

                        if (_showLowStockOnly) {
                          await _loadLowStockData();
                        } else {
                          await _loadInitialData();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildAnimatedFabItem(
                    index: 1,
                    child: FloatingActionButton.extended(
                      heroTag: "pdf",
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Print PDF Low Stock'),
                      onPressed: () async {
                        setState(() => _isFabOpen = false);

                        final confirm = await _confirmPrintPdf();
                        if (!confirm) return;

                        await _generateLowStockPdf();
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildAnimatedFabItem(
                    index: 2,
                    child: FloatingActionButton.extended(
                      heroTag: "add",
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Spare Part'),
                      onPressed: () {
                        setState(() => _isFabOpen = false);

                        final isDesktop =
                            MediaQuery.of(context).size.width >= 900;
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
                  ),

                  const SizedBox(height: 10),
                ],

                // 🔥 MAIN BUTTON (toggle)
                FloatingActionButton(
                  heroTag: "main_fab",
                  backgroundColor: const Color(0xFF2563EB),
                  child: Icon(_isFabOpen ? Icons.close : Icons.menu),
                  onPressed: () {
                    setState(() {
                      _isFabOpen = !_isFabOpen;
                    });
                  },
                ),
              ],
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
    final hasMoreData = !_isSearching && _hasMore;

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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final part = displayList[index];
        final isSelected = _selectedParts.containsKey(part.id);
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

            if (_isMultiSelectMode) {
              _togglePartSelection(part);
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
          onLongPress: widget.selectionMode || widget.isCompact
              ? null
              : () {
                  if (!_isMultiSelectMode) {
                    setState(() => _isMultiSelectMode = true);
                  }
                  _togglePartSelection(part);
                },
          child: _ModernCard(
            part: part,
            isCompact: widget.isCompact,
            isSelectionMode: _isMultiSelectMode,
            isSelected: isSelected,
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectionMode
                          ? 'Select Spare Part'
                          : 'Spare Part Database',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _showLowStockOnly ? 'Low Stock' : 'All Stock',
                        key: ValueKey(_showLowStockOnly),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _showLowStockOnly ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.selectionMode && !widget.isCompact)
                TextButton.icon(
                  onPressed: _isGeneratingPdf
                      ? null
                      : () {
                          setState(() {
                            _isMultiSelectMode = !_isMultiSelectMode;
                            if (!_isMultiSelectMode) _selectedParts.clear();
                            _isFabOpen = false;
                          });
                        },
                  icon: Icon(
                    _isMultiSelectMode ? Icons.close : Icons.checklist,
                  ),
                  label: Text(_isMultiSelectMode ? 'Cancel' : 'Select'),
                ),
            ],
          ),
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
          hintText: 'Search by code, name, location, or category...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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

  void _togglePartSelection(SparePart part) {
    setState(() {
      if (_selectedParts.containsKey(part.id)) {
        _selectedParts.remove(part.id);
      } else {
        _selectedParts[part.id] = part;
      }
    });
  }

  List<SparePart> get _visibleParts {
    if (_isSearching) return _searchResults;
    if (_showLowStockOnly) {
      return _parts.where((part) => part.currentStock <= 0).toList();
    }
    return _parts;
  }

  Widget _buildMultiSelectBar() {
    final visibleParts = _visibleParts;
    final allVisibleSelected =
        visibleParts.isNotEmpty &&
        visibleParts.every((part) => _selectedParts.containsKey(part.id));
    final countLabel = Text(
      '${_selectedParts.length} part selected',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    );
    final selectVisibleButton = TextButton(
      onPressed: visibleParts.isEmpty
          ? null
          : () {
              setState(() {
                if (allVisibleSelected) {
                  for (final part in visibleParts) {
                    _selectedParts.remove(part.id);
                  }
                } else {
                  for (final part in visibleParts) {
                    _selectedParts[part.id] = part;
                  }
                }
              });
            },
      child: Text(allVisibleSelected ? 'Clear visible' : 'Select visible'),
    );
    final shareButton = ElevatedButton.icon(
      onPressed: _selectedParts.isEmpty || _isGeneratingPdf
          ? null
          : _shareSelectedPartsPdf,
      icon: _isGeneratingPdf
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.share, size: 18),
      label: const Text('Share PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  countLabel,
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: selectVisibleButton),
                      const SizedBox(width: 8),
                      Expanded(child: shareButton),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: countLabel),
                selectVisibleButton,
                const SizedBox(width: 6),
                shareButton,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _shareSelectedPartsPdf() async {
    final parts = _selectedParts.values.toList()
      ..sort((a, b) => a.partCode.compareTo(b.partCode));
    if (parts.isEmpty) return;

    setState(() {
      _isGeneratingPdf = true;
      _pdfProgress = 0;
    });

    try {
      final regularFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      );
      final boldFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
      );
      final images = <String, pw.MemoryImage>{};

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.imageUrl.isNotEmpty) {
          try {
            final response = await http
                .get(Uri.parse(part.imageUrl))
                .timeout(const Duration(seconds: 15));
            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              images[part.id] = pw.MemoryImage(response.bodyBytes);
            }
          } catch (_) {
            // PDF tetap dibuat jika satu foto tidak dapat diunduh.
          }
        }
        if (mounted) {
          setState(() => _pdfProgress = (i + 1) / (parts.length + 1));
        }
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          header: (_) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blueGrey300),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SPARE PART LIST',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
                pw.Text('${parts.length} part(s)'),
              ],
            ),
          ),
          build: (_) => [
            pw.SizedBox(height: 14),
            ...parts.asMap().entries.map((entry) {
              final part = entry.value;
              final image = images[part.id];
              final description = [
                part.name,
                part.nameEn,
              ].where((value) => value.trim().isNotEmpty).join('\n');

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 86,
                      height: 86,
                      color: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                      child: image == null
                          ? pw.Text(
                              'No photo',
                              style: const pw.TextStyle(fontSize: 9),
                            )
                          : pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            part.partCode,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 14,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            description.isEmpty ? '-' : description,
                            style: const pw.TextStyle(
                              fontSize: 11,
                              lineSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'spare_parts_${DateTime.now().millisecondsSinceEpoch}.pdf';
      XFile pdfFile;
      if (kIsWeb) {
        pdfFile = XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: fileName,
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        pdfFile = XFile(file.path, mimeType: 'application/pdf', name: fileName);
      }

      if (!mounted) return;
      final renderBox = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [pdfFile],
        text: 'Spare part list (${parts.length} part)',
        subject: 'Spare Part List',
        sharePositionOrigin: renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size,
      );

      if (mounted) {
        setState(() => _pdfProgress = 1);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create PDF: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _checkForServerUpdates() async {
    debugPrint('SYNC CHECK RUNNING');
  try {
    final cache = SparePartCache();
    final service = SparePartService();

    final serverUpdateTime =
        await service.getLatestServerUpdateTime();

    final localSyncTime =
        await cache.getServerSyncTime();

    if (serverUpdateTime == null) {
      return;
    }

    if (localSyncTime == null ||
        serverUpdateTime.isAfter(localSyncTime)) {

      debugPrint(
        'SERVER CHANGE DETECTED -> REFRESH CACHE',
      );

      await _loadInitialData();
    }
  } catch (e) {
    debugPrint(
      'SYNC CHECK ERROR: $e',
    );
  }
}

  Future<void> _loadFromCache() async {
  final cache = SparePartCache();

  final cachedData = await cache.load();

  debugPrint(
  'CACHE PART COUNT = ${cachedData.length}',
);

  if (cachedData.isNotEmpty) {
    if (!mounted || _isDisposed) return;

    setState(() {
      _parts = cachedData;
    });
  }

  final service = SparePartService();

  final serverUpdateTime =
      await service.getLatestServerUpdateTime();

  final localSyncTime =
      await cache.getServerSyncTime();

  final needRefresh =
      serverUpdateTime == null ||
      localSyncTime == null ||
      serverUpdateTime.isAfter(localSyncTime);

      debugPrint(
  'SERVER UPDATE = $serverUpdateTime',
);

debugPrint(
  'LOCAL SYNC = $localSyncTime',
);

debugPrint(
  'NEED REFRESH = $needRefresh',
);

  if (needRefresh) {
    await _loadInitialData();
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
      (await rootBundle.load('assets/images/Atom.png')).buffer.asUint8List(),
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

              headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),

              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),

              cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),

              columnWidths: {
                0: const pw.FixedColumnWidth(30), // No
                1: const pw.FlexColumnWidth(2), // Code
                2: const pw.FlexColumnWidth(4), // Name
                3: const pw.FlexColumnWidth(2), // Stock
                4: const pw.FlexColumnWidth(3), // Location
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

  Widget _buildAnimatedFabItem({required int index, required Widget child}) {
    final delay = index * 50;

    return AnimatedOpacity(
      duration: _fabAnimDuration,
      curve: _fabAnimCurve,
      opacity: _isFabOpen ? 1 : 0,
      child: AnimatedSlide(
        duration: _fabAnimDuration,
        curve: _fabAnimCurve,
        offset: _isFabOpen ? Offset.zero : Offset(0, 0.3 + (0.1 * index)),
        child: Padding(
          padding: EdgeInsets.only(bottom: delay.toDouble() * 0.1),
          child: child,
        ),
      ),
    );
  }
}

// =====================================================
// MODERN CARD
// =====================================================
class _ModernCard extends StatelessWidget {
  final SparePart part;
  final bool isCompact;
  final bool isSelectionMode;
  final bool isSelected;

  const _ModernCard({
    required this.part,
    required this.isCompact,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFDBEAFE).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          width: 2,
        ),
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
        if (isSelectionMode) ...[
          Checkbox(value: isSelected, onChanged: null),
          const SizedBox(width: 6),
        ],
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
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
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: Color(0xFF64748B),
                ),
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
        if (isSelectionMode) ...[
          Checkbox(value: isSelected, onChanged: null),
          const SizedBox(width: 6),
        ],
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
                      child: Icon(
                        Icons.inventory,
                        size: 32,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.inventory,
                      size: 32,
                      color: Color(0xFF94A3B8),
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                        color: part.currentStock > 0
                            ? Colors.green
                            : Colors.red,
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: Color(0xFF64748B),
                  ),
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
                  const Icon(
                    Icons.category,
                    size: 12,
                    color: Color(0xFF64748B),
                  ),
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
