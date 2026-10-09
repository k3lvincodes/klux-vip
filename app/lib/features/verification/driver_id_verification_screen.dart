import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/repositories/document_repository.dart';
import 'package:kenick_vip/services/didit_verification_service.dart';
import 'package:kenick_vip/services/email_notification_service.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    switch (result) {
      case VerificationCompleted(:final session):
        // 1. Fetch detailed Didit session decision
        final decisionData =
            await _diditService.getSessionDecision(session.sessionId);

        // 2. Determine final status and rejection reason
        String finalStatus;
        String? rejectionReason;

        final sdkStatus = session.status;
        final decisionStatusStr =
            (decisionData?['status'] as String?)?.toLowerCase();

        if (decisionStatusStr == 'approved' ||
            sdkStatus == VerificationStatus.approved) {
          // Strictly validate USA Driver's License (without writing region)
          final docValidation =
              _diditService.validateChauffeurDocument(decisionData);
          if (docValidation['isValid'] == false) {
            finalStatus = 'declined';
            rejectionReason = docValidation['reason'] as String?;
          } else {
            finalStatus = 'approved';
          }
        } else if (decisionStatusStr == 'declined' ||
            sdkStatus == VerificationStatus.declined) {
          finalStatus = 'declined';
          rejectionReason = _diditService.extractRejectionReason(decisionData) ??
              'Your document or liveness check could not be verified by Didit.';
        } else {
          finalStatus = 'pending';
        }

        final extractedImages =
            _diditService.extractDocumentImages(decisionData);

        // 3. Update Database across driver_documents, driver_details, and profiles
        try {
          await _saveDocuments(
            sessionId: session.sessionId,
            diditStatus: finalStatus,
            rejectionReason: rejectionReason,
          );
          await _updateDriverDetails(
            status: finalStatus,
            imageUrls: extractedImages,
          );
          await _updateProfileStatus(finalStatus);
        } catch (e) {
          debugPrint('Error updating database: $e');
        }

        // 4. Send Email notification to user
        _sendResultEmail(
          status: finalStatus,
          rejectionReason: rejectionReason,
        );

        if (mounted) {
          setState(() => _isVerifying = false);
          if (finalStatus == 'approved') {
            CustomToast.showSuccess(
              context,
              'Driver\'s License verified successfully!',
            );
          } else if (finalStatus == 'declined') {
            CustomToast.showError(
              context,
              rejectionReason ?? 'Verification was declined.',
            );
          } else {
            CustomToast.showSuccess(
              context,
              'Verification submitted for automated review.',
            );
          }

          // 5. Navigate user to in-app status page
          context.go('/driver-id-documents');
        }

      case VerificationCancelled():
        if (mounted) {
          setState(() => _isVerifying = false);
          CustomToast.showError(context, 'Verification was cancelled.');
        }

      case VerificationFailed(:final error):
        if (mounted) {
          setState(() => _isVerifying = false);
          CustomToast.showError(context, error.message);
        }
    }
  }

  void _sendResultEmail({
    required String status,
    String? rejectionReason,
  }) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    final name =
        user?.userMetadata?['name'] as String? ?? email ?? 'Chauffeur';
    if (email == null) return;

    if (status == 'approved') {
      _emailService.sendVerificationSuccessEmail(
        toEmail: email,
        userName: name,
      );
    } else if (status == 'declined') {
      _emailService.sendVerificationFailedEmail(
        toEmail: email,
        userName: name,
        reason: rejectionReason,
      );
    }
  }

  Future<void> _saveDocuments({
    required String sessionId,
    required String diditStatus,
    String? rejectionReason,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final docDbStatus = diditStatus == 'approved'
            ? 'approved'
            : diditStatus == 'declined'
                ? 'rejected'
                : 'pending';

        await _documentRepo.uploadDocument(
          driverId: user.id,
          type: 'driver_license',
          fileUrl: 'didit://$sessionId',
          status: docDbStatus,
          rejectionReason: rejectionReason,
        );

        await _documentRepo.uploadDocument(
          driverId: user.id,
          type: 'background_check',
          fileUrl: 'didit://$sessionId',
          status: docDbStatus,
          rejectionReason: rejectionReason,
        );
      }
    } catch (e) {
      debugPrint('Failed to save driver documents: $e');
    }
  }

  Future<void> _updateDriverDetails({
    required String status,
    List<String>? imageUrls,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      String dbStatus = status;
      if (status == 'declined') dbStatus = 'suspended';

      final Map<String, dynamic> updatePayload = {
        'status': dbStatus,
        'verification_status': status,
      };

      if (imageUrls != null && imageUrls.isNotEmpty) {
        updatePayload['verification_urls'] = imageUrls;
      }

      await Supabase.instance.client
          .from('driver_details')
          .update(updatePayload)
          .eq('profile_id', user.id);
    }
  }

  Future<void> _updateProfileStatus(String status) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'verification_status': status})
          .eq('id', user.id);
    }
  }

  Widget _buildStepItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: cs.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Top Bar: Circular `<` Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/role-selection');
                          }
                        },
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

                    const SizedBox(height: 24),

                    // Headline & Subtitle
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      slideOffset: 0.04,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identity Verification',
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              letterSpacing: -0.5,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Verify your USA Driver\'s License to continue.',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Steps Container Card
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 60),
                      slideOffset: 0.04,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 1.2,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            _buildStepItem(
                              icon: Icons.drive_eta_outlined,
                              title: 'Driver\'s License',
                              description:
                                  'Valid USA Driver\'s License.',
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Divider(
                                height: 1,
                                color: cs.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            _buildStepItem(
                              icon: Icons.camera_front_outlined,
                              title: 'Liveness Selfie Scan',
                              description:
                                  'Quick 3D facial scan to confirm your identity.',
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Divider(
                                height: 1,
                                color: cs.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            _buildStepItem(
                              icon: Icons.verified_user_outlined,
                              title: 'Instant Automatic Verification',
                              description:
                                  'Automated approval or denial powered by Didit.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Pinned Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _startVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isVerifying
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
                          'Start Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
