import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

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
    final role = widget.role ?? 'Unassigned';

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
                  padding: const EdgeInsets.fromLTRB(0, 50, 0, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We're glad to have you here! Let's get started.",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey),
                      ),
                      const SizedBox(height: 34),
                      _buildInput(
                        controller: _nameController,
                        hintText: 'Enter your full name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _emailController,
                        hintText: 'Enter your email address',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
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
                      const SizedBox(height: 12),
                      Row(
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
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                              style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.white : AppColors.black),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return CustomButton(
                            title: auth.isLoading ? 'Loading...' : 'Create account',
                            onPress: auth.isLoading ? () {} : _handleCreateAccount,
                            variant: ButtonVariant.primary,
                            height: 40,
                            borderRadius: 25,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          );
                        }
                      ),
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
                          'Already have an account? ',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.white : AppColors.black),
                        ),
                        GestureDetector(
                          onTap: _handleSignIn,
                          child: const Text(
                            'Sign in',
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
              ).animate().fade(duration: 400.ms, delay: 800.ms).slideY(begin: 0.2, end: 0),
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

