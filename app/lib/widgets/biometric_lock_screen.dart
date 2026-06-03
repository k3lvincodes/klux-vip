import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kenick_vip/theme/app_colors.dart';

enum LockMode { soft, hard }

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback? onSoftDismiss;
  final bool canAuthenticate;
  final LockMode lockMode;

  const BiometricLockScreen({
    super.key,
    required this.onUnlocked,
    this.onSoftDismiss,
    this.canAuthenticate = true,
    this.lockMode = LockMode.hard,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with TickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _biometricAvailable = true;
  late final AnimationController _pulseController;
  late final AnimationController _entranceController;
  BiometricType? _biometricType;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _initBiometrics();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _initBiometrics() async {
    try {
      final available = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (available && supported) {
        final types = await _auth.getAvailableBiometrics();
        if (mounted) {
          setState(() {
            _biometricAvailable = types.isNotEmpty;
            if (types.contains(BiometricType.face)) {
              _biometricType = BiometricType.face;
            } else if (types.contains(BiometricType.fingerprint)) {
              _biometricType = BiometricType.fingerprint;
            } else if (types.contains(BiometricType.iris)) {
              _biometricType = BiometricType.iris;
            }
          });
        }
      } else {
        if (mounted) setState(() => _biometricAvailable = false);
      }
    } catch (_) {
      if (mounted) setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _authenticate() async {
    if (!_biometricAvailable && widget.canAuthenticate) return;

    setState(() {
      _isAuthenticating = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final reason = widget.lockMode == LockMode.hard
          ? 'Authenticate to unlock the app'
          : 'Verify it\'s you';

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );

      if (didAuthenticate && mounted) {
        _onUnlocked();
      } else if (mounted) {
        _onError('Authentication failed');
      }
    } catch (e) {
      if (mounted) {
        _onError(e.toString().contains('UserCanceled') || e.toString().contains('canceled')
            ? ''
            : 'Biometric not available');
      }
    }
  }

  void _onUnlocked() {
    _entranceController.reverse().then((_) {
      if (mounted) widget.onUnlocked();
    });
  }

  void _onError(String message) {
    setState(() {
      _isAuthenticating = false;
      _hasError = true;
      _errorMessage = message;
    });
  }

  String get _biometricLabel {
    if (_biometricType == BiometricType.face) return 'Face ID';
    if (_biometricType == BiometricType.fingerprint) return 'Touch ID';
    return 'Biometrics';
  }

  IconData get _biometricIcon {
    if (_biometricType == BiometricType.face) return Icons.face_3;
    if (_biometricType == BiometricType.fingerprint) return Icons.fingerprint;
    return Icons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pulseValue = _pulseController.value;
    final entranceValue = _entranceController.value;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _entranceController,
          child: child,
        );
      },
      child: Container(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        child: ClipRect(
          child: BackdropFilter(
          filter: _entranceController.value > 0.5
              ? (isDark
                  ? _darkBlur
                  : _lightBlur)
              : _lightBlur,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 0.8 + 0.2 * entranceValue,
                      child: _buildIcon(isDark, pulseValue),
                    ),
                    const SizedBox(height: 40),
                    _buildTitle(isDark, entranceValue),
                    const SizedBox(height: 12),
                    _buildSubtitle(isDark, entranceValue),
                    const SizedBox(height: 48),
                    _buildButton(isDark),
                    if (widget.lockMode == LockMode.soft &&
                        _hasError) ...[
                      const SizedBox(height: 16),
                      _buildSkipButton(isDark),
                    ],
                    if (widget.lockMode == LockMode.soft &&
                        !_hasError) ...[
                      const SizedBox(height: 16),
                      _buildSkipButton(isDark),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark, double pulse) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15 + 0.08 * pulse),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08 + 0.06 * pulse),
            blurRadius: 24 + 12 * pulse,
            spreadRadius: 2 * pulse,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_biometricType == BiometricType.face)
            Icon(
              Icons.face_3_outlined,
              size: 42,
              color: AppColors.primary.withValues(alpha: 0.6 + 0.4 * (1 - pulse)),
            ),
          Icon(
            _biometricIcon,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.7 + 0.3 * pulse),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark, double entrance) {
    return Opacity(
      opacity: entrance,
      child: Column(
        children: [
          Text(
            'App Locked',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.lockMode == LockMode.hard ? 'secured' : 'paused',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 4,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(bool isDark, double entrance) {
    return Opacity(
      opacity: entrance * 0.8,
      child: Text(
        _hasError && _errorMessage.isNotEmpty
            ? _errorMessage
            : _biometricAvailable
                ? 'Use $_biometricLabel to unlock'
                : 'Device biometrics not available',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: _hasError
              ? Colors.red.shade400
              : isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAuthenticating || !_biometricAvailable
            ? null
            : _authenticate,
        icon: _isAuthenticating
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.black,
                  ),
                ),
              )
            : Icon(
                _biometricAvailable ? _biometricIcon : Icons.lock_open,
                size: 20,
              ),
        label: Text(
          _isAuthenticating
              ? 'Verifying...'
              : _hasError
                  ? 'Try Again'
                  : _biometricAvailable
                      ? 'Unlock with $_biometricLabel'
                      : 'Unlock',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildSkipButton(bool isDark) {
    return TextButton(
      onPressed: widget.onSoftDismiss,
      child: Text(
        'Enter app without unlocking',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  ui.ImageFilter get _lightBlur =>
      ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5);

  ui.ImageFilter get _darkBlur =>
      ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0);
}
