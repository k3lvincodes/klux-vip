import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class KenickBottomNavBar extends StatelessWidget {
  const KenickBottomNavBar({
    super.key,
    required this.currentIndex,
    this.showQuickBookFab = true,
    this.onQuickBookTap,
  });

  final int currentIndex; // 0 = Home, 1 = Rides, 2 = Help
  final bool showQuickBookFab;
  final VoidCallback? onQuickBookTap;

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/passenger-home');
        break;
      case 1:
        if (currentIndex == 0) {
          context.push('/ride-history');
        } else {
          context.go('/ride-history');
        }
        break;
      case 2:
        if (currentIndex == 0) {
          context.push('/support');
        } else {
          context.go('/support');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: Row(
          children: [
            // Navigation Pill
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.9)
                        : AppColors.softYellow.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab 0: Home
                      _buildTab(
                        context: context,
                        index: 0,
                        iconWidget: FaIcon(
                          FontAwesomeIcons.house,
                          size: 21,
                          color: currentIndex == 0
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                        label: 'Home',
                        isDark: isDark,
                      ),
                      // Tab 1: Rides
                      _buildTab(
                        context: context,
                        index: 1,
                        iconWidget: FaIcon(
                          FontAwesomeIcons.route,
                          size: 21,
                          color: currentIndex == 1
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                        label: 'Rides',
                        isDark: isDark,
                      ),
                      // Tab 2: Help
                      _buildTab(
                        context: context,
                        index: 2,
                        iconWidget: Icon(
                          Icons.help_outline_rounded,
                          size: 24,
                          color: currentIndex == 2
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                        label: 'Help',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showQuickBookFab) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onQuickBookTap ?? () => context.push('/book-journey'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: Color(0xFF111827),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required int index,
    required Widget iconWidget,
    required String label,
    required bool isDark,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(context, index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            padding: isSelected
                ? const EdgeInsets.symmetric(horizontal: 24, vertical: 5)
                : const EdgeInsets.symmetric(vertical: 5),
            decoration: isSelected
                ? BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.softYellow.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(30),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                SizedBox(height: index == 2 ? 2 : 3),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
