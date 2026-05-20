import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool canAuthenticate;

  const BiometricLockScreen({
    super.key,
    required this.onUnlocked,
    this.canAuthenticate = true,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.canAuthenticate) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _hasError = false;
    });

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock the app',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate && mounted) {
        widget.onUnlocked();
      } else if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _hasError
                      ? 'Authentication failed. Tap below to try again.'
                      : 'Use Face ID / Touch ID to unlock',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(_isAuthenticating
                        ? 'Authenticating...'
                        : _hasError
                            ? 'Try Again'
                            : 'Unlock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
