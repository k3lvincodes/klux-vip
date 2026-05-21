import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/document_repository.dart';
import 'package:kenick_vip/services/device_biometrics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
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
        persistAcrossBackgrounding: true,
      );

      if (didAuth && mounted && _biometricData != null) {
        final userId = _biometricData!['user_id'] as String;
        final auth = context.read<AuthProvider>();

        // Refresh the session timestamp locally via biometrics RPC
        await DeviceBiometricsService.refreshSession(userId);
        
        // Restore Supabase Session using saved refresh token
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('bio_refresh_token');
        if (refreshToken != null) {
          try {
            await Supabase.instance.client.auth.setSession(refreshToken);
          } catch (_) {
            // Ignore if refresh token is invalid/expired, it will fall through to null check below
          }
        }
        
        if (!mounted) return;

        // Get user role and redirect
        final user = auth.currentUser;
        if (user == null) {
          CustomToast.showError(context, 'Session expired. Please log in with your password.');
          return;
        }

        final role = user.userMetadata?['role'];

        if (role == 'Driver' || role == 'Affiliate') {
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
          if (role == 'Driver' || role == 'Affiliate') {
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkBackground 
                  : AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 180, 0, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to your account',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey),
                      ),
                      const SizedBox(height: 34),
                      _buildInput(
                        controller: _emailController,
                        hintText: 'Enter your full name/Email',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _passwordController,
                        hintText: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? AppColors.white : AppColors.black),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final isLoading = auth.isLoading || _isNavigating;
                          return CustomButton(
                            title: isLoading ? 'Loading...' : 'Login',
                            onPress: isLoading ? () {} : _handleLogin,
                            variant: ButtonVariant.primary,
                            height: 40,
                            borderRadius: 25,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            isLoading: isLoading,
                          );
                        }
                      ),
                      if (_biometricAvailable) ...[
                        const SizedBox(height: 16),
                        CustomButton(
                          title: 'Login with Biometrics',
                          onPress: _handleBiometricLogin,
                          variant: ButtonVariant.outline,
                          height: 40,
                          borderRadius: 25,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildOrContinue(),
                      const SizedBox(height: 18),
                      _buildSocialButtons(),
                    ].animate(interval: 50.ms).fade(duration: 400.ms, curve: Curves.easeOutQuad).slideY(begin: 0.1, end: 0),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.white : AppColors.black),
                        ),
                        GestureDetector(
                          onTap: _handleSignUp,
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(duration: 400.ms, delay: 600.ms).slideY(begin: 0.2, end: 0),
            ),
          ],
        ),
    );
  }

  Widget _buildOrContinue() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or continue with',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.black54),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
          label: 'G',
          color: const Color(0xFFDB4437),
        ),
        const SizedBox(width: 18),
        _socialButton(
          iconWidget: Icon(Icons.apple, size: 22, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ],
    );
  }

  Widget _socialButton({String? label, Widget? iconWidget, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: label != null
            ? Text(
                label,
                style: TextStyle(
                  fontSize: label.length == 1 && label.toLowerCase() == 'f' ? 20 : 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              )
            : (iconWidget ?? const SizedBox()),
      ),
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
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
              controller: controller,
              obscureText: isPassword && !isPasswordVisible,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.white : AppColors.black),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: onToggleVisibility,
            ),
        ],
      ),
    );
  }
}
