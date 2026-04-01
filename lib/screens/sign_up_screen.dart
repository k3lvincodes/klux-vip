import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/auth_provider.dart';

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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || !_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and accept terms')));
      return;
    }
    
    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text;
    final role = widget.role ?? 'Passenger';

    final success = await auth.signUp(
      email, 
      _passwordController.text, 
      _nameController.text, 
      role,
    );
    
    if (success) {
      router.push('/otp?role=$role&email=$email&isSignup=true');
    } else {
      messenger.showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Sign up failed')));
    }
  }

  void _handleSignIn() {
    context.push('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFFEBE5E4),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 30, 0, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create an account',
                        style: TextStyle(
                        fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We're glad to have you here! Let's get started.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
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
                              style: const TextStyle(fontSize: 12, color: AppColors.black),
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
                            height: 50,
                            borderRadius: 25,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          );
                        }
                      ),
                      const SizedBox(height: 20),
                      _buildOrContinue(),
                      const SizedBox(height: 18),
                      _buildSocialButtons(),
                      const SizedBox(height: 26),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                            style: TextStyle(fontSize: 12, color: AppColors.black),
                            ),
                            GestureDetector(
                              onTap: _handleSignIn,
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: 160,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrContinue() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or continue with',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withValues(alpha: 0.5),
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
          label: 'f',
          color: const Color(0xFF1877F2),
        ),
        const SizedBox(width: 18),
        _socialButton(
          icon: Icons.apple,
          color: Colors.black,
        ),
      ],
    );
  }

  Widget _socialButton({String? label, IconData? icon, required Color color}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
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
            : Icon(icon, size: 22, color: color),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !isPasswordVisible,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 13),
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
