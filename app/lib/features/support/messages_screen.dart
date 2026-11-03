import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/models/support_ticket.dart';
import 'package:kenick_vip/repositories/support_repository.dart';
import 'package:kenick_vip/services/kenick_ai_service.dart';
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
  List<AiChatMessage> _aiMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final aiMsgs = await KenickAiService.loadMessages();
      final user = Supabase.instance.client.auth.currentUser;
      List<SupportTicket> tickets = [];
      if (user != null) {
        tickets = await _supportRepo.getUserTickets(user.id);
      }
      if (mounted) {
        setState(() {
          _aiMessages = aiMsgs;
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openNewChat() async {
    HapticFeedback.lightImpact();
    await context.push('/support/chat');
    _loadAll();
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
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChat,
        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFF111827),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.edit_outlined,
          color: Colors.white,
          size: 22,
        ),
      ),
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
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          // Kenick AI Agent Conversation Thread (matching Image 3)
                          _buildAiAgentTile(isDark, cs),
                          Divider(height: 1, color: subtleDivider),

                          // Additional Support Tickets (if any)
                          for (final ticket in _tickets) ...[
                            _buildTicketTile(ticket, isDark, cs),
                            Divider(height: 1, color: subtleDivider),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAgentTile(bool isDark, ColorScheme cs) {
    String subtitle = 'How can I help you?';
    if (_aiMessages.isNotEmpty) {
      final lastMsg = _aiMessages.last;
      subtitle = lastMsg.isUser ? 'You: ${lastMsg.text}' : lastMsg.text;
    }

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        await context.push('/support/chat');
        _loadAll();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Dark Avatar
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF111827),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kenick AI agent',
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Just now',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTile(
    SupportTicket ticket,
    bool isDark,
    ColorScheme cs,
  ) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
  }
}
