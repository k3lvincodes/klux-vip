import 'package:flutter/material.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class PremiumCard extends StatefulWidget {

  const PremiumCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(20),
    this.height,
    this.width,
    this.borderRadius = 16,
    this.color,
    this.borderColor,
    this.onTap,
    this.index = 0,
    this.elevated = true,
  });
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final int index;
  final bool elevated;

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = widget.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return FadeSlideIn(
      delay: Duration(milliseconds: widget.index * 60),
      child: AnimatedScale(
        scale: widget.onTap != null && _isPressed ? 0.98 : 1.0,
        duration: AppDurations.press,
        curve: AppCurves.easeOutCubic,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.easeOutCubic,
          margin: widget.margin,
          padding: !_isPressed ? widget.padding : EdgeInsets.zero,
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: widget.elevated
                ? _isPressed
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: widget.onTap != null
                  ? (_) => setState(() => _isPressed = true)
                  : null,
              onTapUp: widget.onTap != null
                  ? (_) {
                      setState(() => _isPressed = false);
                      widget.onTap!.call();
                    }
                  : null,
              onTapCancel: widget.onTap != null
                  ? () => setState(() => _isPressed = false)
                  : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
