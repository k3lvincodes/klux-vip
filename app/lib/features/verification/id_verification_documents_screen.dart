import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/user_profile.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IdVerificationDocumentsScreen extends StatefulWidget {
  const IdVerificationDocumentsScreen({super.key});

  @override
  State<IdVerificationDocumentsScreen> createState() =>
      _IdVerificationDocumentsScreenState();
}

class _IdVerificationDocumentsScreenState
    extends State<IdVerificationDocumentsScreen> {
  bool _isLoading = true;
  UserProfile? _profile;
  String? _overallStatus;
  String? _rejectionReason;
  List<dynamic>? _verificationUrls;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await ProfileRepository().getDriverProfile(user.id);

        // 1. Fetch direct chauffeur verification & status from driver_details and profiles
        final ddRes = await Supabase.instance.client
            .from('driver_details')
            .select('verification_status, status, verification_urls')
            .eq('profile_id', user.id)
            .maybeSingle();

        final profRes = await Supabase.instance.client
            .from('profiles')
            .select('verification_status')
            .eq('id', user.id)
            .maybeSingle();

        final rawDdVerification =
            (ddRes?['verification_status'] as String?)?.toLowerCase();
        final rawDdStatus = (ddRes?['status'] as String?)?.toLowerCase();
        final rawProfVerification =
            (profRes?['verification_status'] as String?)?.toLowerCase() ??
                profile?.verificationStatus?.toLowerCase();

        // 2. Fetch document statuses from driver_documents
        final docs = await Supabase.instance.client
            .from('driver_documents')
            .select('type, status, file_url, rejection_reason')
            .eq('driver_id', user.id)
            .filter('deleted_at', 'is', null);

        final docList = (docs as List?) ?? [];
        final hasAnyDeclined = docList.any((d) =>
            d['status'] == 'declined' || d['status'] == 'rejected');
        final allDocsApproved =
            docList.isNotEmpty && docList.every((d) => d['status'] == 'approved');

        String computedStatus;
        if (rawDdVerification == 'approved' ||
            rawDdStatus == 'approved' ||
            rawProfVerification == 'approved' ||
            allDocsApproved) {
          computedStatus = 'approved';
        } else if (rawDdVerification == 'rejected' ||
            rawDdVerification == 'declined' ||
            rawProfVerification == 'rejected' ||
            rawProfVerification == 'declined' ||
            hasAnyDeclined) {
          computedStatus = 'declined';
        } else if (rawDdVerification == 'pending' ||
            rawProfVerification == 'pending' ||
            docList.isNotEmpty) {
          computedStatus = 'pending';
        } else {
          computedStatus = 'unverified';
        }

        // Extract rejection reason if available
        String? reason;
        for (final doc in docList) {
          if (doc['rejection_reason'] != null &&
              doc['rejection_reason'].toString().isNotEmpty) {
            reason = doc['rejection_reason'].toString();
            break;
          }
        }

        // Collect verification image URLs
        final urls = <dynamic>[];
        if (ddRes?['verification_urls'] is List) {
          urls.addAll(ddRes!['verification_urls'] as List);
        } else if (profile?.driverDetails?['verification_urls'] is List) {
          urls.addAll(profile!.driverDetails!['verification_urls'] as List);
        }
        for (final doc in docList) {
          final url = doc['file_url'];
          if (url != null &&
              url.toString().startsWith('http') &&
              !urls.contains(url)) {
            urls.add(url);
          }
        }

        if (mounted) {
          setState(() {
            _profile = profile;
            _overallStatus = computedStatus;
            _rejectionReason = reason;
            _verificationUrls = urls;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomToast.showError(context, 'Failed to load verification status');
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'declined':
        return const Color(0xFFDC2626);
      case 'pending':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.verified_rounded;
      case 'declined':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.gpp_maybe_rounded;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'declined':
        return 'Declined';
      case 'pending':
        return 'Pending Review';
      default:
        return 'Not Verified';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String status = _overallStatus ??
        _profile?.driverDetails?['verification_status'] as String? ??
        _profile?.verificationStatus ??
        'unverified';

    final List<dynamic>? verificationUrls = _verificationUrls ??
        _profile?.driverDetails?['verification_urls'] as List<dynamic>?;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadProfile,
                color: cs.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Circular Back Arrow Button
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/driver-home');
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

                      const SizedBox(height: 20),

                      Text(
                        'Verification Status',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Automated Didit identity compliance check.',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Primary Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
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
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor(status)
                                    .withValues(alpha: 0.12),
                              ),
                              child: Icon(
                                _statusIcon(status),
                                size: 36,
                                color: _statusColor(status),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(status),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            if (status == 'approved') ...[
                              Text(
                                'USA Driver\'s License Verified',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your identity has been successfully verified. You can now proceed to register your luxury vehicle.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.push('/vehicle-registration'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    'Continue to Vehicle Registration',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (status == 'declined') ...[
                              Text(
                                'Verification Declined',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your submitted verification could not be approved.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                              if (_rejectionReason != null &&
                                  _rejectionReason!.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFDC2626)
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: Color(0xFFDC2626),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _rejectionReason!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFFDC2626),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      context.push('/driver-id-verification'),
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  label: const Text(
                                    'Re-verify Driver\'s License',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (status == 'pending') ...[
                              Text(
                                'Verification Under Review',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Didit is automatically analyzing your USA Driver\'s License and facial scan. Results will update shortly.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _loadProfile,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Refresh Status'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.onSurface,
                                    side: BorderSide(color: cs.outlineVariant),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Verification Required',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chauffeurs must complete automated identity verification with a valid USA Driver\'s License.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.push('/driver-id-verification'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    'Start Verification',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Specification Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERIFICATION DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildDetailRow(
                              title: 'Accepted Document',
                              value: 'USA Driver\'s License',
                              cs: cs,
                            ),
                            _buildDivider(cs),
                            _buildDetailRow(
                              title: 'Issuance',
                              value: 'USA',
                              cs: cs,
                            ),
                            _buildDivider(cs),
                            _buildDetailRow(
                              title: 'Verification Engine',
                              value: 'Didit Automated KYC',
                              cs: cs,
                            ),
                            _buildDivider(cs),
                            _buildDetailRow(
                              title: 'Notifications',
                              value: 'In-app & Email',
                              cs: cs,
                            ),
                          ],
                        ),
                      ),

                      if (verificationUrls != null &&
                          verificationUrls.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Scanned Assets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...verificationUrls.map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: url as String,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 180,
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 180,
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.grey.shade200,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey.shade500,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    required ColorScheme cs,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
