import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/auth_routing_service.dart';
import 'package:kenick_vip/services/device_biometrics_service.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPasswordField = false;
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
    final data = await DeviceBiometricsService.checkDeviceBiometric(
      _emailController.text.trim(),
    );
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

        const storage = FlutterSecureStorage();
        final refreshToken = await storage.read(key: 'bio_refresh_token');
        if (refreshToken != null) {
          try {
            await Supabase.instance.client.auth.setSession(refreshToken);
          } catch (_) {}
        }

        if (!mounted) return;

        final user = auth.currentUser;
        if (user == null) {
          CustomToast.showError(
            context,
            'Session expired. Please log in with your password.',
          );
          return;
        }

        final role = user.userMetadata?['role'];

        if (role == null) {
          if (mounted) context.go('/role-selection');
        } else if (role == 'Chauffeur' || role == 'Affiliate') {
          final profile = await ProfileRepository().getDriverProfile(user.id);
          if (mounted) {
            if (profile == null || profile.firstName == null) {
              context.go('/driver-profile-setup');
            } else {
              context.go('/driver-home');
            }
          }
        } else {
          final profile = await ProfileRepository().getPassengerProfile(user.id);
          if (mounted) {
            if (profile == null || profile.firstName == null) {
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

  void _onContinuePressed() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      CustomToast.showError(context, 'Please enter a valid email address');
      return;
    }
    setState(() {
      _showPasswordField = true;
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      CustomToast.showError(context, 'Please enter email and password');
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _isNavigating = true);
    final success = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final user = auth.currentUser;

      if (user != null) {
        try {
          final routingService = AuthRoutingService();
          final route = await routingService.determineRouteForUser(user);
          if (mounted) context.go(route);
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
    context.push('/role-selection');
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Google sign in failed: $e');
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Apple sign in failed: $e');
      }
    }
  }

  void _handleCloseOrBack() {
    if (_showPasswordField) {
      setState(() => _showPasswordField = false);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Top Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _handleCloseOrBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : cs.surfaceContainerLow,
                      border: Border.all(
                        color: isDark
                            ? Colors.transparent
                            : cs.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Headline: "Welcome"
              FadeSlideIn(
                duration: AppDurations.slow,
                slideOffset: 0.04,
                child: Text(
                  'Welcome',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    letterSpacing: -0.5,
                    color: cs.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              FadeSlideIn(
                duration: AppDurations.slow,
                delay: const Duration(milliseconds: 60),
                slideOffset: 0.04,
                child: Text(
                  _showPasswordField
                      ? 'Enter your password to continue to Kenick.'
                      : 'Log in to continue to Kenick.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (!_showPasswordField) ...[
                // --- STEP 1: Email Form ---
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 100),
                  slideOffset: 0.04,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onContinuePressed(),
                    style: TextStyle(color: cs.onSurface, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Email address*',
                      hintStyle: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: cs.outlineVariant,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: cs.outlineVariant,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: cs.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Primary "Continue" Pill Button
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 140),
                  slideOffset: 0.04,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onContinuePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_biometricAvailable) ...[
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    duration: AppDurations.slow,
                    delay: const Duration(milliseconds: 160),
                    slideOffset: 0.04,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _handleBiometricLogin,
                        icon: Icon(
                          Icons.fingerprint_rounded,
                          size: 22,
                          color: cs.primary,
                        ),
                        label: Text(
                          'Log in with Biometrics',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.outlineVariant, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Don't have an account? Sign up
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 180),
                  slideOffset: 0.04,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleSignUp,
                        child: Text(
                          'Sign up',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                            decorationColor: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // OR divider
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 220),
                  slideOffset: 0.04,
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: cs.outlineVariant,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: cs.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Social Button: Continue with Google
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 260),
                  slideOffset: 0.04,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.outlineVariant, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleIcon(),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Social Button: Continue with Apple
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 300),
                  slideOffset: 0.04,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _handleAppleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.outlineVariant, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAppleIcon(cs),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Apple',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // --- STEP 2: Password Form (Matching user's uploaded Blacklane screenshot) ---

                // Box 1: Email Box with "Edit"
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 100),
                  slideOffset: 0.04,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _emailController.text.trim(),
                            style: TextStyle(
                              fontSize: 16,
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showPasswordField = false);
                          },
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                              decorationColor: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Box 2: Password Field ("and code input should be password")
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 130),
                  slideOffset: 0.04,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    style: TextStyle(color: cs.onSurface, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Enter your password*',
                      hintStyle: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: cs.outlineVariant,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: cs.outlineVariant,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: cs.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Box 3: Primary "Continue" Pill Button
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 160),
                  slideOffset: 0.04,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isLoading = auth.isLoading || _isNavigating;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      cs.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onPrimary,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Forgot Password Link ("and resend side should be like forgot password")
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 190),
                  slideOffset: 0.04,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Forgot your password? ',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: Text(
                          'Reset',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                            decorationColor: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_biometricAvailable) ...[
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    duration: AppDurations.slow,
                    delay: const Duration(milliseconds: 220),
                    slideOffset: 0.04,
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _handleBiometricLogin,
                        icon: Icon(
                          Icons.fingerprint_rounded,
                          size: 22,
                          color: cs.primary,
                        ),
                        label: Text(
                          'Log in with Biometrics',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
        ],
        stops: [0.1, 0.4, 0.7, 1.0],
      ).createShader(bounds),
      child: const FaIcon(
        FontAwesomeIcons.google,
        size: 19,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAppleIcon(ColorScheme cs) {
    return FaIcon(
      FontAwesomeIcons.apple,
      size: 20,
      color: cs.onSurface,
    );
  }
}
