import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/repositories/support_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.subject,
    required this.status,
  });

  final String ticketId;
  final String subject;
  final String status;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final SupportRepository _supportRepo = SupportRepository();
  final String _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

  List<TicketMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasInputText = false;
  StreamSubscription<List<TicketMessage>>? _subscription;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _loadMessages();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _supportRepo.getMessages(widget.ticketId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    HapticFeedback.lightImpact();
    setState(() => _isSending = true);
    try {
      await _supportRepo.sendMessage(
        ticketId: widget.ticketId,
        senderId: _currentUserId,
        message: text,
      );
      _messageController.clear();
      await _loadMessages();
    } catch (_) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to send message. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final subtleDivider = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    final isClosed = widget.status.toLowerCase() == 'closed';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            border: Border(bottom: BorderSide(color: subtleDivider)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: cs.onSurface,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 4),
                  // Care Agent Badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2026)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.support_agent_rounded,
                        size: 20,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ticket Subject & Status Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Kenick Care Team • ${widget.status.toUpperCase()}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
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
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'No messages yet.',
                            style: GoogleFonts.poppins(
                              color: cs.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.senderId == _currentUserId;
                            return _buildMessageBubble(msg, isMe, isDark, cs);
                          },
                        ),
            ),

            // Bottom Area: Closed Footer or Input Bar
            if (isClosed)
              _buildClosedFooter(isDark, cs)
            else
              _buildInputBar(isDark, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    TicketMessage msg,
    bool isMe,
    bool isDark,
    ColorScheme cs,
  ) {
    final timeStr = DateFormat.jm().format(msg.createdAt);

    if (isMe) {
      // User Message (Right-aligned, black VIP pill)
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2026) : const Color(0xFF121417),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  msg.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  'You • $timeStr',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Care Team Message (Left-aligned, soft rounded grey card)
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262A33) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                msg.message,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Kenick Care Team • $timeStr',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedFooter(bool isDark, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This ticket has been resolved',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/support/chat');
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_comment_outlined,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Start new inquiry',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, ColorScheme cs) {
    final subtleBorder = isDark
        ? const Color(0xFF3F3F46)
        : const Color(0xFFE4E4E7);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Input Field: ONLY bottom border line (no top, right, or left)
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _focusNode.hasFocus
                      ? AppColors.primary
                      : subtleBorder,
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 4),
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Message Care Team...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(height: 8),

          // Toolbar Row: Paperclip, GIF, Mic, Send Button
          Row(
            children: [
              // Attachment Paperclip
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  CustomToast.showInfo(context, 'Attachments coming soon');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
                  child: Icon(
                    Icons.attach_file_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                ),
              ),

              // GIF Badge
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  CustomToast.showInfo(context, 'GIF library coming soon');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'GIF',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

              // Microphone
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  CustomToast.showInfo(context, 'Voice recording coming soon');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                ),
              ),

              const Spacer(),

              // Upward Send Button
              GestureDetector(
                onTap: (_hasInputText && !_isSending) ? _handleSend : null,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _hasInputText
                        ? AppColors.primary
                        : (isDark ? Colors.white12 : const Color(0xFFF3F4F6)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF111827),
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            size: 19,
                            color: _hasInputText
                                ? const Color(0xFF111827)
                                : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
