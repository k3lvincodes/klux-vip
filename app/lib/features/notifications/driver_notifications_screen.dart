import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/repositories/notification_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() => _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  final NotificationRepository _notificationRepo = NotificationRepository();
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final dt = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return 'Recently';
    }
  }

  IconData _getNotificationIcon(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('ride') || t.contains('dispatch') || t.contains('trip') || t.contains('assign')) {
      return Icons.directions_car_rounded;
    }
    if (t.contains('payment') || t.contains('payout') || t.contains('wallet') || t.contains('earn')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (t.contains('verify') || t.contains('document') || t.contains('kyc') || t.contains('license')) {
      return Icons.verified_user_rounded;
    }
    if (t.contains('rating') || t.contains('review') || t.contains('star')) {
      return Icons.star_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('ride') || t.contains('dispatch') || t.contains('trip')) {
      return AppColors.primary;
    }
    if (t.contains('payment') || t.contains('payout') || t.contains('earn')) {
      return const Color(0xFF10B981); // Emerald
    }
    if (t.contains('verify') || t.contains('document')) {
      return const Color(0xFF3B82F6); // Blue
    }
    return AppColors.primary;
  }

  Future<void> _markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;
    HapticFeedback.lightImpact();
    try {
      await _notificationRepo.markAllAsRead(userId);
      if (mounted) {
        CustomToast.showSuccess(context, 'All notifications marked as read');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Unable to mark notifications: $e');
      }
    }
  }

  Future<void> _markSingleAsRead(String id, bool isRead) async {
    if (isRead) return;
    HapticFeedback.lightImpact();
    try {
      await _notificationRepo.markAsRead(id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF18181B);
    final textMuted = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final dividerColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Standard Circular Back Button (ui_pattern Section 3.1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18191C) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dividerColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_currentUserId != null)
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2128) : const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: dividerColor, width: 0.8),
                        ),
                        child: Text(
                          'Mark read',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF27272A),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Notification Stream Body
            Expanded(
              child: _currentUserId == null
                  ? _buildEmptyState(isDark, textPrimary, textMuted)
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _notificationRepo.listenToNotifications(_currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          );
                        }

                        final notifications = (snapshot.data ?? []).reversed.toList();

                        if (notifications.isEmpty) {
                          return _buildEmptyState(isDark, textPrimary, textMuted);
                        }

                        return RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: notifications.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              final id = item['id']?.toString() ?? '';
                              final title = item['title']?.toString() ?? 'Notification';
                              final body = item['body']?.toString() ?? item['message']?.toString() ?? '';
                              final type = item['type']?.toString();
                              final isRead = item['is_read'] == true;
                              final createdAt = item['created_at'];
                              final accentColor = _getNotificationColor(type);
                              final icon = _getNotificationIcon(type);

                              return GestureDetector(
                                onTap: () => _markSingleAsRead(id, isRead),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? (isRead ? const Color(0xFF16181D) : const Color(0xFF1A1C24))
                                        : (isRead ? Colors.white : const Color(0xFFFFFDF5)),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isRead
                                          ? dividerColor
                                          : AppColors.primary.withValues(alpha: 0.4),
                                      width: isRead ? 1 : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category Icon Container
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: accentColor.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          icon,
                                          size: 20,
                                          color: accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Text Information
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                                      color: textPrimary,
                                                      letterSpacing: -0.2,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _formatNotificationTime(createdAt),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w400,
                                                    color: textMuted,
                                                  ),
                                                ),
                                                if (!isRead) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (body.isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              Text(
                                                body,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w400,
                                                  color: textMuted,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textPrimary, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF0F0F2),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! New dispatch offers, payout updates, and chauffeur notices will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

