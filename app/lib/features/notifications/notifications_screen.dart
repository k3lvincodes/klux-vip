import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/repositories/notification_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/feedback/shimmer_loading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repo = NotificationRepository();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _isLoading = false; _error = 'Not authenticated'; });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = 'Failed to load notifications'; });
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) _notifications[index]['is_read'] = true;
        });
      }
    } catch (_) {}
  }

  String _formatDate(String iso) {
    final date = DateTime.parse(iso);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'ride_update':
        return Icons.directions_car_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'system':
        return Icons.info_outline_rounded;
      case 'driver_assigned':
        return Icons.person_pin_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type, bool isDark) {
    switch (type) {
      case 'ride_update':
        return AppColors.primary;
      case 'payment':
        return const Color(0xFF22C55E);
      case 'promotion':
        return const Color(0xFF8B5CF6);
      case 'driver_assigned':
        return const Color(0xFF3B82F6);
      default:
        return isDark ? Colors.white54 : Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(5, (i) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 80, avatarSize: 44),
          )),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFEF4444)),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.white : AppColors.text)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkText.withValues(alpha: 0.6) : Colors.grey.shade600)),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.7)),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text('No notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.white : AppColors.text)),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up!\nWe\'ll let you know when something comes up.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? AppColors.darkText.withValues(alpha: 0.6) : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final isRead = notification['is_read'] as bool? ?? false;
          final type = notification['type'] as String?;
          final title = notification['title'] as String? ?? 'Notification';
          final body = notification['body'] as String?;
          final createdAt = notification['created_at'] as String?;

          return FadeSlideIn(
            delay: Duration(milliseconds: 40 * index),
            child: GestureDetector(
              onTap: !isRead && notification['id'] != null
                  ? () => _markAsRead(notification['id'])
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.transparent
                      : AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _colorForType(type, isDark).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconForType(type),
                        size: 20,
                        color: _colorForType(type, isDark),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                    color: isDark ? AppColors.white : AppColors.text,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          if (body != null && body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark
                                    ? AppColors.darkText.withValues(alpha: 0.5)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkText.withValues(alpha: 0.35)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
