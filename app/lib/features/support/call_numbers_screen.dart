import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/features/support/new_chat_sheet.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/navigation/kenick_bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CallNumbersScreen extends StatelessWidget {
  const CallNumbersScreen({super.key});

  static const List<Map<String, String>> _supportChannels = [
    {
      'label': 'US (Direct)',
      'number': '+1 260-210-3519',
      'rawNumber': '+12602103519',
      'type': 'phone',
    },
    {
      'label': 'Dispatch',
      'number': '+1 260-210-3519',
      'rawNumber': '+12602103519',
      'type': 'phone',
    },
    {
      'label': 'Lost & Found',
      'number': '+1 260-210-3519',
      'rawNumber': '+12602103519',
      'type': 'phone',
    },
    {
      'label': 'Concierge',
      'number': '+1 260-210-3519',
      'rawNumber': '+12602103519',
      'type': 'phone',
    },
    {
      'label': 'Email Desk',
      'number': 'booking@kenicktransportation.com',
      'rawNumber': 'mailto:booking@kenicktransportation.com',
      'type': 'email',
    },
  ];

  Future<void> _handleChannelTap(
    BuildContext context,
    String rawTarget,
    String display,
    String type,
  ) async {
    HapticFeedback.lightImpact();
    final Uri launchUri = type == 'email'
        ? Uri.parse(rawTarget)
        : Uri(scheme: 'tel', path: rawTarget);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        await Clipboard.setData(ClipboardData(text: display));
        if (context.mounted) {
          CustomToast.showSuccess(
            context,
            'Copied $display to clipboard',
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: display));
      if (context.mounted) {
        CustomToast.showSuccess(
          context,
          'Copied $display to clipboard',
        );
      }
    }
  }

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

            // Scrollable Phone Numbers List & Notices
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Kenick Dedicated Contact Channels
                    for (int i = 0; i < _supportChannels.length; i++) ...[
                      InkWell(
                        onTap: () => _handleChannelTap(
                          context,
                          _supportChannels[i]['rawNumber']!,
                          _supportChannels[i]['number']!,
                          _supportChannels[i]['type']!,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 104,
                                child: Text(
                                  _supportChannels[i]['label']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _supportChannels[i]['number']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w400,
                                    color: cs.onSurface.withValues(alpha: 0.85),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _supportChannels[i]['type'] == 'email'
                                    ? Icons.mail_outline_rounded
                                    : Icons.phone_outlined,
                                size: 21,
                                color: cs.onSurface,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < _supportChannels.length - 1)
                        Divider(height: 1, thickness: 1, color: subtleDivider),
                    ],

                    const SizedBox(height: 32),

                    // Information Notice 1: Chat Resolution
                    _buildNotice(
                      icon: Icons.info_outline_rounded,
                      text:
                          'Did you know you can quickly resolve your issues through our in-app chat? Our Kenick VIP concierge responds within minutes.',
                      cs: cs,
                    ),

                    const SizedBox(height: 18),

                    // Information Notice 2: Kenick Operating Hours
                    _buildNotice(
                      icon: Icons.info_outline_rounded,
                      text:
                          'Kenick VIP Concierge Desk (Indianapolis, IN):\n'
                          'Monday – Friday 6:00 AM – 11:00 PM EST\n'
                          'Saturday – Sunday 7:00 AM – 10:00 PM EST\n'
                          'All scheduled rides and advance reservations are monitored 24/7.',
                      cs: cs,
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

  Widget _buildNotice({
    required IconData icon,
    required String text,
    required ColorScheme cs,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
