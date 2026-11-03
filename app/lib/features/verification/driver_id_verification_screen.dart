import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/repositories/document_repository.dart';
import 'package:kenick_vip/services/didit_verification_service.dart';
import 'package:kenick_vip/services/email_notification_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
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
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.primary,
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
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
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
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1E2026) : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE4E4E7),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: isDark ? Colors.white : const Color(0xFF18181B),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Headline & Subtitle (Poppins scale)
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      slideOffset: 0.04,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identity Verification',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 27,
                              letterSpacing: -0.4,
                              color: isDark ? Colors.white : const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Verify your USA Driver\'s License to continue.',
                            style: GoogleFonts.poppins(
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                              fontSize: 14.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Steps Stage Card (Section 5.3)
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 60),
                      slideOffset: 0.04,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF121316) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFE4E4E7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildStepItem(
                              icon: Icons.drive_eta_outlined,
                              title: 'Driver\'s License',
                              description: 'Valid USA Driver\'s License.',
                              isDark: isDark,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Divider(
                                height: 1,
                                thickness: 0.8,
                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                              ),
                            ),
                            _buildStepItem(
                              icon: Icons.camera_front_outlined,
                              title: 'Liveness Selfie Scan',
                              description:
                                  'Quick 3D facial scan to confirm your identity.',
                              isDark: isDark,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Divider(
                                height: 1,
                                thickness: 0.8,
                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                              ),
                            ),
                            _buildStepItem(
                              icon: Icons.verified_user_outlined,
                              title: 'Instant Automatic Verification',
                              description:
                                  'Automated approval or denial powered by Didit.',
                              isDark: isDark,
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

            // Pinned Bottom Gold Pill CTA Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _startVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF111827),
                            ),
                          ),
                        )
                      : Text(
                          'Start Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            letterSpacing: 0.1,
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
