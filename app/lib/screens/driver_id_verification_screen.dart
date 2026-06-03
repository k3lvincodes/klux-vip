import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/services/didit_verification_service.dart';
import 'package:kenick_vip/services/email_notification_service.dart';
import 'package:kenick_vip/repositories/document_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:didit_sdk/sdk_flutter.dart';

class DriverIdVerificationScreen extends StatefulWidget {
  const DriverIdVerificationScreen({super.key});

  @override
  State<DriverIdVerificationScreen> createState() =>
      _DriverIdVerificationScreenState();
}

class _DriverIdVerificationScreenState
    extends State<DriverIdVerificationScreen> {
  bool _isVerifying = false;
  final DiditVerificationService _diditService = DiditVerificationService();
  final DocumentRepository _documentRepo = DocumentRepository();
  final EmailNotificationService _emailService = EmailNotificationService();

  Future<void> _startVerification() async {
    setState(() => _isVerifying = true);

    final user = Supabase.instance.client.auth.currentUser;

    VerificationResult? result;
    try {
      result = await _diditService.verifyIdentity(
        vendorData: user?.id,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        CustomToast.showError(context, 'Verification failed to start: $e');
      }
      return;
    }

    if (!mounted) return;

    setState(() => _isVerifying = false);

    switch (result) {
      case VerificationCompleted(:final session):
        switch (session.status) {
          case VerificationStatus.approved:
            try {
              await _saveDocuments(session.sessionId);
              await _updateVerificationStatus('approved');
              _sendResultEmail(isSuccess: true);
              if (mounted) {
                CustomToast.showSuccess(context, 'Identity verified successfully!');
                context.go('/vehicle-registration');
              }
            } catch (_) {}
          case VerificationStatus.pending:
            try {
              await _saveDocuments(session.sessionId);
              await _updateVerificationStatus('pending');
              if (mounted) {
                CustomToast.showSuccess(
                  context,
                  'Verification submitted. You will be updated when the result is out.',
                );
                context.go('/vehicle-registration');
              }
            } catch (_) {}
          case VerificationStatus.declined:
            await _updateVerificationStatus('declined');
            _sendResultEmail(isSuccess: false);
            if (mounted) {
              CustomToast.showError(
                context,
                'Identity verification declined. Please try again.',
              );
            }
        }
      case VerificationCancelled():
        if (mounted) {
          CustomToast.showError(context, 'Verification cancelled.');
        }
      case VerificationFailed(:final error):
        _sendResultEmail(isSuccess: false);
        if (mounted) {
          CustomToast.showError(context, error.message);
        }
    }
  }

  void _sendResultEmail({required bool isSuccess}) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    final name = user?.userMetadata?['name'] as String? ?? email ?? 'Chauffeur';
    if (email == null) return;
    if (isSuccess) {
      _emailService.sendVerificationSuccessEmail(toEmail: email, userName: name);
    } else {
      _emailService.sendVerificationFailedEmail(toEmail: email, userName: name);
    }
  }

  Future<void> _saveDocuments(String sessionId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _documentRepo.uploadDocument(
          driverId: user.id,
          type: 'driver_license',
          fileUrl: 'didit://$sessionId',
        );
        await _documentRepo.uploadDocument(
          driverId: user.id,
          type: 'background_check',
          fileUrl: 'didit://$sessionId',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to save documents. Please try again.');
      }
      rethrow;
    }
  }

  Future<void> _updateVerificationStatus(String status) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      String dbStatus = status;
      if (status == 'declined') dbStatus = 'suspended';
      
      await Supabase.instance.client
          .from('driver_details')
          .update({'status': dbStatus})
          .eq('profile_id', user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.black,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Identity Verification',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'You will be guided through a secure process to verify your ID, take a selfie, and confirm your identity.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 80,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'ID Scan + Selfie + Face Match',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.white : AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A single combined verification powered by Didit.\nFully encrypted and secure.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isVerifying)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              if (!_isVerifying)
                CustomButton(
                  title: 'Start Verification',
                  onPress: _startVerification,
                  variant: ButtonVariant.primary,
                  height: 48,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
