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
  State<IdVerificationDocumentsScreen> createState() => _IdVerificationDocumentsScreenState();
}

class _IdVerificationDocumentsScreenState extends State<IdVerificationDocumentsScreen> {
  bool _isLoading = true;
  UserProfile? _profile;
  String? _overallStatus;
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

        final rawDdVerification = (ddRes?['verification_status'] as String?)?.toLowerCase();
        final rawDdStatus = (ddRes?['status'] as String?)?.toLowerCase();
        final rawProfVerification = (profRes?['verification_status'] as String?)?.toLowerCase() ??
            profile?.verificationStatus?.toLowerCase();

        // 2. Fetch document statuses from driver_documents
        final docs = await Supabase.instance.client
            .from('driver_documents')
            .select('type, status, document_url')
            .eq('driver_id', user.id)
            .filter('deleted_at', 'is', null);

        final docList = (docs as List?) ?? [];
        final hasAnyDeclined = docList.any((d) => d['status'] == 'declined' || d['status'] == 'rejected');
        final allDocsApproved = docList.isNotEmpty && docList.every((d) => d['status'] == 'approved');

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

        // Collect verification image URLs
        final urls = <dynamic>[];
        if (ddRes?['verification_urls'] is List) {
          urls.addAll(ddRes!['verification_urls'] as List);
        } else if (profile?.driverDetails?['verification_urls'] is List) {
          urls.addAll(profile!.driverDetails!['verification_urls'] as List);
        }
        for (final doc in docList) {
          final url = doc['document_url'];
          if (url != null && !urls.contains(url)) urls.add(url);
        }

        if (mounted) {
          setState(() {
            _profile = profile;
            _overallStatus = computedStatus;
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
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.verified;
      case 'declined':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.gpp_bad;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String? status = _overallStatus ??
        _profile?.driverDetails?['verification_status'] as String? ??
        _profile?.verificationStatus;
    final List<dynamic>? verificationUrls = _verificationUrls ?? _profile?.driverDetails?['verification_urls'] as List<dynamic>?;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verification Documents',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _statusIcon(status),
                          size: 64,
                          color: _statusColor(status),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (status == 'declined')
                          Column(
                            children: [
                              Text(
                                'Your verification was declined. Please re-submit your documents.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/driver-id-verification'),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Re-verify'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (status == 'approved')
                          Column(
                            children: [
                              const Icon(Icons.check_circle, size: 32, color: Colors.green),
                              const SizedBox(height: 8),
                              Text(
                                'Your identity has been verified successfully.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else if (status == 'pending')
                          Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 12),
                              Text(
                                'Your documents are being reviewed. This usually takes 1-2 business days.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Text(
                                'You have not completed identity verification yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/driver-id-verification'),
                                  icon: const Icon(Icons.verified_user),
                                  label: const Text('Verify Now'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (verificationUrls != null && verificationUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Uploaded Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...verificationUrls.map((url) => Padding(
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
                            color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                            child: Center(
                              child: Icon(Icons.broken_image, color: Colors.grey.shade500, size: 40),
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ),
    );
  }
}
