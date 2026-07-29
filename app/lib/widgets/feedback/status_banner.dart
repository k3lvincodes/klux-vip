import 'package:flutter/material.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class StatusBanner extends StatefulWidget {

  const StatusBanner({
    super.key,
    required this.isActive,
    this.activeText = 'Chauffeur found!',
    this.inactiveText = 'Searching for chauffeur...',
    this.activeColor,
    this.inactiveColor,
    this.showBorder = true,
  });
  final bool isActive;
  final String activeText;
  final String inactiveText;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBorder;

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isActive
        ? (widget.activeColor ?? Colors.green[50]!)
        : (widget.inactiveColor ?? Colors.white);
    final textColor = widget.isActive ? Colors.green[800]! : Colors.black;
    final borderColor = widget.isActive ? Colors.green : null;

    return FadeSlideIn(
      delay: const Duration(milliseconds: 100),
      slideOffset: -0.02,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppCurves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: widget.showBorder && borderColor != null
              ? Border.all(color: borderColor)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                widget.isActive ? Icons.check_circle : Icons.hourglass_empty,
                key: ValueKey(widget.isActive),
                size: 16,
                color: widget.isActive ? Colors.green[700] : AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              child: Text(
                widget.isActive ? widget.activeText : widget.inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
