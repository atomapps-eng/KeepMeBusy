import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/partner_service.dart';
import '../../models/partner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_partner_page.dart';
import 'edit_partner_page.dart';



class PartnerListPage extends StatefulWidget {
  const PartnerListPage({super.key});

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final PartnerService service = PartnerService();

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddPartnerPage(),
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
                  // ===== HEADER =====
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildHeader(context),
                  ),

                  // ===== SEARCH =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSearchBar(),
                  ),

                  const SizedBox(height: 12),

                  // ===== LIST =====
                  Expanded(
                    child: StreamBuilder<List<Partner>>(
                      stream: service.getPartners(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final partners = snapshot.data!;
                        final keyword =
                            searchController.text.toLowerCase();

                        final filtered = partners.where((p) {
                          return p.name.toLowerCase().contains(keyword) ||
                              p.address.toLowerCase().contains(keyword);
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text('No data'),
                          );
                        }

                        return ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final partner = filtered[index];

                            return InkWell(
  borderRadius: BorderRadius.circular(14),
  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPartnerPage(partner: partner),
      ),
    );
  },
  child: _GlassCard(
    child: _PartnerItem(partner: partner),
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
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Partners',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SEARCH =================
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
            decoration: const InputDecoration(
              hintText: 'Search partner...',
              border: InputBorder.none,
              icon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// PARTNER ITEM (READ ONLY)
// =====================================================
class _PartnerItem extends StatelessWidget {
  final Partner partner;

  const _PartnerItem({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LOGO
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 56,
            height: 56,
            color: Colors.white.withValues(alpha: 0.4),
            child: partner.logoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: partner.logoUrl,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.business, size: 28),
          ),
        ),

        const SizedBox(width: 12),

        // DATA
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
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
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${partner.lat}, ${partner.lng}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
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
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }
}
