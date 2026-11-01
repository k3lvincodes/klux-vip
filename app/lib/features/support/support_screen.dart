import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/features/support/new_chat_sheet.dart';
import 'package:kenick_vip/models/support_ticket.dart';
import 'package:kenick_vip/repositories/support_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/navigation/kenick_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final SupportRepository _supportRepo = SupportRepository();
  List<SupportTicket> _tickets = [];

  final List<Map<String, String>> _faqTopics = [
    {
      'question': 'How can I make changes to my booking?',
      'answer':
          'You can modify your pickup address, scheduled time, or vehicle preference directly from the ride details before a chauffeur is dispatched. For modifications within 1 hour of pickup, our 24/7 Care Team can assist you immediately via chat or phone.',
    },
    {
      'question': 'Cancellation policy & how can I cancel?',
      'answer':
          'Complimentary cancellation is available up to 1 hour before scheduled pickup for One-way rides, and up to 24 hours for By-the-hour and Special Event bookings. You can cancel with one tap from the Rides tab.',
    },
    {
      'question': 'Where do I see a ride that was booked for me?',
      'answer':
          'When an executive assistant, travel coordinator, or friend books a ride for you using your phone number or email, it immediately syncs and appears in your "Upcoming" tab in the Rides section.',
    },
    {
      'question': 'Where is my chauffeur?',
      'answer':
          'Once your chauffeur is assigned, you can track their real-time vehicle GPS position, estimated arrival time, and contact details directly on the live map.',
    },
    {
      'question': 'What vehicles does Kenick use?',
      'answer':
          'Kenick VIP operates a handpicked luxury fleet including the GMC Yukon Denali, Cadillac Escalade, Mercedes-Benz S-Class, BMW 7 Series, and executive VIP Sprinters. Every vehicle is thoroughly inspected, sanitized, and chauffeur-driven.',
    },
    {
      'question': 'Explore other help topics',
      'answer':
          'Have questions regarding corporate billing, airport flight tracking, lost property, or child safety seats? Our concierge desk is standing by 24/7.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final tickets = await _supportRepo.getUserTickets(user.id);
        if (mounted) {
          setState(() {
            _tickets = tickets;
          });
        }
      }
    } catch (_) {}
  }

  void _showTopicDetail(String question, String answer) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  answer,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startNewChat(initialSubject: question);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Still need help? Message Care Team',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _startNewChat({String? initialSubject}) {
    showNewChatSheet(
      context,
      initialSubject: initialSubject,
      onTicketCreated: _loadTickets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    final subtleDivider = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final openTicketsCount =
        _tickets.where((t) => t.status.toLowerCase() != 'closed').length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar: Back button (if pushed) + Title "How can we help?"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (canPop)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => context.pop(),
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
                    'How can we help?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Topics and Options
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Care team conversation
                    _buildRowItem(
                      title: 'Care team conversation',
                      trailingBadge: openTicketsCount > 0
                          ? '$openTicketsCount active'
                          : null,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/support/messages');
                      },
                      isDark: isDark,
                      cs: cs,
                    ),

                    Divider(height: 1, thickness: 1, color: subtleDivider),

                    const SizedBox(height: 32),

                    // Section: Explore help topics
                    Text(
                      'Explore help topics',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // FAQ Topics list
                    for (int i = 0; i < _faqTopics.length; i++) ...[
                      _buildRowItem(
                        title: _faqTopics[i]['question']!,
                        onTap: () => _showTopicDetail(
                          _faqTopics[i]['question']!,
                          _faqTopics[i]['answer']!,
                        ),
                        isDark: isDark,
                        cs: cs,
                      ),
                      if (i < _faqTopics.length - 1)
                        Divider(height: 1, color: subtleDivider),
                    ],

                    const SizedBox(height: 32),

                    // Footer notes with "Reach out to our Care Team" button
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Still can't find a solution?",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.push('/support/call');
                            },
                            icon: Icon(
                              Icons.phone_in_talk_rounded,
                              size: 17,
                              color: isDark ? AppColors.primary : cs.onSurface,
                            ),
                            label: Text(
                              'Reach out to our Care Team',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.primary : cs.onSurface,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? AppColors.primary : cs.onSurface,
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : cs.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Floating "Start chat" CTA above bottom nav bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _startNewChat(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 2,
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

            // Floating Bottom Navigation Pill with Circular Car FAB
            const KenickBottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem({
    required String title,
    String? trailingBadge,
    required VoidCallback onTap,
    required bool isDark,
    required ColorScheme cs,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurface,
                  height: 1.35,
                ),
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailingBadge,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
