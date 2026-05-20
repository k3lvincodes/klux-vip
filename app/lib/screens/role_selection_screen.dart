import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/custom_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final List<String> _roles = ['Affiliate', 'Driver', 'Passenger'];

  Future<void> _handleSelectRole(String role) async {
    // Call AuthProvider to update role
    final auth = context.read<AuthProvider>();
    final success = await auth.updateUserRole(role);

    if (success && mounted) {
      if (role == 'Passenger') {
        context.push('/passenger-profile-setup');
      } else {
        context.push('/driver-profile-setup');
      }
    } else if (mounted) {
      CustomToast.showError(
        context,
        auth.errorMessage ?? 'Failed to update role',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 40),
              Column(
                children: _roles.map((role) {
                  final isPrimary = role == 'Passenger';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: CustomButton(
                      title: role,
                      variant: isPrimary
                          ? ButtonVariant.primary
                          : ButtonVariant.outline,
                      height: 48,
                      borderRadius: 24,
                      onPress: () => _handleSelectRole(role),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
