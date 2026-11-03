import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/services/kenick_ai_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

class KenickAiChatScreen extends StatefulWidget {
  const KenickAiChatScreen({super.key});

  @override
  State<KenickAiChatScreen> createState() => _KenickAiChatScreenState();
}

class _KenickAiChatScreenState extends State<KenickAiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<AiChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isEnded = false;
  bool _hasInputText = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _initChat();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final loaded = await KenickAiService.loadMessages();
    final ended = await KenickAiService.isConversationEnded();
    if (mounted) {
      setState(() {
        _messages = loaded;
        _isEnded = ended;
        _isLoading = false;
      });
      _scrollToBottom(immediate: true);
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isTyping || _isEnded) return;

    HapticFeedback.lightImpact();
    _inputController.clear();

    final userMessage = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    // Check if termination intent
    final willEnd = KenickAiService.isTerminationIntent(text);

    // Persist user message
    await KenickAiService.saveMessages(_messages);

    // Artificial realistic concierge typing delay
    await Future.delayed(const Duration(milliseconds: 900));

    final replyText = await KenickAiService.generateResponse(text, _messages);

    final botMessage = AiChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
        if (willEnd) {
          _isEnded = true;
        }
      });
      _scrollToBottom();
    }

    await KenickAiService.saveMessages(_messages);
    if (willEnd) {
      await KenickAiService.setConversationEnded(true);
    }
  }

  Future<void> _startNewConversation() async {
    HapticFeedback.lightImpact();
    await KenickAiService.resetConversation();
    final initial = await KenickAiService.loadMessages();
    if (mounted) {
      setState(() {
        _messages = initial;
        _isEnded = false;
        _isTyping = false;
      });
      _scrollToBottom();
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
                      Icons.arrow_back_rounded,
                      color: cs.onSurface,
                      size: 24,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 4),
                  // Robot Icon Badge
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
                        Icons.smart_toy_outlined,
                        size: 20,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Agent Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kenick AI agent',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'The team can also help',
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
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isTyping) {
                          return _buildTypingIndicator(isDark, cs);
                        }
                        final message = _messages[index];
                        return _buildMessageBubble(message, isDark, cs);
                      },
                    ),
            ),

            // Bottom Area: Conversation Ended banner OR Input Bar
            if (_isEnded)
              _buildEndedFooter(isDark, cs)
            else
              _buildInputBar(isDark, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    AiChatMessage message,
    bool isDark,
    ColorScheme cs,
  ) {
    if (message.isUser) {
      // User Message (Right-aligned, black pill)
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2026) : const Color(0xFF121417),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ),
      );
    }

    // Bot Message (Left-aligned, soft rounded grey card)
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262A33) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildRichMessageText(message.text, isDark, cs),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Kenick AI agent • Just now',
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

  Widget _buildTypingIndicator(bool isDark, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262A33) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pulsingDot(0, isDark),
                  const SizedBox(width: 5),
                  _pulsingDot(200, isDark),
                  const SizedBox(width: 5),
                  _pulsingDot(400, isDark),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Kenick AI agent • Typing...',
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

  Widget _pulsingDot(int delayMs, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRichMessageText(String text, bool isDark, ColorScheme cs) {
    final baseColor = isDark ? Colors.white : const Color(0xFF111827);
    final spans = _parseMarkdownSpans(text, baseColor);

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.48,
        ),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseMarkdownSpans(String text, Color baseColor) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  Widget _buildEndedFooter(bool isDark, ColorScheme cs) {
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
            'Your conversation has ended',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _startNewConversation,
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
                    Icons.refresh_rounded,
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
              controller: _inputController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Ask a question...',
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
              onSubmitted: (_) => _handleSendMessage(),
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
                onTap: _hasInputText ? _handleSendMessage : null,
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
                    child: Icon(
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

