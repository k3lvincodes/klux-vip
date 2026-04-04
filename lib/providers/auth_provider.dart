import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _supabase.auth.currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Sign up with Email and Password
  Future<bool> signUp(String email, String password, String name, String role) async {
    try {
      _setLoading(true);
      _setError(null);
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
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

  /// Sign in with Email and Password
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
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

  /// Verifies the OTP sent to the email
  Future<bool> verifyOtp(String email, String token, {bool isSignup = false, bool isPasswordReset = false}) async {
    try {
      _setLoading(true);
      _setError(null);
      
      OtpType type = OtpType.magiclink;
      if (isSignup) type = OtpType.signup;
      if (isPasswordReset) type = OtpType.recovery;

      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
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

  /// Sends a password reset OTP to the given email
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

  /// Updates the user's password using the current session
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

  /// Update user metadata (like role)
  Future<bool> updateUserRole(String role) async {
    try {
      _setLoading(true);
      _setError(null);
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'role': role},
        ),
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

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabase.auth.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
