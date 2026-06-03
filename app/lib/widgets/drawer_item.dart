import 'package:flutter/material.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class DrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;
  final bool isDestructive;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
    this.isDestructive = false,
  });

  @override
  State<DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<DrawerItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  Color get _iconBgColor {
    if (widget.isDestructive) return Colors.red.withValues(alpha: 0.1);
    if (widget.isActive) return AppColors.primary.withValues(alpha: 0.15);
    return widget.isDark ? Colors.grey.shade800 : Colors.grey.shade100;
  }

  Color get _iconColor {
    if (widget.isDestructive) return Colors.red;
    if (widget.isActive) return AppColors.primary;
    return widget.isDark ? Colors.white : Colors.black;
  }

  Color get _textColor {
    if (widget.isDestructive) return Colors.red;
    if (widget.isActive) return AppColors.primary;
    return widget.isDark ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: AppDurations.press,
        curve: AppCurves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: AppCurves.easeOut,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedSwitcher(
                      duration: AppDurations.fast,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        widget.icon,
                        key: ValueKey('${widget.icon.hashCode}_${widget.isActive}'),
                        color: _iconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                  ),
                  if (widget.isActive)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
