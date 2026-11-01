import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/core/constants/asset_paths.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

class LegalNoticeScreen extends StatelessWidget {
  const LegalNoticeScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.showSuccess(
      context,
      '$label copied to clipboard',
    );
  }

  void _showNavigationMenu(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Navigation',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickMenuItem(
                  context: ctx,
                  icon: Icons.directions_car_rounded,
                  title: 'Book a Luxury Ride',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/passenger-home');
                  },
                ),
                _buildQuickMenuItem(
                  context: ctx,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/privacy-policy');
                  },
                ),
                _buildQuickMenuItem(
                  context: ctx,
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/terms-of-service');
                  },
                ),
                _buildQuickMenuItem(
                  context: ctx,
                  icon: Icons.support_agent_rounded,
                  title: '24/7 Client Support',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/support');
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: cs.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const primaryGold = AppColors.primary;
    final cardBg = isDark ? const Color(0xFF141416) : Colors.white;
    final footerBg = isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF9F8F5);
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Back Button + "Legal notice" title
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.05,
                            ),
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
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Legal notice',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand In-Page Action Banner (Logo + Book Now + Menu)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: subtleBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Logo
                          Image.asset(
                            isDark
                                ? AssetPaths.logoTransparentDark
                                : AssetPaths.logoTransparentLight,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: primaryGold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_car_filled,
                                  size: 15,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () => context.push('/passenger-home'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              foregroundColor: const Color(0xFF111827),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'Book now',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showNavigationMenu(context),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF242428)
                                    : const Color(0xFFF1F1F4),
                                border: Border.all(color: subtleBorder),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.menu_rounded,
                                size: 19,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Headers
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Legal Notice',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                                letterSpacing: -0.5,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Last updated: October 2026',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Registered Entity & Operational Details (Robust Kenick Information)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kenick Transportation LLC\n'
                            '125 W South St\n'
                            'Indianapolis, Indiana 46206\n'
                            'United States',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              height: 1.6,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildContactLine(
                            context: context,
                            label: 'Phone',
                            value: '+1 260-210-3519',
                            onTap: () => _copyToClipboard(
                              context,
                              '+12602103519',
                              'Phone number',
                            ),
                          ),
                          _buildContactLine(
                            context: context,
                            label: 'Booking',
                            value: 'booking@kenicktransportation.com',
                            isLink: true,
                            onTap: () => _copyToClipboard(
                              context,
                              'booking@kenicktransportation.com',
                              'Booking email',
                            ),
                          ),
                          _buildContactLine(
                            context: context,
                            label: 'Legal',
                            value: 'legal@kenicktransportation.com',
                            isLink: true,
                            onTap: () => _copyToClipboard(
                              context,
                              'legal@kenicktransportation.com',
                              'Legal email',
                            ),
                          ),
                          _buildContactLine(
                            context: context,
                            label: 'Website',
                            value: 'https://kenicktransportation.com',
                            isLink: true,
                            onTap: () => _copyToClipboard(
                              context,
                              'https://kenicktransportation.com',
                              'Website URL',
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Entity Type: Limited Liability Company (LLC)\n'
                            'Jurisdiction: State of Indiana, United States\n'
                            'Operating Brand: Kenick VIP / Kenick Transportation\n'
                            'USDOT & Regulatory Compliance: Licensed Luxury Ground Passenger Transportation Provider\n'
                            'Operating Hours: Monday – Friday 6:00 AM – 11:00 PM | Saturday – Sunday 7:00 AM – 10:00 PM (24/7 Advance Reservations)',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              height: 1.6,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Regulatory Oversight & Safety Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Regulatory Standards & Licensing',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Kenick Transportation LLC operates under the regulatory standards established for commercial passenger transportation in the State of Indiana and applicable United States Department of Transportation (USDOT) guidelines.\n\n'
                            'All chauffeurs and partner drivers operating on the Kenick VIP platform undergo extensive criminal history background investigations, continuous motor vehicle record (MVR) screening, and vehicle safety inspections prior to being cleared for client service.',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Zero Tolerance Policy Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zero Tolerance Policy',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kenick Transportation LLC enforces a strict zero-tolerance intoxicating substance and alcohol policy for all chauffeurs providing transportation services through the Kenick platform.\n\n'
                            'Chauffeurs are strictly prohibited from consuming or being under the influence of alcohol, cannabis, narcotics, or any impairing prescription medications before or during their service periods.\n\n'
                            'If you suspect your chauffeur is under the influence of drugs or alcohol, please request to end the trip immediately at the nearest safe location. Once safely out of the vehicle, please dial 911 for emergency assistance.\n\n'
                            'Please report any suspected violations immediately to our 24/7 Client Safety Directorate:\n'
                            '• Hotline: +1 260-210-3519\n'
                            '• Safety Email: booking@kenicktransportation.com',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Non-Discrimination Policy
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Non-Discrimination & Accessibility Statement',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kenick Transportation LLC is committed to providing luxury, dignified ground transportation to all individuals regardless of race, color, national origin, religious belief, sex, sexual orientation, gender identity, marital status, disability, age, or veteran status.\n\n'
                            'Transportation is dispatched solely upon vehicle and chauffeur availability. In compliance with the Americans with Disabilities Act (ADA), certified service animals are welcomed in all Kenick vehicles at no additional charge.',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Intellectual Property & Trademark Disclaimers
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trademarks & Intellectual Property',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The Kenick name, Kenick VIP logo, interface designs, and service names are proprietary trademarks of Kenick Transportation LLC. All other vehicle names (including GMC Yukon, Cadillac Escalade, Ford Expedition) and service provider marks are the trademarks of their respective owners and are referenced solely for vehicle category identification.',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Brand Footer Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: footerBg,
                        border: Border(
                          top: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                isDark
                                    ? AssetPaths.logoTransparentDark
                                    : AssetPaths.logoTransparentLight,
                                height: 32,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: primaryGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions_car_filled,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Kenick VIP',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // App Store & Google Play Badges
                          Row(
                            children: [
                              Expanded(
                                child: _buildStoreBadge(
                                  context: context,
                                  iconWidget: const FaIcon(
                                    FontAwesomeIcons.apple,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  badgeSubtitle: 'Download on the',
                                  badgeTitle: 'App Store',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStoreBadge(
                                  context: context,
                                  iconWidget: const FaIcon(
                                    FontAwesomeIcons.googlePlay,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  badgeSubtitle: 'GET IT ON',
                                  badgeTitle: 'Google Play',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),

                          Text(
                            'Company',
                            style: GoogleFonts.poppins(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFooterLink(context, 'How Kenick works', () {
                            CustomToast.showInfo(
                              context,
                              'Kenick VIP: Luxury SUV & chauffeur transportation across Indiana & the U.S.',
                            );
                          }),
                          _buildFooterLink(context, 'Our Fleet', () {
                            CustomToast.showInfo(
                              context,
                              'GMC Yukon, Cadillac Escalade, Ford Expedition, and Executive Sedans.',
                            );
                          }),
                          _buildFooterLink(context, 'Airport Transfers', () {
                            CustomToast.showInfo(
                              context,
                              'Seamless airport pickup with automated flight tracking & 60 min wait time.',
                            );
                          }),
                          _buildFooterLink(context, 'Contact & Support', () {
                            _copyToClipboard(
                              context,
                              'booking@kenicktransportation.com',
                              'Support email',
                            );
                          }),
                          _buildFooterLink(
                            context,
                            'Become a chauffeur partner',
                            () => context.push('/driver-profile-setup'),
                          ),

                          const SizedBox(height: 32),

                          Text(
                            'Kenick for Business',
                            style: GoogleFonts.poppins(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFooterLink(context, 'Corporate Travel Accounts', () {
                            CustomToast.showInfo(
                              context,
                              'Executive transportation for corporate meetings, events, and VIP clients.',
                            );
                          }),
                          _buildFooterLink(context, 'Hourly & Special Charters', () {
                            CustomToast.showInfo(
                              context,
                              'Flexible hourly charter service with dedicated chauffeur.',
                            );
                          }),
                          _buildFooterLink(context, 'Corporate Inquiries', () {
                            _copyToClipboard(
                              context,
                              'booking@kenicktransportation.com',
                              'Corporate email',
                            );
                          }),

                          const SizedBox(height: 32),
                          Divider(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            '© 2026 Kenick Transportation LLC. All rights reserved.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactLine({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLink = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    const primaryGold = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 85,
              child: Text(
                '$label:',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: isLink ? FontWeight.w600 : FontWeight.w400,
                  color: isLink ? primaryGold : cs.onSurface,
                  decoration: isLink ? TextDecoration.underline : null,
                  decorationColor: isLink ? primaryGold : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreBadge({
    required BuildContext context,
    required Widget iconWidget,
    required String badgeSubtitle,
    required String badgeTitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badgeSubtitle.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  badgeTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
