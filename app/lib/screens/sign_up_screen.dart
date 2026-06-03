import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class SignUpScreen extends StatefulWidget {
  final String? role;

  const SignUpScreen({super.key, this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isChecked = false;

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || !_isChecked) {
      CustomToast.showError(context, 'Please fill all fields and accept terms');
      return;
    }
    
    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    final email = _emailController.text.trim();
    final role = widget.role ?? '';

    final success = await auth.signUp(
      email, 
      _passwordController.text, 
      _nameController.text.trim(), 
      role,
    );
    
    if (success) {
      router.push('/otp?email=$email&isSignup=true');
    } else {
      if (mounted) {
        CustomToast.showError(context, auth.errorMessage ?? 'Sign up failed');
      }
    }
  }

  void _handleSignIn() {
    context.push('/sign-in');
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 60, 0, 120),
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
                              'Create account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                color: isDark ? AppColors.white : AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Let's get you started",
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 80),
                        slideOffset: 0.04,
                        child: _buildInput(
                          controller: _nameController,
                          hintText: 'Full name',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 120),
                        slideOffset: 0.04,
                        child: _buildInput(
                          controller: _emailController,
                          hintText: 'Email address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 160),
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
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 200),
                        slideOffset: 0.04,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _isChecked,
                              onChanged: (value) {
                                setState(() {
                                  _isChecked = value ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text.rich(
                                  TextSpan(
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: AppColors.primary,
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
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 240),
                        slideOffset: 0.04,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return CustomButton(
                              title: auth.isLoading ? 'Creating account...' : 'Create account',
                              onPress: auth.isLoading ? () {} : _handleCreateAccount,
                              variant: ButtonVariant.primary,
                              height: 48,
                              borderRadius: 14,
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            );
                          }
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 280),
                        slideOffset: 0.04,
                        child: _buildOrContinue(isDark),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 320),
                        slideOffset: 0.04,
                        child: _buildSocialButtons(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: FadeSlideIn(
                  duration: AppDurations.slow,
                  delay: const Duration(milliseconds: 400),
                  slideOffset: 0.06,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleSignIn,
                        child: Text(
                          'Sign in',
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

  Widget _buildOrContinue(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or continue with',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
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
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
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
                fillColor: isDark ? AppColors.darkSurface : AppColors.white,
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

