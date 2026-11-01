import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/features/support/new_chat_sheet.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/navigation/kenick_bottom_nav_bar.dart';

class UrgentSupportScreen extends StatelessWidget {
  const UrgentSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    final subtleDivider = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar: Back button + Title "Call us"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (canPop)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.pop();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    'Call us',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Section Heading: Something urgent?
                    Text(
                      'Something urgent?',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Option 1: Item left in the car?
                    _buildUrgentOption(
                      title: 'Item left in the car?',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '/support/call-numbers',
                          extra: {'topic': 'Item left in the car'},
                        );
                      },
                      isDark: isDark,
                      cs: cs,
                    ),

                    Divider(height: 1, thickness: 1, color: subtleDivider),

                    // Option 2: Cannot locate your chauffeur?
                    _buildUrgentOption(
                      title: 'Cannot locate your chauffeur?',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '/support/call-numbers',
                          extra: {'topic': 'Cannot locate your chauffeur'},
                        );
                      },
                      isDark: isDark,
                      cs: cs,
                    ),

                    const SizedBox(height: 36),

                    // Informational Callout Notice
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 22,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'For all other inquiries, please use our 24/7 in-app chat feature for quicker resolutions. The Kenick VIP Care Team responds in real time to assist you immediately.',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Start chat CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    showNewChatSheet(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 1,
                  ),
                  child: Text(
                    'Start chat',
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation Bar with Help tab active
            const KenickBottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentOption({
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    required ColorScheme cs,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurface,
                  height: 1.3,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
