import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/partner_service.dart';
import '../../models/partner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_partner_page.dart';
import 'edit_partner_page.dart';
import '../../theme/app_theme.dart';
import '../../models/read_tracker_service.dart';

class PartnerListPage extends StatefulWidget {
  final bool selectionMode;
  final Function(dynamic)? onSelected;
   final bool isWindow;

  const PartnerListPage({
    super.key,
    this.selectionMode = false,
    this.onSelected,
    this.isWindow = false,
  });
  

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final PartnerService service = PartnerService();
  bool _hasTracked = false;
  
  // Animation controllers
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'A-Z', 'Z-A', 'Recently Added'];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        floatingActionButton: widget.selectionMode
    ? null
    : ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
            backgroundColor: Colors.blueGrey.shade700,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Partner'),
            elevation: 8,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddPartnerPage(),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ),
        body: Stack(
          children: [
            // ===== BACKGROUND WITH ANIMATION =====
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
  gradient: AppTheme.backgroundGradient,
),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ===== HEADER =====
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildHeader(context),
                  ),

                  // ===== SEARCH & FILTER =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildFilterChips(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== STATISTICS CARD =====
                  _buildStatisticsCard(),

                  const SizedBox(height: 12),

                  // ===== LIST =====
                  Expanded(
                    child: StreamBuilder<List<Partner>>(
                      stream: service.getPartners(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const _ShimmerLoadingList();
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        final partners = snapshot.data!;

                       if (!_hasTracked && snapshot.hasData) {
  final partners = snapshot.data!;

  ReadTrackerService().trackRead(
    page: 'PartnerListPage',
    collection: 'partners',
    operation: 'stream',
    documentsCount: partners.length,
  );

  _hasTracked = true;
}
                        final keyword = searchController.text.toLowerCase();

                        List<Partner> filtered = partners.where((p) {
                          return p.name.toLowerCase().contains(keyword) ||
                              p.address.toLowerCase().contains(keyword);
                        }).toList();

                        // Apply sorting
                        filtered = _applyFilter(filtered);

                        if (filtered.isEmpty) {
                          return _buildNoSearchResults();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final partner = filtered[index];
                            
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              curve: Curves.easeOut,
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildPartnerCard(partner),
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
 

  // ================= STATISTICS CARD =================
  Widget _buildStatisticsCard() {
    return StreamBuilder<List<Partner>>(
      stream: service.getPartners(),
      builder: (context, snapshot) {
        final total = snapshot.data?.length ?? 0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatisticItem(
                    icon: Icons.business,
                    value: total.toString(),
                    label: 'Total Partners',
                    color: Colors.blue,
                  ),
                  _StatisticItem(
                    icon: Icons.location_on,
                    value: '${_countLocations(snapshot.data)}',
                    label: 'Locations',
                    color: Colors.green,
                  ),
                  _StatisticItem(
                    icon: Icons.star,
                    value: '${_countActivePartners(snapshot.data)}',
                    label: 'Active',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _countLocations(List<Partner>? partners) {
    if (partners == null) return 0;
    return partners.map((p) => '${p.lat},${p.lng}').toSet().length;
  }

  int _countActivePartners(List<Partner>? partners) {
    // You can implement active logic based on your business rules
    return partners?.length ?? 0;
  }

  // ================= FILTER CHIPS =================
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.white.withValues(alpha:0.2),
              selectedColor: Colors.blueGrey.shade300,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _selectedFilter == filter ? Colors.white : Colors.black87,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: Colors.white.withValues(alpha:0.5),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Partner> _applyFilter(List<Partner> partners) {
    final filtered = List<Partner>.from(partners);
    
    switch (_selectedFilter) {
      case 'A-Z':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Z-A':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Recently Added':
        // Assuming you have an addedDate field
        // filtered.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
    }
    return filtered;
  }

  // ================= ENHANCED PARTNER CARD =================
  Widget _buildPartnerCard(Partner partner) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
     onTap: () async {
  if (widget.selectionMode) {
    if (widget.onSelected != null) {
      widget.onSelected!(partner);
    } else {
      Navigator.pop(context, partner);
    }
    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditPartnerPage(partner: partner),
    ),
  );

  setState(() {});
},
      child: _GlassCard(
        child: _PartnerItem(partner: partner),
      ),
    );
  }

  // ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha:0.2),
            ),
            child: const Icon(
              Icons.business_center,
              size: 64,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Partners Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first partner',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "${searchController.text}"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.3),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Text(
  widget.selectionMode ? 'Select Partner' : 'Partners',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.more_vert, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SEARCH BAR =================
  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search partner...',
              border: InputBorder.none,
              icon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }
}

// ================= STATISTIC ITEM =================
class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ================= SHIMMER LOADING =================
class _ShimmerLoadingList extends StatelessWidget {
  const _ShimmerLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================= ENHANCED PARTNER ITEM =================
class _PartnerItem extends StatelessWidget {
  final Partner partner;

  const _PartnerItem({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LOGO WITH SHADOW
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.white.withValues(alpha: 0.4),
              child: partner.logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: partner.logoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.business, size: 28),
                    )
                  : const Icon(Icons.business, size: 28),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // DATA
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partner.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                partner.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${partner.lat?.toStringAsFixed(4) ?? '0.0000'}, ${partner.lng?.toStringAsFixed(4) ?? '0.0000'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================= GLASS CARD (enhanced) =================
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: child,
        ),
      ),
    );
  }
}