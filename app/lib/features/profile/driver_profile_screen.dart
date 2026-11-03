import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/models/user_profile.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await ProfileRepository().getDriverProfile(user.id);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF6F6F8),
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
        ),
      );
    }

    final String firstName = _profile?.firstName ?? 'Chauffeur';
    final String lastName = _profile?.lastName ?? '';
    final String? imageUrl = _profile?.avatarUrl;
    final int ratingCount = (_profile?.driverDetails?['rating_count'] as num?)?.toInt() ?? 0;
    final double rawRating = (_profile?.driverDetails?['rating'] as num?)?.toDouble() ?? 0.0;
    final bool hasRating = ratingCount > 0 && rawRating > 0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Circular Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
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
                  Text(
                    'Chauffeur Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Avatar Container with Gold Accent Border
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF4F4F5),
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$firstName $lastName'.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: hasRating ? AppColors.primary : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A)),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasRating ? '${rawRating.toStringAsFixed(1)} ★ ($ratingCount)' : 'New Chauffeur',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: hasRating ? AppColors.primary : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Menu Stage Container (Section 4 & 5)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121316) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile Details',
                            onTap: () => context.push('/driver-edit-profile'),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildMenuItem(
                            icon: Icons.directions_car_outlined,
                            title: 'Vehicle Information',
                            onTap: () => context.push('/vehicle-management'),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildMenuItem(
                            icon: Icons.verified_user_outlined,
                            title: 'ID Verification Documents',
                            onTap: () => context.push('/driver-id-documents'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark ? Colors.white70 : const Color(0xFF18181B),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 52,
      endIndent: 18,
      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
    );
  }
}
