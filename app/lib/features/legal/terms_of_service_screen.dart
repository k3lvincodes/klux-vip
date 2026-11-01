import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/core/constants/asset_paths.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = List.generate(10, (_) => GlobalKey());

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    if (index >= 0 && index < _sectionKeys.length) {
      final keyContext = _sectionKeys[index].currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.05,
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.showSuccess(context, '$label copied to clipboard');
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
                  icon: Icons.gavel_outlined,
                  title: 'Legal Notice',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/legal-notice');
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
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    final List<String> tableOfContents = [
      'Acceptance of Terms',
      'Booking, Scheduling and Confirmation',
      'Fleet Categories and Vehicle Availability',
      'Airport Transfers, Flight Tracking and Waiting Times',
      'Transparent Pricing, Fares and Payment Terms',
      'Cancellation, Rescheduling and No-Show Policy',
      'Passenger Conduct and Vehicle Care Standards',
      'Service Limitations and Disclaimers of Liability',
      'Dispute Resolution, Binding Arbitration and Class Action Waiver',
      'Governing Law and Legal Notices',
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
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
                    'Terms & conditions',
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
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand In-Page Action Banner
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

                    // Headings
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Terms and Conditions',
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

                    // Table of Contents Section List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: subtleBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < tableOfContents.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: GestureDetector(
                                  onTap: () => _scrollToSection(i),
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: primaryGold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          tableOfContents[i],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w500,
                                            color: cs.onSurface,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Section 1: Acceptance of Terms
                    _buildLegalSection(
                      key: _sectionKeys[0],
                      sectionNumber: '1',
                      title: 'Acceptance of Terms',
                      body:
                          'Welcome to Kenick. These Terms and Conditions ("Terms") constitute a legally binding agreement between you ("User", '
                          '"Passenger", or "Client") and Kenick Transportation LLC ("Kenick", "Kenick VIP", "we", "us", or "our").\n\n'
                          'By accessing or using our mobile application, our website at https://kenicktransportation.com, or reserving our premium '
                          'chauffeur and luxury ground transportation services in the United States, you expressly agree to be bound by these Terms. '
                          'If you do not agree to all provisions, you may not access or use the Kenick platform.',
                    ),

                    // Section 2: Booking, Scheduling & Confirmation
                    _buildLegalSection(
                      key: _sectionKeys[1],
                      sectionNumber: '2',
                      title: 'Booking, Scheduling and Confirmation',
                      body:
                          'Kenick offers both on-demand booking and advanced scheduling up to 30 days prior to your travel date.\n\n'
                          '• Reservation Accuracy: Passengers are responsible for providing correct pickup addresses, destination coordinates, '
                          'flight numbers, and contact telephone numbers.\n'
                          '• Binding Confirmation: A reservation is confirmed when Kenick issues a digital trip confirmation receipt via in-app notification, '
                          'email, or SMS containing your assigned chauffeur details and vehicle class.\n'
                          '• Age Requirement: Passengers creating an account or reserving unchaperoned rides must be at least 18 years of age.',
                    ),

                    // Section 3: Fleet Categories & Vehicle Availability
                    _buildLegalSection(
                      key: _sectionKeys[2],
                      sectionNumber: '3',
                      title: 'Fleet Categories and Vehicle Availability',
                      body:
                          'Our fleet features impeccably maintained, late-model luxury SUVs and executive black cars tailored for comfort, style, '
                          'and peace of mind:\n\n'
                          '• Luxury SUV Fleet: GMC Yukon, Cadillac Escalade, Ford Expedition, and comparable full-size premium SUVs accommodating up to 7 passengers.\n'
                          '• Executive Black Car Fleet: Premium sedans for executive point-to-point and city transfers.\n'
                          '• Vehicle Substitution: While Kenick strives to dispatch the exact vehicle model selected, we reserve the right to '
                          'substitute an equivalent or higher vehicle class at no additional charge to ensure punctuality and uninterrupted service.',
                    ),

                    // Section 4: Airport Transfers, Flight Tracking & Waiting Times
                    _buildLegalSection(
                      key: _sectionKeys[3],
                      sectionNumber: '4',
                      title: 'Airport Transfers, Flight Tracking and Waiting Times',
                      body:
                          '• Automated Flight Tracking: For airport arrivals, Kenick continuously tracks inbound commercial and private flights. '
                          'Pickup times are adjusted dynamically based on actual touchdown telemetry.\n'
                          '• Airport Complimentary Waiting Buffer: To ensure a relaxed arrival, all airport pickups include up to 60 minutes of '
                          'complimentary waiting time from the moment the aircraft arrives at the gate.\n'
                          '• Non-Airport Waiting Buffer: All non-airport, residential, or hotel pickups include 15 minutes of complimentary waiting time.\n'
                          '• Additional Waiting Charges: Waiting time beyond the complimentary period is billed at the standard vehicle category '
                          'hourly rate in 15-minute increments.',
                    ),

                    // Section 5: Transparent Pricing, Fares & Payment Terms
                    _buildLegalSection(
                      key: _sectionKeys[4],
                      sectionNumber: '5',
                      title: 'Transparent Pricing, Fares and Payment Terms',
                      body:
                          '• Upfront Flat-Rate Fares: All fares are quoted upfront in U.S. Dollars (USD) prior to booking confirmation. Quoted rates include '
                          'the base transportation charge, distance, estimated travel time, all highway and bridge tolls, and standard chauffeur gratuity.\n'
                          '• Authorized Payment Methods: Fares are charged to the credit or debit card registered in your account upon trip completion '
                          'or upon late cancellation.\n'
                          '• Incidental Surcharges: Unscheduled intermediate stops requested en route, route detours, or extra waiting time will be '
                          'itemized transparently on the final trip receipt.',
                    ),

                    // Section 6: Cancellation, Rescheduling & No-Show Policy
                    _buildLegalSection(
                      key: _sectionKeys[5],
                      sectionNumber: '6',
                      title: 'Cancellation, Rescheduling and No-Show Policy',
                      body:
                          'To respect our professional chauffeurs\' dedicated schedules and vehicle staging logistics, the following cancellation '
                          'guidelines apply:\n\n'
                          '• Free Cancellation: You may cancel your reservation completely free of charge up to 2 hours before the scheduled pickup time.\n'
                          '• Late Cancellation: Cancellations submitted within 2 hours of scheduled pickup will be charged 50% of the quoted flat ride fare.\n'
                          '• No-Show Policy: If a passenger does not arrive at the designated pickup point within 30 minutes for standard pickups '
                          '(or 60 minutes for airport arrivals) without contacting client support or the chauffeur, the booking is designated as a No-Show '
                          'and charged 100% of the ride fare.',
                    ),

                    // Section 7: Passenger Conduct & Vehicle Care Standards
                    _buildLegalSection(
                      key: _sectionKeys[6],
                      sectionNumber: '7',
                      title: 'Passenger Conduct and Vehicle Care Standards',
                      body:
                          '• Strict Smoke-Free Fleet: Smoking, vaping, electronic cigarettes, and the use of tobacco or cannabis products are strictly '
                          'prohibited inside all Kenick vehicles.\n'
                          '• Safety & Seatbelts: All passengers must wear seatbelts at all times during transit in compliance with state and federal highway regulations.\n'
                          '• Cleaning & Damage Fees: A sanitation fee of up to \$250 may be charged for bodily fluid spills, food stains, or odors requiring '
                          'professional interior detailing. Passengers are liable for any intentional damage caused to vehicle equipment.',
                    ),

                    // Section 8: Service Limitations & Disclaimers of Liability
                    _buildLegalSection(
                      key: _sectionKeys[7],
                      sectionNumber: '8',
                      title: 'Service Limitations and Disclaimers of Liability',
                      body:
                          'Kenick, its members, officers, and chauffeur partners shall not be held liable for indirect, incidental, special, or consequential '
                          'damages resulting from transit delays caused by extreme weather conditions, unexpected road closures, major traffic incidents, '
                          'police directions, or force majeure events beyond our reasonable control.\n\n'
                          'Passengers are advised to schedule airport transfers with adequate buffer time to accommodate unexpected flight boarding windows.',
                    ),

                    // Section 9: Dispute Resolution & Binding Arbitration
                    _buildLegalSection(
                      key: _sectionKeys[8],
                      sectionNumber: '9',
                      title: 'Dispute Resolution, Binding Arbitration and Class Action Waiver',
                      body:
                          'PLEASE READ CAREFULLY. THIS PROVISION AFFECTS YOUR LEGAL RIGHTS.\n\n'
                          'Any controversy, claim, or dispute arising out of or relating to these Terms, the Kenick VIP application, or our transportation '
                          'services shall be resolved through binding individual arbitration administered by the American Arbitration Association (AAA) '
                          'under its Consumer Arbitration Rules in Indianapolis, Indiana.\n\n'
                          'CLASS ACTION WAIVER: YOU AND KENICK AGREE THAT ALL CLAIMS MUST BE BROUGHT IN AN INDIVIDUAL CAPACITY AND NOT AS A PLAINTIFF '
                          'OR CLASS MEMBER IN ANY PURPORTED CLASS, CONSOLIDATED, OR REPRESENTATIVE PROCEEDING.',
                    ),

                    // Section 10: Governing Law & Legal Notices
                    _buildLegalSection(
                      key: _sectionKeys[9],
                      sectionNumber: '10',
                      title: 'Governing Law and Legal Notices',
                      body:
                          'These Terms shall be governed by and construed in accordance with the laws of the State of Indiana and the United States, '
                          'without regard to conflict of laws principles.\n\n'
                          'For questions, corporate account inquiries, or legal notices, please contact us:\n\n'
                          'Kenick Transportation LLC\n'
                          'Attn: Legal & Compliance Directorate\n'
                          '125 W South St\n'
                          'Indianapolis, Indiana 46206\n'
                          'United States\n\n'
                          'Phone: +1 260-210-3519\n'
                          'Email: booking@kenicktransportation.com / legal@kenicktransportation.com',
                      linkAction: () => _copyToClipboard('legal@kenicktransportation.com', 'Legal email'),
                      linkLabel: 'E-Mail: legal@kenicktransportation.com',
                    ),

                    const SizedBox(height: 32),

                    // Brand Footer Section
                    _buildBrandFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection({
    required Key key,
    required String sectionNumber,
    required String title,
    required String body,
    VoidCallback? linkAction,
    String? linkLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    const primaryGold = AppColors.primary;

    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sectionNumber. $title',
            style: GoogleFonts.poppins(
              fontSize: 18.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              height: 1.65,
              color: cs.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (linkAction != null && linkLabel != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: linkAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                linkLabel,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: primaryGold,
                  decoration: TextDecoration.underline,
                  decorationColor: primaryGold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrandFooter(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const primaryGold = AppColors.primary;
    final footerBg = isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF9F8F5);

    return Container(
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

          // App Badges
          Row(
            children: [
              Expanded(
                child: _buildStoreBadge(
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
          _buildFooterLink('How Kenick works', () {
            CustomToast.showInfo(
              context,
              'Kenick VIP: Luxury SUV & chauffeur transportation across Indiana & the U.S.',
            );
          }),
          _buildFooterLink('Our Fleet', () {
            CustomToast.showInfo(
              context,
              'GMC Yukon, Cadillac Escalade, Ford Expedition, and Executive Sedans.',
            );
          }),
          _buildFooterLink('Airport Transfers', () {
            CustomToast.showInfo(
              context,
              'Seamless airport pickup with automated flight tracking & 60 min wait time.',
            );
          }),
          _buildFooterLink('Contact & Support', () {
            _copyToClipboard('booking@kenicktransportation.com', 'Support email');
          }),
          _buildFooterLink(
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
          _buildFooterLink('Corporate Travel Accounts', () {
            CustomToast.showInfo(
              context,
              'Executive transportation for corporate meetings, events, and VIP clients.',
            );
          }),
          _buildFooterLink('Hourly & Special Charters', () {
            CustomToast.showInfo(
              context,
              'Flexible hourly charter service with dedicated chauffeur.',
            );
          }),
          _buildFooterLink('Corporate Inquiries', () {
            _copyToClipboard('booking@kenicktransportation.com', 'Corporate email');
          }),

          const SizedBox(height: 32),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
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
    );
  }

  Widget _buildStoreBadge({
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

  Widget _buildFooterLink(String title, VoidCallback onTap) {
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
