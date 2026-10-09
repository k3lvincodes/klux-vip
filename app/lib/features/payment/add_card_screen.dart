import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _detectCardBrand(String number) {
    final cleaned = number.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('4')) return 'Visa';
    if (cleaned.startsWith(RegExp(r'5[1-5]'))) return 'Mastercard';
    if (cleaned.startsWith(RegExp(r'3[47]'))) return 'Amex';
    return 'Card';
  }

  Future<void> _saveCard() async {
    final name = _nameController.text.trim();
    final number = _numberController.text.trim().replaceAll(' ', '');
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();

    if (name.isEmpty || number.length < 12 || expiry.isEmpty || cvv.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all card details correctly',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.darkSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('saved_user_cards');
      List<dynamic> cardsList = [];
      if (existingJson != null) {
        try {
          cardsList = jsonDecode(existingJson) as List<dynamic>;
        } catch (_) {}
      }

      final last4 = number.length >= 4 ? number.substring(number.length - 4) : number;
      final brand = _detectCardBrand(number);

      final newCard = {
        'id': 'card_${DateTime.now().millisecondsSinceEpoch}',
        'holder': name,
        'brand': brand,
        'last4': last4,
        'expiry': expiry,
        'created_at': DateTime.now().toIso8601String(),
      };

      cardsList.insert(0, newCard);
      await prefs.setString('saved_user_cards', jsonEncode(cardsList));

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Card added successfully',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.darkSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credit or debit card',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // 1. Name on card
                    Text(
                      'Name on card',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Cardholder',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                        isDense: true,
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 2. Card number
                    Text(
                      'Card number',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberFormatter(),
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: '0102 0304 0506 0708',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                        isDense: true,
                        suffixIcon: Icon(
                          Icons.credit_card_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 3. Expiry date
                    Text(
                      'Expiry date',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateFormatter(),
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'MM/YY',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                        isDense: true,
                        suffixIcon: Icon(
                          Icons.calendar_month_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 4. Security code (CVV)
                    Text(
                      'Security code (CVV)',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: '123',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                        isDense: true,
                        suffixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Disclosures
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.credit_card_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Our servers are encrypted with TLS/SSL to ensure security and privacy.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'The amount will be held on your selected payment method after booking. You only charged once your journey is complete.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            // Bottom Add card button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFBDBDBD),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Add card',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
