import 'package:flutter/material.dart';
import '../../core/widgets/draggable_window.dart';
import 'order_out_mobile.dart';
import 'order_out_desktop_history.dart';

class OrderOutDesktop extends StatelessWidget {
  const OrderOutDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 2;
        if (width > 1400) crossAxisCount = 3;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Order Out',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 1.2,
                  children: [

                    _buildMenu(
                      icon: Icons.add_box_rounded,
                      title: "Create Order Out",
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: "CreateOrderOut",
                          barrierColor: Colors.black.withValues(alpha: 0.35),
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder: (context, anim1, anim2) {
                            return DraggableResizableWindow(
                              title: "Create Order Out",
                              child: const OrderOutMobile(
                                isCompact: false,
                              ),
                            );
                          },
                        );
                      },
                    ),

                    _buildMenu(
                      icon: Icons.list_alt_rounded,
                      title: "Order History",
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: "OrderHistory",
                          barrierColor: Colors.black.withValues(alpha: 0.35),
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder: (context, anim1, anim2) {
                            return DraggableResizableWindow(
                              title: "Order History",
                              child: OrderOutDesktopHistory(
                                searchKeyword: '',
                                filterDate: null,
                                onTap: (context, data) {},
                              ),
                            );
                          },
                        );
                      },
                    ),

                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.12), // samakan dengan Order In
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
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
}