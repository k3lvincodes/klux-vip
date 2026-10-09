import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/auth_routing_service.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.role,
    this.email,
    this.isSignup,
    this.isPasswordReset,
  });

  final String? role;
  final String? email;
  final bool? isSignup;
  final bool? isPasswordReset;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _start = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _start = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      CustomToast.showError(context, 'Please enter all 6 digits');
      return;
    }

    if (widget.email == null) {
      CustomToast.showError(context, 'Email not found');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(
      widget.email!,
      otp,
      isSignup: widget.isSignup ?? false,
      isPasswordReset: widget.isPasswordReset ?? false,
    );

    if (success) {
      if (widget.isPasswordReset != true) {
        final user = auth.currentUser;
        if (user != null) {
          await ProfileRepository().markEmailVerified(user.id);
        }
      }
      if (mounted) {
        if (widget.isPasswordReset == true) {
          context.go('/new-password');
        } else if (widget.isSignup == true) {
          final user = auth.currentUser;
          final role = widget.role ?? (user?.userMetadata?['role'] as String?);
          if (user != null && role != null) {
            try {
              final dbRole =
                  (role.toLowerCase() == 'client') ? 'client' : 'chauffeur';
              final updates = <String, dynamic>{'role': dbRole};
              final phone = user.userMetadata?['phone_number'];
              if (phone != null && phone.toString().isNotEmpty) {
                updates['phone_number'] = phone;
              }
              await Supabase.instance.client
                  .from('profiles')
                  .update(updates)
                  .eq('id', user.id);
            } catch (_) {}
          }
          if (mounted) {
            if (role?.toLowerCase() == 'client') {
              context.go('/passenger-profile-setup');
            } else if (role?.toLowerCase() == 'chauffeur' ||
                role?.toLowerCase() == 'affiliate') {
              context.go('/driver-profile-setup');
            } else {
              context.go('/role-selection');
            }
          }
        } else if (widget.role != null && widget.role != 'signup') {
          final user = auth.currentUser;
          if (user != null && mounted) {
            final routingService = AuthRoutingService();
            final route = await routingService.determineRouteForUser(user);
            if (mounted) context.go(route);
          }
        } else {
          _showDemoRoleSelection();
        }
      }
    } else {
      if (mounted) {
        CustomToast.showError(context, auth.errorMessage ?? 'Invalid OTP code');
      }
    }
  }

  Future<void> _handleResend() async {
    if (widget.email != null) {
      try {
        final supabase = Supabase.instance.client;
        if (widget.isPasswordReset == true) {
          await supabase.auth.resetPasswordForEmail(widget.email!);
        } else {
          await supabase.auth.resend(
            type: widget.isSignup == true ? OtpType.signup : OtpType.magiclink,
            email: widget.email,
          );
        }
        _startTimer();
        if (!mounted) return;
        CustomToast.showSuccess(
            context, 'Verification code resent to ${widget.email}');
      } catch (e) {
        if (!mounted) return;
        CustomToast.showError(context, 'Failed to resend verification code');
      }
    }
  }

  void _showDemoRoleSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Demo: Where do you want to go?',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Client Flow'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/passenger-home');
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Chauffeur Flow'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver-home');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: tt.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant,
          width: 1.2,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.primary,
          width: 1.8,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Top Bar: Back Button `<`
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
                        color: isDark ? Colors.transparent : cs.outlineVariant,
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

              // Headline: "Verify Email"
              FadeSlideIn(
                duration: AppDurations.slow,
                slideOffset: 0.04,
                child: Text(
                  'Verify Email',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    letterSpacing: -0.5,
                    color: cs.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle with Email Display
              FadeSlideIn(
                duration: AppDurations.slow,
                delay: const Duration(milliseconds: 60),
                slideOffset: 0.04,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please enter the 6-digit code we sent to:',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.email ?? 'your email',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 6-digit Pinput Code Field
              FadeSlideIn(
                duration: AppDurations.slow,
                delay: const Duration(milliseconds: 100),
                slideOffset: 0.04,
                child: Center(
                  child: Pinput(
                    length: 6,
                    controller: _otpController,
                    focusNode: _focusNode,
                    autofocus: true,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    onCompleted: (_) => _handleVerify(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Primary "Continue" / "Verify" Pill Button
              FadeSlideIn(
                duration: AppDurations.slow,
                delay: const Duration(milliseconds: 140),
                slideOffset: 0.04,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final isLoading = auth.isLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleVerify,
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
                                'Verify',
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

              const SizedBox(height: 24),

              // Resend Code Link (Matching design system)
              FadeSlideIn(
                duration: AppDurations.slow,
                delay: const Duration(milliseconds: 180),
                slideOffset: 0.04,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive a code? ",
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: _start == 0 ? _handleResend : null,
                      child: Text(
                        _start == 0 ? 'Resend' : 'Resend in ${_start}s',
                        style: tt.bodyMedium?.copyWith(
                          color: _start == 0 ? cs.primary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration:
                              _start == 0 ? TextDecoration.underline : null,
                          decorationColor: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
