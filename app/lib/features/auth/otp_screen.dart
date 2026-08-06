import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/auth_routing_service.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.role, this.email, this.isSignup, this.isPasswordReset});
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
    final otp = _otpController.text;

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
          if (user != null) {
            try {
              await Supabase.instance.client
                  .from('profiles')
                  .update({'role': null})
                  .eq('id', user.id);
            } catch (_) {}
          }
          if (mounted) context.go('/role-selection');
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
        CustomToast.showError(context, auth.errorMessage ?? 'Invalid OTP');
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 40,
      textStyle: tt.titleSmall,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 180),
                Text(
                  'Verify Code',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter the code we just sent to email',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.email ?? 'your email',
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 40),
                Pinput(
                  length: 6,
                  controller: _otpController,
                  focusNode: _focusNode,
                  defaultPinTheme: defaultPinTheme,
                  onCompleted: (pin) => _handleVerify(),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive OTP? ",
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    GestureDetector(
                      onTap: _start == 0
                          ? () async {
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
                                  if (!context.mounted) return;
                                  CustomToast.showSuccess(context, 'OTP resent to ${widget.email}');
                                } catch (e) {
                                  if (!context.mounted) return;
                                  CustomToast.showError(context, 'Failed to resend OTP');
                                }
                              }
                            }
                          : null,
                      child: Text(
                        _start == 0 ? 'Resend code' : 'Resend code in ${_start}s',
                        style: tt.bodySmall?.copyWith(
                          color: _start == 0 ? cs.primary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      title: auth.isLoading ? 'Verifying...' : 'Verify',
                      onPress: auth.isLoading ? () {} : _handleVerify,
                      variant: ButtonVariant.primary,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
