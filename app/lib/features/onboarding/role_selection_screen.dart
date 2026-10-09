import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final List<Map<String, dynamic>> _roles = [
    {
      'role': 'Client',
      'title': 'Client',
      'icon': Icons.person_outline_rounded,
    },
    {
      'role': 'Chauffeur',
      'title': 'Chauffeur',
      'icon': Icons.directions_car_outlined,
    },
    {
      'role': 'Affiliate',
      'title': 'Affiliate',
      'icon': Icons.business_outlined,
    },
  ];

  String? _loadingRole;

  Future<void> _handleSelectRole(String role) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() => _loadingRole = role);
      final auth = context.read<AuthProvider>();
      final success = await auth.updateUserRole(role);

      if (mounted) {
        setState(() => _loadingRole = null);
        if (success) {
          if (role == 'Client') {
            context.go('/passenger-profile-setup');
          } else {
            context.go('/driver-profile-setup');
          }
        } else {
          CustomToast.showError(
            context,
            auth.errorMessage ?? 'Failed to update role',
          );
        }
      }
    } else {
      context.push('/sign-up?role=$role');
    }
  }

  void _handleBack() {
    if (context.canPop()) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Top Circular Back Button (Matching Sign In page)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: _handleBack,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white,
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

                      // Welcome Accent Divider Line (Matching Welcome page)
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        slideOffset: 0.04,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Get Started',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Container(
                                  height: 1,
                                  color: cs.outlineVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Headline: "Who are you?" (Matching Sign In page typography)
                      FadeSlideIn(
                        duration: AppDurations.slow,
                        delay: const Duration(milliseconds: 60),
                        slideOffset: 0.04,
                        child: Text(
                          'Who are you?',
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
                        delay: const Duration(milliseconds: 100),
                        slideOffset: 0.04,
                        child: Text(
                          'Select how you would like to experience or partner with Kenick VIP.',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 3 Role Pill Buttons (Matching Sign In page 52px pill outline style)
                      ...List.generate(_roles.length, (index) {
                        final item = _roles[index];
                        final role = item['role'] as String;
                        final title = item['title'] as String;
                        final icon = item['icon'] as IconData;
                        final isItemLoading = _loadingRole == role;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: FadeSlideIn(
                            duration: AppDurations.slow,
                            delay: Duration(milliseconds: 140 + (index * 50)),
                            slideOffset: 0.04,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? cs.surfaceContainerHighest
                                        .withValues(alpha: 0.3)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: cs.outlineVariant,
                                  width: 1.5,
                                ),
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isItemLoading
                                      ? null
                                      : () => _handleSelectRole(role),
                                  borderRadius: BorderRadius.circular(26),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: cs.primary
                                                .withValues(alpha: 0.12),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: cs.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (isItemLoading)
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                cs.primary,
                                              ),
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.6),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      const Spacer(),

                      // Bottom Link: Already have an account? Sign in (Matching Sign In page)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: FadeSlideIn(
                          duration: AppDurations.slow,
                          delay: const Duration(milliseconds: 300),
                          slideOffset: 0.04,
                          child: Center(
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
                                  onTap: () => context.go('/sign-in'),
                                  child: Text(
                                    'Sign in',
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
