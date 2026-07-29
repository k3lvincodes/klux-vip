import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kenick_vip/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseService {
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  static final FirebaseService _instance = FirebaseService._internal();

  final NotificationRepository _notificationRepo = NotificationRepository();
  String? _fcmToken;
  StreamSubscription? _onTokenRefreshSub;
  StreamSubscription? _onMessageSub;
  StreamSubscription? _onMessageOpenedAppSub;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _updateDeviceToken(token);
      });

      _fcmToken = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        debugPrint('FCM Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase init failed: $e');
      }
    }
  }

  Future<void> registerDevice(String userId) async {
    try {
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        _fcmToken = await FirebaseMessaging.instance.getToken();
      }

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _notificationRepo.registerDevice(
          userId: userId,
          fcmToken: _fcmToken!,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to register device: $e');
      }
    }
  }

  Future<void> _updateDeviceToken(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _notificationRepo.registerDevice(
          userId: user.id,
          fcmToken: token,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update device token: $e');
      }
    }
  }

  Future<void> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        announcement: true,
      );
      if (kDebugMode) {
        debugPrint('Notification permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Permission request failed: $e');
      }
    }
  }

  void setForegroundHandler(Function(RemoteMessage) handler) {
    _onMessageSub = FirebaseMessaging.onMessage.listen(handler);
  }

  void setNotificationOpenedHandler(Function(RemoteMessage) handler) {
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  static void setBackgroundHandler(Future<void> Function(RemoteMessage) handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  void dispose() {
    _onTokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }

  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    if (kDebugMode) {
      debugPrint('Background message: ${message.notification?.title}');
    }
  }
}
