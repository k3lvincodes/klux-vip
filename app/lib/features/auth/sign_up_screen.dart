import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.role});
  final String? role;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPasswordField = false;
  bool _isPasswordVisible = false;
  bool _isChecked = false;

  bool get _isAffiliate => widget.role?.toLowerCase() == 'affiliate';
  bool get _isChauffeur => widget.role?.toLowerCase() == 'chauffeur';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (!_isChecked) {
      CustomToast.showError(context, 'Please accept the terms and conditions');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      CustomToast.showError(context, 'Please enter a password');
      return;
    }

    if (password.length < 6) {
      CustomToast.showError(context, 'Password must be at least 6 characters');
      return;
    }

    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    final role = widget.role ?? 'Client';

    final Map<String, dynamic> extraData = {
      'role': role,
    };

    final success = await auth.signUp(
      email,
      password,
      '',
      role,
      extraData: extraData,
    );

    if (success) {
      try {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: email,
        );
      } catch (_) {}
      if (!context.mounted) return;
      router.go('/otp?email=$email&role=$role&isSignup=true');
    } else {
      if (mounted) {
        CustomToast.showError(context, auth.errorMessage ?? 'Sign up failed');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Google sign up failed: $e');
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Apple sign up failed: $e');
      }
    }
  }

  void _handleSignIn() {
    context.go('/sign-in');
  }

  void _handleBack() {
    if (_showPasswordField) {
      setState(() => _showPasswordField = false);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/role-selection');
    }
  }

  void _handleChangeRole() {
    context.go('/role-selection');
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(color: cs.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
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
        suffixIcon: suffixIcon,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String activeRoleLabel = _isAffiliate
        ? 'Affiliate'
        : _isChauffeur
            ? 'Chauffeur'
            : 'Client';

    const String subtitle = 'Sign Up to continue to Kenick.';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Top Bar: Back Button `<` & Role Switcher Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _handleBack,
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
                  GestureDetector(
                    onTap: _handleChangeRole,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeRoleLabel,
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Headline: Always "Create Account"
              FadeSlideIn(
                duration: AppDurations.slow,
                slideOffset: 0.04,
                child: Text(
                  'Create Account',
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
                      ? 'Create a password to secure your account.'
                      : subtitle,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (!_showPasswordField) ...[
                // --- STEP 1: Single Email Input (Matching Blacklane Screenshot) ---
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 100),
                  slideOffset: 0.04,
                  child: _buildInputField(
                    controller: _emailController,
                    hintText: 'Email address*',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onContinuePressed(),
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

                const SizedBox(height: 24),

                // Already have an account? Log in
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 180),
                  slideOffset: 0.04,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleSignIn,
                        child: Text(
                          'Log in',
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

                // OR Divider
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
                // --- STEP 2: Password Only (Irrespective of role) ---

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

                // Box 2: Password Input Field (Only password)
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 130),
                  slideOffset: 0.04,
                  child: _buildInputField(
                    controller: _passwordController,
                    hintText: 'Create password*',
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleCreateAccount(),
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
                  ),
                ),

                const SizedBox(height: 18),

                // Terms and Conditions Agreement
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 160),
                  slideOffset: 0.04,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _isChecked,
                          activeColor: cs.primary,
                          checkColor: cs.onPrimary,
                          side: BorderSide(
                            color: cs.outlineVariant,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() => _isChecked = val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isChecked = !_isChecked);
                          },
                          child: Text.rich(
                            TextSpan(
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to Kenick\'s '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Primary "Continue" / "Create Account" Pill Button
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 190),
                  slideOffset: 0.04,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isLoading = auth.isLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleCreateAccount,
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

                // Bottom Login Link
                FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 220),
                  slideOffset: 0.04,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleSignIn,
                        child: Text(
                          'Log in',
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
