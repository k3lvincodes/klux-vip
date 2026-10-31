import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

class OffersRewardsScreen extends StatefulWidget {
  const OffersRewardsScreen({super.key});

  @override
  State<OffersRewardsScreen> createState() => _OffersRewardsScreenState();
}

class _OffersRewardsScreenState extends State<OffersRewardsScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _redeemPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      CustomToast.showError(context, 'Please enter a voucher or promo code');
      return;
    }

    setState(() => _isRedeeming = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isRedeeming = false);

    CustomToast.showSuccess(context, 'Offer code "$code" applied!');
    _promoController.clear();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        border: Border.all(color: subtleBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Offers & rewards',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content: Faithfully matches reference empty state
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (mounted) setState(() {});
                },
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 120),

                        // Discount Tag Graphic (reproduced with smooth luxury gradients)
                        _buildDiscountTagGraphic(isDark),

                        const SizedBox(height: 36),

                        // Title: "No offers available" (Restrained boldness)
                        Text(
                          'No offers available',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle: "There are no offers available in your account at this time."
                        Text(
                          'There are no offers available in your\naccount at this time.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // VIP Promo Code Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: subtleBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Have an exclusive voucher?',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF141416) : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: cs.outlineVariant.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: TextField(
                                        controller: _promoController,
                                        textCapitalization: TextCapitalization.characters,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Enter promo code',
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          isDense: true,
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: _isRedeeming ? null : _redeemPromo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: const Color(0xFF111827),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      child: _isRedeeming
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF111827),
                                              ),
                                            )
                                          : Text(
                                              'Apply',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildDiscountTagGraphic(bool isDark) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Back angled tag (darker blue / subtle gold accent)
            Transform.translate(
              offset: const Offset(16, -6),
              child: Transform.rotate(
                angle: 0.35,
                child: Container(
                  width: 68,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5BB8),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E5BB8).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Front primary tag with glassmorphic shine and '%' symbol
            Transform.translate(
              offset: const Offset(-8, 4),
              child: Transform.rotate(
                angle: -0.15,
                child: Container(
                  width: 72,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8DC5FE),
                        Color(0xFF5BA4FB),
                        Color(0xFF388CF7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF388CF7).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Tag perforation hole
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F0F11) : const Color(0xFFF6F6F8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      // '%' glyph
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '%',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
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
