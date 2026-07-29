import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';

class TipSelectionScreen extends StatefulWidget {
  const TipSelectionScreen({super.key});

  @override
  State<TipSelectionScreen> createState() => _TipSelectionScreenState();
}

class _TipSelectionScreenState extends State<TipSelectionScreen> {
  double _selectedTip = 0.0;
  bool _isCustomTip = false;
  bool _isNoTip = false;
  final TextEditingController _customTipController = TextEditingController();
  final FocusNode _customTipFocusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extras = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _fareAmount = extras?['fareAmount'] as double? ?? 0.0;
  }

  double _fareAmount = 0.0;

  @override
  void dispose() {
    _customTipController.dispose();
    _customTipFocusNode.dispose();
    super.dispose();
  }

  double get _totalAmount => _fareAmount + _selectedTip;

  void _selectTip(double tip) {
    setState(() {
      _selectedTip = tip;
      _isCustomTip = false;
      _isNoTip = false;
      _customTipController.clear();
    });
  }

  void _selectNoTip() {
    setState(() {
      _selectedTip = 0.0;
      _isCustomTip = false;
      _isNoTip = true;
      _customTipController.clear();
    });
  }

  void _selectCustomTip() {
    setState(() {
      _isCustomTip = true;
      _isNoTip = false;
    });
    _customTipFocusNode.requestFocus();
  }

  void _onCustomTipChanged(String value) {
    final parsed = double.tryParse(value) ?? 0.0;
    setState(() {
      _selectedTip = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add a Tip',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Fare summary card
                      FadeSlideIn(
                        child: _buildFareSummaryCard(isDark),
                      ),
                      const SizedBox(height: 32),

                      // Section label
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: Text(
                          'Select a tip for your driver',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tip chips
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: Row(
                          children: [
                            _buildTipChip(
                              label: '20%',
                              tip: _fareAmount * 0.20,
                              isSelected: _selectedTip == _fareAmount * 0.20 && !_isCustomTip && !_isNoTip,
                              isDark: isDark,
                              onTap: () => _selectTip(_fareAmount * 0.20),
                            ),
                            const SizedBox(width: 12),
                            _buildTipChip(
                              label: '25%',
                              tip: _fareAmount * 0.25,
                              isSelected: _selectedTip == _fareAmount * 0.25 && !_isCustomTip && !_isNoTip,
                              isDark: isDark,
                              onTap: () => _selectTip(_fareAmount * 0.25),
                            ),
                            const SizedBox(width: 12),
                            _buildTipChip(
                              label: '30%',
                              tip: _fareAmount * 0.30,
                              isSelected: _selectedTip == _fareAmount * 0.30 && !_isCustomTip && !_isNoTip,
                              isDark: isDark,
                              onTap: () => _selectTip(_fareAmount * 0.30),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custom tip
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: _buildCustomTipOption(isDark),
                      ),
                      const SizedBox(height: 12),

                      // No tip
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: _buildNoTipOption(isDark),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section: total + continue button
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTotalDisplay(isDark),
                    const SizedBox(height: 16),
                    CustomButton(
                      title: 'Continue to Payment',
                      variant: ButtonVariant.primary,
                      onPress: () {
                        context.push(
                          '/booking-payment',
                          extra: {
                            'fareAmount': _fareAmount,
                            'tipAmount': _selectedTip,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareSummaryCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFareRow(
            label: 'Base fare',
            value: _fareAmount,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildFareRow(
            label: 'Distance fare',
            value: 0.0,
            isDark: isDark,
            suffix: 'Included',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.primary),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              Text(
                '\$${_fareAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow({
    required String label,
    required double value,
    required bool isDark,
    String? suffix,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.7)
                : AppColors.black.withValues(alpha: 0.6),
          ),
        ),
        if (suffix != null)
          Text(
            suffix,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.5)
                  : AppColors.black.withValues(alpha: 0.4),
            ),
          )
        else
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.7)
                  : AppColors.black.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildTipChip({
    required String label,
    required double tip,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkSurface : AppColors.secondary),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.black
                      : (isDark ? AppColors.white : AppColors.black),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${tip.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.7)
                      : (isDark
                          ? AppColors.white.withValues(alpha: 0.5)
                          : AppColors.black.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipOption(bool isDark) {
    return PressScale(
      onTap: _selectCustomTip,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isCustomTip
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.secondary),
          borderRadius: BorderRadius.circular(12),
          border: _isCustomTip
              ? Border.all(color: AppColors.primary)
              : Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: _isCustomTip
                  ? AppColors.primary
                  : (isDark ? AppColors.white : AppColors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isCustomTip
                  ? _buildCustomTipInput(isDark)
                  : Text(
                      'Custom amount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
            ),
            if (_isCustomTip)
              const Text(
                '\$',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTipInput(bool isDark) {
    return TextField(
      controller: _customTipController,
      focusNode: _customTipFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: _onCustomTipChanged,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.white : AppColors.black,
      ),
      decoration: InputDecoration(
        hintText: 'Enter amount',
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark
              ? AppColors.white.withValues(alpha: 0.3)
              : AppColors.black.withValues(alpha: 0.3),
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNoTipOption(bool isDark) {
    return PressScale(
      onTap: _selectNoTip,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isNoTip
              ? AppColors.darkSurface.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkSurface : AppColors.secondary),
          borderRadius: BorderRadius.circular(12),
          border: _isNoTip
              ? Border.all(
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                )
              : Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.money_off_rounded,
              size: 18,
              color: _isNoTip
                  ? (isDark ? AppColors.white.withValues(alpha: 0.7) : AppColors.black.withValues(alpha: 0.7))
                  : (isDark ? AppColors.white : AppColors.black),
            ),
            const SizedBox(width: 12),
            Text(
              'No tip',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDisplay(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        Text(
          '\$${_totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
