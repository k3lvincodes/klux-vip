import 'package:flutter/material.dart';
import 'package:klux_vip/theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline }

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPress;
  final ButtonVariant variant;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPress,
    this.variant = ButtonVariant.secondary,
    this.height = 52,
    this.borderRadius = 30,
    this.textStyle,
    this.icon,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.secondary:
        return AppColors.white;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.black;
      case ButtonVariant.outline:
        return AppColors.black;
      case ButtonVariant.secondary:
        return AppColors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(borderRadius),
        border: variant == ButtonVariant.outline
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
            : null,
        boxShadow: variant == ButtonVariant.primary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : variant == ButtonVariant.secondary
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
          onTap: onPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: _getTextColor()),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(),
                    letterSpacing: 0.3,
                  ).merge(textStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
