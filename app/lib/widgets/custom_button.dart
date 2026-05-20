import 'package:flutter/material.dart';
import 'package:kenick_vip/theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline }

class CustomButton extends StatefulWidget {
  final String title;
  final VoidCallback onPress;
  final ButtonVariant variant;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isLoading;

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
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkSurface : AppColors.white;
    }
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.black;
      case ButtonVariant.outline:
        return isDark ? AppColors.white : AppColors.black;
      case ButtonVariant.secondary:
        return isDark ? AppColors.white : AppColors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedScale(
      scale: _isPressed && !widget.isLoading ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.variant == ButtonVariant.outline
              ? Border.all(color: isDark ? Colors.grey.shade700 : AppColors.primary.withValues(alpha: 0.5), width: 1)
              : null,
          boxShadow: widget.variant == ButtonVariant.primary
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
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              if (!widget.isLoading) widget.onPress();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(context)),
                      ),
                    )
                  : Row(
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
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
