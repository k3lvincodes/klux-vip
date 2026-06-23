import 'package:flutter/material.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class AnimatedListItem extends StatefulWidget {

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.padding,
    this.borderRadius = 16,
    this.color,
    this.onTap,
    this.dismissDirection,
    this.onDismissed,
    this.secondaryBackground,
    this.primaryBackground,
  });
  final Widget child;
  final int index;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final DismissDirection? dismissDirection;
  final VoidCallback? onDismissed;
  final Widget? secondaryBackground;
  final Widget? primaryBackground;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        widget.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    Widget item = Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: AppDurations.press,
        curve: AppCurves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.dismissDirection != null) {
      item = Dismissible(
        key: ValueKey('list_item_${widget.index}'),
        direction: widget.dismissDirection!,
        onDismissed: (_) => widget.onDismissed?.call(),
        background: widget.primaryBackground,
        secondaryBackground: widget.secondaryBackground,
        dismissThresholds: const {DismissDirection.endToStart: 0.4},
        child: item,
      );
    }

    return FadeSlideIn(
      delay: Duration(milliseconds: widget.index * 60),
      child: item,
    );
  }
}
