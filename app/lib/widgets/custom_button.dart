import 'package:flutter/material.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

enum ButtonVariant { primary, secondary, outline }

enum ButtonStatus { normal, loading, success, error }

class CustomButton extends StatefulWidget {
  final String title;
  final VoidCallback onPress;
  final ButtonVariant variant;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final ButtonStatus status;
  final VoidCallback? onStatusComplete;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPress,
    this.variant = ButtonVariant.secondary,
    this.height = 52,
    this.borderRadius = 30,
    this.textStyle,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.status = ButtonStatus.normal,
    this.onStatusComplete,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  void didUpdateWidget(CustomButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (widget.status == ButtonStatus.success ||
          widget.status == ButtonStatus.error) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onStatusComplete?.call();
          }
        });
      }
    }
  }

  bool get _isActive =>
      !widget.isLoading &&
      !widget.isDisabled &&
      widget.status == ButtonStatus.normal;

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.status == ButtonStatus.success) return Colors.green;
    if (widget.status == ButtonStatus.error) return Colors.red.shade500;
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkSurface : Colors.white;
    }
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.status == ButtonStatus.success ||
        widget.status == ButtonStatus.error) {
      return Colors.white;
    }
    switch (widget.variant) {
      case ButtonVariant.primary:
        return Colors.black;
      case ButtonVariant.outline:
        return isDark ? Colors.white : Colors.black;
      case ButtonVariant.secondary:
        return isDark ? Colors.white : Colors.black;
    }
  }

  Widget _buildContent(BuildContext context) {
    if (widget.status == ButtonStatus.success) {
      return const Icon(Icons.check, size: 22, color: Colors.white);
    }
    if (widget.status == ButtonStatus.error) {
      return const Icon(Icons.close, size: 22, color: Colors.white);
    }
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(context)),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: _getTextColor(context)),
          const SizedBox(width: 8),
        ],
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getTextColor(context),
            letterSpacing: 0.3,
          ).merge(widget.textStyle),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed && _isActive ? 0.97 : 1.0,
      duration: AppDurations.press,
      curve: AppCurves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: widget.isDisabled ? 0.5 : 1.0,
        duration: AppDurations.fast,
        curve: AppCurves.easeOut,
        child: AnimatedContainer(
          duration: AppDurations.slow,
          curve: AppCurves.easeOutCubic,
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.variant == ButtonVariant.outline &&
                    widget.status == ButtonStatus.normal
                ? Border.all(
                    color: isDark
                        ? Colors.grey.shade700
                        : AppColors.primary.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
            boxShadow: widget.status == ButtonStatus.normal
                ? widget.variant == ButtonVariant.primary
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ]
                    : widget.variant == ButtonVariant.secondary
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ]
                        : null
                : null,
          ),
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            switchInCurve: AppCurves.easeOutCubic,
            switchOutCurve: AppCurves.easeOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(
                '${widget.isLoading}_${widget.status}_${widget.title}',
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTapDown: _isActive
                      ? (_) => setState(() => _isPressed = true)
                      : null,
                  onTapUp: _isActive
                      ? (_) {
                          setState(() => _isPressed = false);
                          widget.onPress();
                        }
                      : null,
                  onTapCancel: _isActive
                      ? () => setState(() => _isPressed = false)
                      : null,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Center(child: _buildContent(context)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
