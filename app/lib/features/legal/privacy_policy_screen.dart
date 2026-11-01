import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/core/constants/asset_paths.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    final List<String> tableOfContents = [
      'Scope and Overview',
      'Information We Collect',
      'How We Use Your Information',
      'Location Tracking and Mobile Device Permissions',
      'Information Sharing and Chauffeur Dispatch',
      'Payment Security and Fraud Protection',
      'Data Security and Storage',
      'Your Privacy Rights and Choices',
      'Children\'s Privacy',
      'Contact Information & Data Requests',
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
                    'Privacy policy',
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

            // Scrollable Body
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
                              'Privacy Policy',
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

                    // Section 1: Scope and Overview
                    _buildLegalSection(
                      key: _sectionKeys[0],
                      sectionNumber: '1',
                      title: 'Scope and Overview',
                      body:
                          'At Kenick Transportation LLC ("Kenick", "Kenick VIP", "we", "us", or "our"), we are dedicated to protecting '
                          'your personal privacy and maintaining the highest confidentiality for our discerning passengers. This Privacy Policy '
                          'explains how we collect, use, process, and protect your information when you access our mobile applications, '
                          'visit our website at https://kenicktransportation.com, or utilize our luxury chauffeur and executive SUV services '
                          'across the United States.\n\n'
                          'By accessing or using the Kenick platform, you acknowledge that you have read and understood this Privacy Policy.',
                    ),

                    // Section 2: Information We Collect
                    _buildLegalSection(
                      key: _sectionKeys[1],
                      sectionNumber: '2',
                      title: 'Information We Collect',
                      body:
                          'We collect personal information that you provide directly to us when creating an account, reserving a vehicle, '
                          'or communicating with client support. This includes:\n\n'
                          '• Contact Identifiers: Full legal name, mobile phone number, email address, and billing address.\n'
                          '• Reservation Details: Origin pickup address, destination drop-off location, flight numbers for airport pickups, '
                          'date and scheduled time, vehicle category selection, and custom ride notes.\n'
                          '• Payment Credentials: Card tokenization data, cardholder name, and transaction history. Credit card details are '
                          'handled exclusively through encrypted, PCI-DSS Level 1 certified payment processors (e.g., Stripe) and are never stored '
                          'in plain text on Kenick servers.\n'
                          '• Technical & Device Telemetry: IP address, operating system, unique device identifiers, and mobile app performance metrics.',
                    ),

                    // Section 3: How We Use Your Information
                    _buildLegalSection(
                      key: _sectionKeys[2],
                      sectionNumber: '3',
                      title: 'How We Use Your Information',
                      body:
                          'Kenick uses your personal information exclusively to deliver a first-class, reliable luxury ride experience, including:\n\n'
                          '• Facilitating seamless online booking, vehicle dispatch, and chauffeur assignment.\n'
                          '• Tracking flights in real-time to adjust airport pickup times automatically and provide complimentary waiting buffers.\n'
                          '• Transmitting live status alerts (e.g., chauffeur arrival, vehicle details, live ETA) via push notifications or SMS.\n'
                          '• Generating accurate trip invoices, processing payments, and enforcing transparent flat-rate pricing.\n'
                          '• Preventing unauthorized account activity and screening transactions against fraudulent chargebacks.\n'
                          '• Providing responsive, personalized 24/7 client care and handling service inquiries.',
                    ),

                    // Section 4: Location Tracking & Device Permissions
                    _buildLegalSection(
                      key: _sectionKeys[3],
                      sectionNumber: '4',
                      title: 'Location Tracking and Mobile Device Permissions',
                      body:
                          'To enable precise chauffeur dispatch and curbside meet-and-greet services, the Kenick VIP application requests access '
                          'to your mobile device location while the app is active:\n\n'
                          '• Precise Pickup Coordinates: Pinpoints your exact physical location to ensure your chauffeur arrives at the correct '
                          'terminal, private residence, or hotel entrance without unnecessary delay.\n'
                          '• Real-Time Navigation & ETA: Calculates accurate transit times and provides real-time route telemetry.\n'
                          '• User Controls: You can enable, disable, or adjust location permissions at any time through your mobile device\'s '
                          'system settings. If location services are disabled, you may still reserve rides by manually entering pickup addresses.',
                    ),

                    // Section 5: Information Sharing & Chauffeur Dispatch
                    _buildLegalSection(
                      key: _sectionKeys[4],
                      sectionNumber: '5',
                      title: 'Information Sharing and Chauffeur Dispatch',
                      body:
                          'Kenick Transportation LLC does not sell, rent, or trade your personal information to third-party data brokers or '
                          'unaffiliated marketers.\n\n'
                          'We only share limited, essential trip details with:\n'
                          '• Assigned Chauffeurs: Your assigned chauffeur receives solely the passenger first name, pickup location, drop-off '
                          'destination, flight number, and specific itinerary notes required to execute your trip safely and professionally.\n'
                          '• Essential Service Partners: Trusted technology providers (such as Google Maps API, cloud infrastructure, and '
                          'SMS notification relays) operating under strict non-disclosure and data protection agreements.\n'
                          '• Legal Compliance: In rare circumstances where disclosure is required by law, court order, or governmental transport '
                          'regulators to protect safety or investigate legal violations.',
                    ),

                    // Section 6: Payment Security & Fraud Protection
                    _buildLegalSection(
                      key: _sectionKeys[5],
                      sectionNumber: '6',
                      title: 'Payment Security and Fraud Protection',
                      body:
                          'All card transactions processed through Kenick are secured by end-to-end TLS 1.3 cryptographic encryption and '
                          'processed through PCI-DSS Level 1 certified payment vaults.\n\n'
                          'We do not retain full payment card numbers, CVV verification numbers, or banking PINs. Payment tokens are securely managed '
                          'to allow easy one-tap checkout for repeat bookings while maintaining absolute financial security.',
                    ),

                    // Section 7: Data Security and Storage
                    _buildLegalSection(
                      key: _sectionKeys[6],
                      sectionNumber: '7',
                      title: 'Data Security and Storage',
                      body:
                          'We implement robust administrative, technical, and physical safeguards designed to protect personal data from accidental '
                          'loss, unauthorized access, destruction, or disclosure.\n\n'
                          'All account data is stored in enterprise-grade cloud datacenters located in the United States, safeguarded by role-based '
                          'access restrictions and continuous security auditing.',
                    ),

                    // Section 8: Your Privacy Rights and Choices
                    _buildLegalSection(
                      key: _sectionKeys[7],
                      sectionNumber: '8',
                      title: 'Your Privacy Rights and Choices',
                      body:
                          'As a Kenick passenger, you have direct control over your personal data:\n\n'
                          '• Access & Correction: You may review and update your name, email, phone number, and saved addresses directly in your '
                          'Kenick VIP Account Profile.\n'
                          '• Account Deletion: You can request the complete deletion of your user account and associated personal data at any time '
                          'via the Settings screen or by contacting our Privacy Desk.\n'
                          '• Marketing Preferences: You may opt out of promotional emails or text messages at any time using the unsubscribe link '
                          'or by replying STOP to SMS notifications (essential transactional ride receipts will continue to be delivered).\n'
                          '• US State Rights (including California CCPA/CPRA): Residents have the right to request disclosure of personal data '
                          'categories collected, request deletion, and opt-out of data sharing. We do not sell passenger personal data.',
                    ),

                    // Section 9: Children's Privacy
                    _buildLegalSection(
                      key: _sectionKeys[8],
                      sectionNumber: '9',
                      title: 'Children\'s Privacy',
                      body:
                          'Kenick Transportation LLC services are exclusively intended for adults aged 18 and older. We do not knowingly collect '
                          'personal information from children under 13. If you believe a minor has provided us with personal data, please contact '
                          'us immediately so we can promptly delete such records.',
                    ),

                    // Section 10: Contact Information & Data Requests
                    _buildLegalSection(
                      key: _sectionKeys[9],
                      sectionNumber: '10',
                      title: 'Contact Information & Data Requests',
                      body:
                          'If you have any questions, inquiries, or requests regarding this Privacy Policy or our data protection practices, '
                          'please contact our Privacy & Compliance Team:\n\n'
                          'Kenick Transportation LLC\n'
                          'Attn: Privacy Officer\n'
                          '125 W South St\n'
                          'Indianapolis, Indiana 46206\n'
                          'United States\n\n'
                          'Phone: +1 260-210-3519\n'
                          'Email: booking@kenicktransportation.com / legal@kenicktransportation.com',
                      linkAction: () => _copyToClipboard('booking@kenicktransportation.com', 'Privacy email'),
                      linkLabel: 'E-Mail: booking@kenicktransportation.com',
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
