import 'dart:ui';
import 'package:flutter/material.dart';
import 'menu_config.dart';

class FloatingMenuLauncher {
  static void open(
    BuildContext context,
    MenuConfig config,
  ) {
    // Jika menu tidak mendukung floating → langsung fullscreen
    if (!config.enableFloating) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => config.pageBuilder(
            isCompact: false,
            searchKeyword: null,
          ),
        ),
      );
      return;
    }

    // ===== SINGLE SOURCE OF TRUTH =====
    final ValueNotifier<String> searchNotifier =
        ValueNotifier<String>('');

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Floating',
      barrierColor: Colors.black.withValues(alpha:0.35),
      transitionDuration: const Duration(milliseconds: 220),

      pageBuilder: (
        BuildContext dialogContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return Center(
          child: _FloatingOverlayContainer(
            title: config.label,
            enableFullscreen: config.enableFullscreen,
            onClose: () => Navigator.pop(dialogContext),
            onFullscreen: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => config.pageBuilder(
                    isCompact: false,
                    searchKeyword: searchNotifier.value,
                  ),
                ),
              );
            },
            onSearchChanged: (value) {
              searchNotifier.value = value;
              debugPrint(
                  'DEBUG ▶ floating search changed: "$value"');
            },
            child: ValueListenableBuilder<String>(
              valueListenable: searchNotifier,
              builder: (context, value, _) {
                return config.pageBuilder(
                  isCompact: true,
                  searchKeyword: value,
                );
              },
            ),
          ),
        );
      },

      // ===== ANIMATION (FADE + SCALE HALUS) =====
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 0.96, end: 1.0)
                    .animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _FloatingOverlayContainer extends StatelessWidget {
  final String title;
  final bool enableFullscreen;
  final VoidCallback onClose;
  final VoidCallback onFullscreen;
  final ValueChanged<String> onSearchChanged;
  final Widget child;

  const _FloatingOverlayContainer({
    required this.title,
    required this.enableFullscreen,
    required this.onClose,
    required this.onFullscreen,
    required this.onSearchChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 700;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width:
              isTablet ? size.width * 0.6 : size.width * 0.9,
          height: isTablet
              ? size.height * 0.7
              : size.height * 0.75,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFE0B2),
                Color(0xFFFFFFFF),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.25),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // ===== UTILITY BAR =====
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    // SEARCH
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          onChanged: onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(
                                Icons.search,
                                size: 18),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            filled: true,
                            fillColor:
                                Colors.white.withValues(alpha:0.7),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    if (enableFullscreen)
                      IconButton(
                        icon: const Icon(
                            Icons.open_in_full),
                        onPressed: onFullscreen,
                      ),

                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ===== CONTENT =====
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
