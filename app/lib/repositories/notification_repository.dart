import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> registerDevice({
    required String userId,
    required String fcmToken,
    String deviceType = 'android',
  }) async {
    try {
      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': fcmToken,
        'device_type': deviceType,
      }, onConflict: 'fcm_token');
      return fcmToken;
    } catch (e) {
      throw Exception('Failed to register device: $e');
    }
  }

  Future<void> unregisterDevice(String fcmToken) async {
    try {
      await _supabase
          .from('user_devices')
          .update({'is_active': false})
          .eq('fcm_token', fcmToken);
    } catch (e) {
      throw Exception('Failed to unregister device: $e');
    }
  }

  Future<String?> getDeviceToken(String userId) async {
    try {
      final response = await _supabase
          .from('user_devices')
          .select('fcm_token')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response?['fcm_token'];
    } catch (e) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> listenToNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((events) => events);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.functions.invoke(
        'notifications',
        body: {
          'user_id': userId,
          'type': type,
          'title': title,
          'body': body,
          'data': data,
        },
      );
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }
}
