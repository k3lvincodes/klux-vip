import 'package:flutter/material.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class AnimatedInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool isDark;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const AnimatedInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.focusNode,
    this.onTap,
  });

  @override
  State<AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<AnimatedInputField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  bool _hasError = false;
  bool _isSuccess = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  bool get _isFocused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDurations.shake,
    );
    _shakeAnimation = CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void triggerError() {
    _shakeController.forward(from: 0);
    setState(() => _hasError = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hasError = false);
    });
  }

  void triggerSuccess() {
    setState(() => _isSuccess = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSuccess = false);
    });
  }

  Color _getBorderColor() {
    if (_hasError) return Colors.red.shade400;
    if (_isSuccess) return Colors.green;
    if (_isFocused) return AppColors.primary;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            style: TextStyle(
              fontSize: 13,
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
              color: _hasError
                  ? Colors.red.shade400
                  : _isFocused
                      ? AppColors.primary
                      : widget.isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
            ),
            child: Text(widget.label!),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value * 12 - 6, 0),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.easeOutCubic,
            height: widget.maxLines != null && widget.maxLines! > 1
                ? null
                : 50,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AppColors.darkBackground
                  : const Color(0xFFF5F0EF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _getBorderColor(),
                width: _hasError || _isSuccess || _isFocused ? 1.5 : 0,
              ),
              boxShadow: _isSuccess
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : _hasError
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ]
                      : _isFocused
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (_hasError) {
                  setState(() => _hasError = false);
                }
              },
              onTap: widget.onTap,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: widget.isDark
                      ? Colors.grey.shade500
                      : Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                prefixIcon: widget.prefix,
                suffixIcon: _hasError
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.error_outline,
                            size: 18, color: Colors.red),
                      )
                    : _isSuccess
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: Icon(Icons.check_circle_outline,
                                size: 18, color: Colors.green),
                          )
                        : widget.suffix,
                counterText: '',
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
