import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/features/support/new_chat_sheet.dart';
import 'package:kenick_vip/models/support_ticket.dart';
import 'package:kenick_vip/repositories/support_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupportRepository _supportRepo = SupportRepository();
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;

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
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openNewChat() {
    HapticFeedback.lightImpact();
    showNewChatSheet(
      context,
      onTicketCreated: () => _loadTickets(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final subtleDivider = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Close "X" + Title "Messages"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 26,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Messages',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: subtleDivider),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : _tickets.isEmpty
                      ? _buildEmptyState(isDark: isDark, cs: cs)
                      : _buildTicketsList(isDark: isDark, cs: cs, divider: subtleDivider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isDark, required ColorScheme cs}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chat bubble icon with horizontal conversation lines
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2026) : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(26, 26),
                  painter: _ChatIconPainter(
                    bubbleColor: isDark ? Colors.white : Colors.white,
                    lineColor: isDark ? const Color(0xFF1E2026) : const Color(0xFF18181B),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title: No messages
            Text(
              'No messages',
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle: Messages from the team will be shown here
            Text(
              'Messages from the team will be shown\nhere',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Button: Ask a question >
            InkWell(
              onTap: _openNewChat,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2026) : const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask a question',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.white,
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

  Widget _buildTicketsList({
    required bool isDark,
    required ColorScheme cs,
    required Color divider,
  }) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTickets,
            color: AppColors.primary,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _tickets.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: divider),
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                final isOpen = ticket.status.toLowerCase() != 'closed';
                final dateStr = DateFormat.MMMd().format(ticket.createdAt);

                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(
                      '/support/ticket/${ticket.id}',
                      extra: {
                        'subject': ticket.subject,
                        'status': ticket.status,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indicator dot for open tickets
                        Container(
                          margin: const EdgeInsets.only(top: 6, right: 12),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOpen ? AppColors.primary : Colors.grey.shade600,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.subject,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    ticket.status.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOpen
                                          ? AppColors.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  $dateStr',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Bottom CTA: Ask another question
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openNewChat,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Ask a question',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF111827),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the luxury chat bubble icon with two message lines
class _ChatIconPainter extends CustomPainter {
  const _ChatIconPainter({
    required this.bubbleColor,
    required this.lineColor,
  });

  final Color bubbleColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()..color = bubbleColor;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw chat bubble
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 8),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, bubblePaint);

    // Draw little speech tail
    final tailPath = Path()
      ..moveTo(size.width * 0.35, size.height - 6)
      ..lineTo(size.width * 0.25, size.height - 1)
      ..lineTo(size.width * 0.5, size.height - 6)
      ..close();
    canvas.drawPath(tailPath, bubblePaint);

    // Draw 2 inner horizontal lines
    final line1Y = size.height * 0.35;
    final line2Y = size.height * 0.55;
    canvas.drawLine(
      Offset(size.width * 0.25, line1Y),
      Offset(size.width * 0.75, line1Y),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, line2Y),
      Offset(size.width * 0.60, line2Y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
