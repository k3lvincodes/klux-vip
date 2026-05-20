import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kenick_vip/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> registerDeviceForNotifications() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final notificationRepo = NotificationRepository();

  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await notificationRepo.registerDevice(
        userId: user.id,
        fcmToken: fcmToken,
      );
    }
  } catch (e) {
    // Handle error silently
  }
}
