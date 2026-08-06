import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final List<String> _roles = ['Affiliate', 'Chauffeur', 'Client'];

  @override
  void initState() {
    super.initState();
    _resetRole();
  }

  Future<void> _resetRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': null})
          .eq('id', user.id);
    } catch (_) {}
  }

  Future<void> _handleSelectRole(String role) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.updateUserRole(role);

    if (success && mounted) {
      if (role == 'Client') {
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
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who are you?',
                style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Column(
                children: _roles.map((role) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: CustomButton(
                      title: role,
                      variant: ButtonVariant.outline,
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
