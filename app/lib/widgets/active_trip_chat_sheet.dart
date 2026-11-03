import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

class ActiveTripChatSheet extends StatefulWidget {
  const ActiveTripChatSheet({
    super.key,
    required this.recipientName,
  });

  final String recipientName;

  static void show(BuildContext context, String recipientName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => ActiveTripChatSheet(recipientName: recipientName),
    );
  }

  @override
  State<ActiveTripChatSheet> createState() => _ActiveTripChatSheetState();
}

class _ActiveTripChatSheetState extends State<ActiveTripChatSheet> {
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello! I am on my way to your pickup location.', 'isMe': false, 'time': '12:31 PM'},
    {'text': 'Great, thank you! I am waiting near the main lobby.', 'isMe': true, 'time': '12:32 PM'},
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _showMediaPanel = false;
  bool _hasInputText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    // Simulate chauffeur typing after a short delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isTyping = true);
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _isTyping = false);
        _insertReceivedMessage('I will arrive in about 2 minutes. See you soon!');
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _textController.clear();

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': 'Just now',
      });
    });

    _scrollToBottom();
  }

  void _insertReceivedMessage(String text) {
    setState(() {
      _messages.add({
        'text': text,
        'isMe': false,
        'time': 'Just now',
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85 + keyboardHeight,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header matching Kenick AI style
          _buildHeader(isDark, cs),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(cs)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator(isDark, cs);
                      }
                      final msg = _messages[index];
                      return _buildMessageItem(msg, isDark, cs);
                    },
                  ),
          ),

          // Quick attachments tray
          if (_showMediaPanel) _buildMediaPanel(isDark),

          // Message input bar with ONLY bottom border line
          _buildInputBar(isDark, cs),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme cs) {
    final subtleDivider = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: subtleDivider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 24,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Chauffeur Avatar / Badge
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
                  Icons.directions_car_rounded,
                  size: 20,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Chauffeur Name & Active Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.recipientName,
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
                    'Active VIP Chauffeur • Online',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Call Action Button
            PressScale(
              onTap: () {
                HapticFeedback.lightImpact();
                CustomToast.showInfo(context, 'Connecting secure call to chauffeur...');
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.phone_rounded,
                    color: cs.onSurface,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Text(
        'Start conversation with your chauffeur',
        style: GoogleFonts.poppins(
          color: cs.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    Map<String, dynamic> msg,
    bool isDark,
    ColorScheme cs,
  ) {
    final isMe = msg['isMe'] as bool;
    final text = msg['text'] as String;
    final time = msg['time'] as String;

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
                  text,
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
                  'You • $time',
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

    // Chauffeur Message (Left-aligned, soft rounded grey card)
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
                text,
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
                '${widget.recipientName} • $time',
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
                '${widget.recipientName} • Typing...',
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
              controller: _textController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Message chauffeur...',
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
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(height: 8),

          // Toolbar Row: Attachments, GIF, Mic, Send Button
          Row(
            children: [
              // Attachment Paperclip
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showMediaPanel = !_showMediaPanel);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
                  child: Icon(
                    _showMediaPanel ? Icons.close_rounded : Icons.attach_file_rounded,
                    size: 20,
                    color: _showMediaPanel
                        ? AppColors.primary
                        : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
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
                onTap: _hasInputText ? _sendMessage : null,
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

  Widget _buildMediaPanel(bool isDark) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF9FAFB),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMediaItem(Icons.camera_alt_outlined, 'Camera', Colors.orange, isDark),
          _buildMediaItem(Icons.photo_library_outlined, 'Gallery', Colors.blue, isDark),
          _buildMediaItem(Icons.location_on_outlined, 'Location', Colors.green, isDark),
          _buildMediaItem(Icons.access_time_rounded, 'ETA update', Colors.purple, isDark),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.4, end: 0, duration: 250.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildMediaItem(IconData icon, String label, Color color, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showMediaPanel = false);
        CustomToast.showInfo(context, '$label shared with chauffeur');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
