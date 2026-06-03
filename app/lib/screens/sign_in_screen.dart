import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/document_repository.dart';
import 'package:kenick_vip/services/device_biometrics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _biometricAvailable = false;
  Map<String, dynamic>? _biometricData;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    if (_emailController.text.contains('@') && _emailController.text.length > 5) {
      _checkBiometricForEmail();
    } else {
      if (_biometricAvailable) setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _checkBiometricForEmail() async {
    final data = await DeviceBiometricsService.checkDeviceBiometric(_emailController.text.trim());
    if (mounted) {
      setState(() {
        _biometricAvailable = data != null;
        _biometricData = data;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      final canBiometrics = await _localAuth.canCheckBiometrics;
      if (!canBiometrics) {
        if (mounted) CustomToast.showError(context, 'Biometrics not available');
        return;
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Log in with biometrics',
        biometricOnly: true,
      );

      if (didAuth && mounted && _biometricData != null) {
        final userId = _biometricData!['user_id'] as String;
        final auth = context.read<AuthProvider>();

        await DeviceBiometricsService.refreshSession(userId);

        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('bio_refresh_token');
        if (refreshToken != null) {
          try {
            await Supabase.instance.client.auth.setSession(refreshToken);
          } catch (_) {}
        }

        if (!mounted) return;

        final user = auth.currentUser;
        if (user == null) {
          CustomToast.showError(context, 'Session expired. Please log in with your password.');
          return;
        }

        final role = user.userMetadata?['role'];

        if (role == null) {
          if (mounted) context.go('/role-selection');
        } else if (role == 'Chauffeur' || role == 'Affiliate') {
          final profile = await ProfileRepository().getDriverProfile(user.id);
          if (mounted) {
            if (profile == null || profile['first_name'] == null) {
              context.go('/driver-profile-setup');
            } else {
              context.go('/driver-home');
            }
          }
        } else {
          final profile = await ProfileRepository().getPassengerProfile(user.id);
          if (mounted) {
            if (profile == null || profile['first_name'] == null) {
              context.go('/passenger-profile-setup');
            } else {
              context.go('/passenger-home');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Biometric login failed');
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      CustomToast.showError(context, 'Please enter email and password');
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _isNavigating = true);
    final success = await auth.signIn(_emailController.text.trim(), _passwordController.text);

    if (success && mounted) {
      final user = auth.currentUser;
      final role = user?.userMetadata?['role'];

      if (user != null) {
        try {
          if (role == null) {
            if (mounted) context.go('/role-selection');
          } else if (role == 'Chauffeur' || role == 'Affiliate') {
            final results = await Future.wait([
              ProfileRepository().getDriverProfile(user.id),
              DocumentRepository().getDocumentByType(user.id, 'driver_license'),
            ]);

            final profile = results[0];
            final idDoc = results[1];

            if (mounted) {
              if (profile == null || (profile as Map)['first_name'] == null) {
                context.go('/driver-profile-setup');
              } else if (idDoc == null) {
                context.go('/driver-id-verification');
              } else {
                context.go('/driver-home');
              }
            }
          } else {
            final profile = await ProfileRepository().getPassengerProfile(user.id);
            if (mounted) {
              if (profile == null || profile['first_name'] == null) {
                context.go('/passenger-profile-setup');
              } else {
                context.go('/passenger-home');
              }
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isNavigating = false);
            CustomToast.showError(context, 'Error fetching profile data');
          }
        }
      } else {
        if (mounted) setState(() => _isNavigating = false);
      }
    } else {
      if (mounted) {
        setState(() => _isNavigating = false);
        CustomToast.showError(context, auth.errorMessage ?? 'Login failed');
      }
    }
  }

  void _handleSignUp() {
    context.push('/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? AppColors.darkBackground : AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 120, 0, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      slideOffset: 0.04,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                              letterSpacing: -0.5,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to continue to Kenick',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 80),
                      slideOffset: 0.04,
                      child: _buildInput(
                        controller: _emailController,
                        hintText: 'Email address',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 120),
                      slideOffset: 0.04,
                      child: _buildInput(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 160),
                      slideOffset: 0.04,
                      child: Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 200),
                      slideOffset: 0.04,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final isLoading = auth.isLoading || _isNavigating;
                          return CustomButton(
                            title: isLoading ? 'Signing in...' : 'Sign In',
                            onPress: isLoading ? () {} : _handleLogin,
                            variant: ButtonVariant.primary,
                            height: 52,
                            borderRadius: 30,
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            isLoading: isLoading,
                          );
                        },
                      ),
                    ),
                    if (_biometricAvailable) ...[
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 240),
                        slideOffset: 0.04,
                        child: CustomButton(
                          title: 'Log in with Biometrics',
                          onPress: _handleBiometricLogin,
                          variant: ButtonVariant.outline,
                          height: 52,
                          borderRadius: 30,
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          icon: Icons.fingerprint,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 280),
                      slideOffset: 0.04,
                      child: _buildDivider(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: FadeSlideIn(
                duration: AppDurations.slow,
                delay: const Duration(milliseconds: 360),
                slideOffset: 0.06,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleSignUp,
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              scrollPadding: const EdgeInsets.only(bottom: 10),
              controller: controller,
              obscureText: isPassword && !isPasswordVisible,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.white : AppColors.black),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade400,
              ),
              onPressed: onToggleVisibility,
            ),
        ],
      ),
    );
  }
}
