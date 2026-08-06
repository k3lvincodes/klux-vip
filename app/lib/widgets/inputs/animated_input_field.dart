import 'package:flutter/material.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class AnimatedInputField extends StatefulWidget {

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final borderColor = _hasError
        ? cs.error
        : _isSuccess
            ? cs.primary
            : _isFocused
                ? cs.primary
                : cs.outline;

    final labelColor = _hasError
        ? cs.error
        : _isFocused
            ? cs.primary
            : cs.onSurfaceVariant;

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
              color: labelColor,
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
            height: widget.maxLines != null && widget.maxLines! > 1 ? null : 50,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: _hasError || _isSuccess || _isFocused ? 1.5 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.12),
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
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                prefixIcon: widget.prefix,
                suffixIcon: _hasError
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(Icons.error_outline,
                            size: 18, color: cs.error),
                      )
                    : _isSuccess
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(Icons.check_circle_outline,
                                size: 18, color: cs.primary),
                          )
                        : widget.suffix,
                counterText: '',
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
