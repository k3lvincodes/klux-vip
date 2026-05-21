import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/document_repository.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpScreen extends StatefulWidget {
  final String? role;
  final String? email;
  final bool? isSignup;
  final bool? isPasswordReset;

  const OtpScreen({super.key, this.role, this.email, this.isSignup, this.isPasswordReset});

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
    debugPrint('OTP Verified: $otp');
    
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
      if (mounted) {
        if (widget.isPasswordReset == true) {
          context.go('/new-password');
        } else if (widget.isSignup == true) {
          context.go('/role-selection');
        } else if (widget.role == 'Passenger') {
          final user = auth.currentUser;
          if (user != null) {
            final profile = await ProfileRepository().getPassengerProfile(user.id);
            if (mounted) {
              if (profile == null || profile['first_name'] == null) {
                context.go('/passenger-profile-setup');
              } else {
                context.go('/passenger-home');
              }
            }
          }
        } else if (widget.role == 'Driver' || widget.role == 'Affiliate') {
          final user = auth.currentUser;
          if (user != null) {
            final profile = await ProfileRepository().getDriverProfile(user.id);
            if (mounted) {
              if (profile == null || profile['first_name'] == null) {
                context.go('/driver-profile-setup');
              } else {
                // Check if identity verification has been completed (combined ID + liveness + face match)
                final docRepo = DocumentRepository();
                final idDoc = await docRepo.getDocumentByType(user.id, 'driver_license');
                if (!mounted) return;
                if (idDoc == null) {
                  context.go('/driver-id-verification');
                } else {
                  context.go('/driver-home');
                }
              }
            }
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Demo: Where do you want to go?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Passenger Flow'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/passenger-home');
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Driver Flow'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 180),
              Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the code we just sent to email',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.email ?? 'your email',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              Pinput(
                length: 6,
                controller: _otpController,
                focusNode: _focusNode,
                defaultPinTheme: PinTheme(
                  width: 45,
                  height: 40,
                  textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.black),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
                  ),
                ),
                onCompleted: (pin) => _handleVerify(),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Didn’t receive OTP? '),
                  GestureDetector(
                    onTap: _start == 0 ? () async {
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
                          CustomToast.showSuccess(context, 'OTP resent to ${widget.email}');
                        } catch (e) {
                          CustomToast.showError(context, 'Failed to resend OTP');
                        }
                      }
                    } : null,
                    child: Text(
                      _start == 0 ? 'Resend code' : 'Resend code in ${_start}s',
                      style: TextStyle(
                        color: _start == 0 ? AppColors.primary : Colors.grey,
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
                    height: 39,
                    borderRadius: 20,
                  );
                }
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

