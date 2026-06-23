import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceBiometricsService {
  static const String _deviceIdKey = 'device_uuid';
  static String? _cachedDeviceId;

  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  static String _generateDeviceId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = (now % 100000).toString();
    return 'dev_${now}_$random';
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('face_id_enabled') ?? false;
  }

  static Future<BiometricType?> getAvailableBiometricType() async {
    try {
      final auth = LocalAuthentication();
      final available = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();
      if (!available || !supported) return null;
      final types = await auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricType.face;
      if (types.contains(BiometricType.fingerprint)) return BiometricType.fingerprint;
      if (types.contains(BiometricType.iris)) return BiometricType.iris;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String> getBiometricLabel() async {
    final type = await getAvailableBiometricType();
    if (type == BiometricType.face) return 'Face ID';
    if (type == BiometricType.fingerprint) return 'Touch ID';
    if (type == BiometricType.iris) return 'Iris';
    return 'Biometrics';
  }

  static Future<void> registerDevice(String userId) async {
    final deviceId = await getDeviceId();
    await Supabase.instance.client.rpc(
      'register_device_biometric',
      params: {'p_user_id': userId, 'p_device_id': deviceId},
    );
  }

  static Future<void> unregisterDevice(String userId) async {
    final deviceId = await getDeviceId();
    await Supabase.instance.client.rpc(
      'unregister_device_biometric',
      params: {'p_user_id': userId, 'p_device_id': deviceId},
    );
  }

  static Future<Map<String, dynamic>?> checkDeviceBiometric(String email) async {
    final deviceId = await getDeviceId();
    try {
      final result = await Supabase.instance.client.rpc(
        'check_device_biometric',
        params: {'p_email': email, 'p_device_id': deviceId},
      );
      if (result != null) {
        return result as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> refreshSession(String userId) async {
    final deviceId = await getDeviceId();
    await Supabase.instance.client.rpc(
      'refresh_device_biometric',
      params: {'p_user_id': userId, 'p_device_id': deviceId},
    );
  }
}
