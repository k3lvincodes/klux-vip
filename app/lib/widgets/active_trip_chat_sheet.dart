import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class ActiveTripChatSheet extends StatefulWidget {

  const ActiveTripChatSheet({
    super.key,
    required this.recipientName,
  });
  final String recipientName;

  static void show(BuildContext context, String recipientName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => ActiveTripChatSheet(recipientName: recipientName),
    );
  }

  @override
  State<ActiveTripChatSheet> createState() => _ActiveTripChatSheetState();
}

class _ActiveTripChatSheetState extends State<ActiveTripChatSheet>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello! I am on my way to your pickup location.', 'isMe': false, 'time': '12:31 PM'},
    {'text': 'Great, thank you! I am waiting near the main lobby.', 'isMe': true, 'time': '12:32 PM'},
  ];

  final TextEditingController _textController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  
  bool _isTyping = false;
  bool _showMediaPanel = false;

  @override
  void initState() {
    super.initState();
    // Simulate chauffeur typing after a short delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _isTyping = true);
      }
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
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    
    final newMsg = {
      'text': text,
      'isMe': true,
      'time': 'Just now',
    };

    _messages.add(newMsg);
    final insertIndex = _messages.length - 1;
    _listKey.currentState?.insertItem(
      insertIndex,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _insertReceivedMessage(String text) {
    final newMsg = {
      'text': text,
      'isMe': false,
      'time': 'Just now',
    };

    _messages.add(newMsg);
    final insertIndex = _messages.length - 1;
    _listKey.currentState?.insertItem(
      insertIndex,
      duration: const Duration(milliseconds: 350),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + keyboardHeight,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          _buildHeader(isDark),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark)
                : AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    initialItemCount: _messages.length,
                    itemBuilder: (context, index, animation) {
                      final msg = _messages[index];
                      return _buildMessageItem(msg, animation, isDark);
                    },
                  ),
          ),

          // Typing Indicator Overlay
          if (_isTyping) _buildTypingIndicator(isDark),

          // Input field and Media attachments
          _buildInputBar(isDark),

          // Quick attachments tray
          if (_showMediaPanel) _buildMediaPanel(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFF5F0EF),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  Text(
                    'Online · Active Ride',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Call action touch feedback
              PressScale(
                onTap: () {
                  // Simulate phone call action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulating voice call connection...')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg, Animation<double> animation, bool isDark) {
    final isMe = msg['isMe'] as bool;
    final text = msg['text'] as String;

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : (isDark ? AppColors.darkSurface : const Color(0xFFF3EEEC)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isMe ? AppColors.black : (isDark ? AppColors.white : Colors.black87),
                      fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: 350.ms,
                      curve: Curves.elasticOut,
                      alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.recipientName} is typing',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 8),
          _buildTypingDots(isDark),
        ],
      ),
    );
  }

  Widget _buildTypingDots(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary : Colors.grey.shade600,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(
              begin: 0.6,
              end: 1.4,
              duration: 400.ms,
              delay: (i * 150).ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment toggler (Tactile pulse)
          PressScale(
            onTap: () {
              setState(() {
                _showMediaPanel = !_showMediaPanel;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : const Color(0xFFF9F8F8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showMediaPanel ? Icons.close : Icons.add_circle_outline,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Message input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF5F0EF),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
                controller: _textController,
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.black,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Message chauffeur...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button (Optimistic scaling feedback)
          PressScale(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.black,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPanel(bool isDark) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.darkSurface : const Color(0xFFFAF9F9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMediaItem(Icons.camera_alt, 'Camera', Colors.orange, isDark),
          _buildMediaItem(Icons.photo_library, 'Gallery', Colors.blue, isDark),
          _buildMediaItem(Icons.location_on, 'Location', Colors.green, isDark),
          _buildMediaItem(Icons.mic, 'Audio', Colors.red, isDark),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.4, end: 0, duration: 250.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildMediaItem(IconData icon, String label, Color color, bool isDark) {
    return PressScale(
      onTap: () {
        setState(() => _showMediaPanel = false);
        _insertReceivedMessage('[Sent $label]');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
