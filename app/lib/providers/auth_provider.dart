import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kenick_vip/services/firebase_service.dart';

enum SessionState {
  unauthenticated,
  authenticating,
  authenticated,
  biometricLocked,
  sessionExpired,
}

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  SessionState _sessionState = SessionState.unauthenticated;
  SessionState _previousState = SessionState.unauthenticated;
  User? _cachedUser;
  String? _userRole;
  DateTime? _lastSessionCheck;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SessionState get sessionState => _sessionState;
  SessionState get previousState => _previousState;
  String? get userRole => _userRole;
  bool get isInitialized => _isInitialized;

  User? get currentUser {
    final live = _supabase.auth.currentUser;
    if (live != null) return live;
    return _cachedUser;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setSessionState(SessionState state) {
    _previousState = _sessionState;
    _sessionState = state;
    if (state == SessionState.authenticated || state == SessionState.biometricLocked) {
      _cachedUser = _supabase.auth.currentUser;
      _userRole = _cachedUser?.userMetadata?['role'] as String?;
      _lastSessionCheck = DateTime.now();
    }
    if (state == SessionState.unauthenticated || state == SessionState.sessionExpired) {
      _cachedUser = null;
      _userRole = null;
    }
    notifyListeners();
  }

  bool get isAuthenticated => _sessionState == SessionState.authenticated;

  Future<void> restoreSession() async {
    if (_isInitialized) return;
    _setSessionState(SessionState.authenticating);
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _cachedUser = _supabase.auth.currentUser;
        _userRole = _cachedUser?.userMetadata?['role'] as String?;
        _setSessionState(SessionState.authenticated);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final sessionJson = prefs.getString('bio_session');
        if (sessionJson != null) {
          try {
            await _supabase.auth.setSession(sessionJson);
            _cachedUser = _supabase.auth.currentUser;
            if (_cachedUser != null) {
              _userRole = _cachedUser?.userMetadata?['role'] as String?;
              _setSessionState(SessionState.authenticated);
              _isInitialized = true;
              return;
            }
          } catch (_) {}
        }
        _setSessionState(SessionState.unauthenticated);
      }
    } catch (_) {
      _setSessionState(SessionState.unauthenticated);
    }
    _isInitialized = true;
  }

  Future<void> silentRefreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null && session.isExpired) {
        await _supabase.auth.refreshSession();
        _cachedUser = _supabase.auth.currentUser;
        _userRole = _cachedUser?.userMetadata?['role'] as String?;
        _lastSessionCheck = DateTime.now();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> restoreUserContext() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final role = user.userMetadata?['role'] as String?;
      if (role != _userRole) {
        _userRole = role;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setBiometricLocked() {
    if (_sessionState == SessionState.authenticated) {
      _setSessionState(SessionState.biometricLocked);
    }
  }

  void clearBiometricLock() {
    if (_sessionState == SessionState.biometricLocked) {
      _setSessionState(SessionState.authenticated);
    }
  }

  bool checkSessionExpiry() {
    if (_lastSessionCheck == null) return false;
    final session = _supabase.auth.currentSession;
    if (session != null && session.isExpired) {
      _setSessionState(SessionState.sessionExpired);
      return true;
    }
    return false;
  }

  Future<bool> signUp(String email, String password, String name, String role) async {
    try {
      _setLoading(true);
      _setError(null);
      final metadata = <String, dynamic>{'name': name};
      if (role.isNotEmpty) {
        metadata['role'] = role;
      }
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user != null && response.user!.identities != null && response.user!.identities!.isEmpty) {
        _setError('An account with this email already exists');
        return false;
      }

      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      _setSessionState(SessionState.authenticating);
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _userRole = response.user!.userMetadata?['role'] as String?;
        _setSessionState(SessionState.authenticated);
        FirebaseService().registerDevice(response.user!.id).ignore();
      }

      if (response.session?.refreshToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bio_session', jsonEncode(response.session!.toJson()));
      }

      return true;
    } on AuthException catch (e) {
      _setSessionState(SessionState.unauthenticated);
      _setError(e.message);
      return false;
    } catch (e) {
      _setSessionState(SessionState.unauthenticated);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String email, String token, {bool isSignup = false, bool isPasswordReset = false}) async {
    try {
      _setLoading(true);
      _setError(null);

      OtpType type = OtpType.magiclink;
      if (isSignup) type = OtpType.signup;
      if (isPasswordReset) type = OtpType.recovery;

      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );

      if (response.user != null && !isPasswordReset) {
        _userRole = response.user!.userMetadata?['role'] as String?;
        _setSessionState(SessionState.authenticated);
        FirebaseService().registerDevice(response.user!.id).ignore();
      }

      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserRole(String role) async {
    try {
      _setLoading(true);
      _setError(null);
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'role': role},
        ),
      );
      _userRole = role;
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabase.auth.signOut();
      _cachedUser = null;
      _userRole = null;
      _isInitialized = false;
      _setSessionState(SessionState.unauthenticated);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
