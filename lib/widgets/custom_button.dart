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

  const CustomButton({
    super.key,
    required this.title,
    required this.onPress,
    this.variant = ButtonVariant.secondary,
    this.height = 50,
    this.borderRadius = 12,
    this.textStyle,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(borderRadius),
        border: variant == ButtonVariant.outline
            ? Border.all(color: AppColors.black, width: 1)
            : null,
        boxShadow: variant != ButtonVariant.outline
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 3.84,
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ).merge(textStyle),
            ),
          ),
        ),
      ),
    );
  }
}
