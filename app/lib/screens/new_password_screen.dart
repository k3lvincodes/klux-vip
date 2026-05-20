import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      CustomToast.showError(context, 'Please fill all fields');
      return;
    }

    if (password != confirm) {
      CustomToast.showError(context, 'Passwords do not match');
      return;
    }

    if (password.length < 6) {
      CustomToast.showError(context, 'Password must be at least 6 characters');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.updatePassword(password);
    
    if (success && mounted) {
      CustomToast.showSuccess(context, 'Password updated successfully!');
      context.go('/sign-in'); // Return to sign in
    } else if (mounted) {
      CustomToast.showError(context, auth.errorMessage ?? 'Failed to update password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Set New Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // New Password Input
              _buildPasswordInput(
                controller: _passwordController,
                hintText: 'New Password',
                isObscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),

              // Confirm Password Input
              _buildPasswordInput(
                controller: _confirmController,
                hintText: 'Confirm Password',
                isObscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 40),

              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return CustomButton(
                    title: auth.isLoading ? 'Updating...' : 'Update Password',
                    onPress: auth.isLoading ? () {} : _handleUpdatePassword,
                    variant: ButtonVariant.primary,
                    height: 40,
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String hintText,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
              controller: controller,
              obscureText: isObscure,
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.white : AppColors.black),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: onToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

