import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/partner_service.dart';
import '../../models/partner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_partner_page.dart';
import 'edit_partner_page.dart';
import '../../theme/app_theme.dart';
import '../../models/read_tracker_service.dart';
import '../../core/widgets/draggable_window.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.selectionMode
          ? null
          : ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Partner'),
                elevation: 0,
                onPressed: () async {
                  if (isDesktop) {
                    await showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: "AddPartner",
                      barrierColor: Colors.black.withOpacity(0.3),
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (dialogContext, _, __) {
                        return DraggableResizableWindow(
                          title: "Add Partner",
                          child: const AddPartnerPage(isWindow: true),
                        );
                      },
                    );
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPartnerPage(),
                      ),
                    );
                  }
                  setState(() {});
                },
              ),
            ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(context),
                const SizedBox(height: 8),
                _buildModernSearchBar(),
                const SizedBox(height: 12),
                _buildModernFilterChips(),
                const SizedBox(height: 16),
                _buildModernStatisticsCard(),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<Partner>>(
                    stream: service.getPartners(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _ModernShimmerLoading();
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildModernEmptyState();
                      }

                      final partners = snapshot.data!;

                      if (!_hasTracked && snapshot.hasData) {
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

                      filtered = _applyFilter(filtered);

                      if (filtered.isEmpty) {
                        return _buildModernNoResults();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final partner = filtered[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(milliseconds: 250 + (index * 30)),
                            curve: Curves.easeOut,
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 15 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildModernPartnerCard(partner, isDesktop),
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

    final content = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: scaffold,
    );

    if (widget.isWindow) {
      return scaffold.body!;
    }

    return content;
  }

  Widget _buildModernHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
          Text(
            widget.selectionMode ? 'Select Partner' : 'Partners',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                StreamBuilder<List<Partner>>(
                  stream: service.getPartners(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Text(
                      '$count Partners',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search partners by name or address...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModernStatisticsCard() {
    return StreamBuilder<List<Partner>>(
      stream: service.getPartners(),
      builder: (context, snapshot) {
        final total = snapshot.data?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildModernStatItem(
                    icon: Icons.business_outlined,
                    value: total.toString(),
                    label: 'Total Partners',
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade200,
                  ),
                  _buildModernStatItem(
                    icon: Icons.location_on_outlined,
                    value: '${_countLocations(snapshot.data)}',
                    label: 'Locations',
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade200,
                  ),
                  _buildModernStatItem(
                    icon: Icons.star_outline,
                    value: '${_countActivePartners(snapshot.data)}',
                    label: 'Active',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildModernPartnerCard(Partner partner, bool isDesktop) {
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (widget.selectionMode) {
            if (widget.onSelected != null) {
              widget.onSelected!(partner);
            } else {
              Navigator.pop(context, partner);
            }
            return;
          }

          if (isDesktop) {
            await showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "EditPartner",
              barrierColor: Colors.black.withOpacity(0.3),
              transitionDuration: const Duration(milliseconds: 200),
              pageBuilder: (dialogContext, _, __) {
                return DraggableResizableWindow(
                  title: "Edit Partner",
                  child: EditPartnerPage(
                    partner: partner,
                    isWindow: true,
                  ),
                );
              },
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditPartnerPage(partner: partner),
              ),
            );
          }
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: partner.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: partner.logoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFEFF6FF),
                            child: const Icon(Icons.business, size: 28, color: Color(0xFF2563EB)),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.business, size: 28, color: Color(0xFF2563EB)),
                        )
                      : const Icon(Icons.business, size: 28, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 16),
              // Data
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
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            partner.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gps_fixed, size: 10, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            '${partner.lat?.toStringAsFixed(4) ?? '0.0000'}, ${partner.lng?.toStringAsFixed(4) ?? '0.0000'}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              if (!widget.selectionMode)
                const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_outlined,
              size: 56,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Partners Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first partner',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            '"${searchController.text}"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  int _countLocations(List<Partner>? partners) {
    if (partners == null) return 0;
    return partners.map((p) => '${p.lat},${p.lng}').toSet().length;
  }

  int _countActivePartners(List<Partner>? partners) {
    return partners?.length ?? 0;
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
        break;
    }
    return filtered;
  }
}

// ================= MODERN SHIMMER LOADING =================
class _ModernShimmerLoading extends StatelessWidget {
  const _ModernShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
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