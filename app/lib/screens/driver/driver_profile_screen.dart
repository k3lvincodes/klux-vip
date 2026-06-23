import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String firstName = _profile?.firstName ?? 'Chauffeur';
    final String lastName = _profile?.lastName ?? '';
    final String? imageUrl = _profile?.avatarUrl;
    final double rating = (_profile?.driverDetails?['rating'] ?? 0.0).toDouble();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title:  Text(
          'Chauffeur Profile',
          style: TextStyle(color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD6D6D6),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(Icons.person, size: 50, color: Colors.grey),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.person, size: 50, color: isDark ? AppColors.white : Colors.black54),
                        ),
                      )
                    : Icon(Icons.person, size: 50, color: isDark ? AppColors.white : Colors.black54),
              ),
              const SizedBox(height: 16),
              Text(
                '$firstName $lastName'.trim(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Edit Personal Details',
                onTap: () => context.push('/driver-edit-profile'),
              ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut).slideX(begin: 0.05, end: 0),
              const SizedBox(height: 16),
              _buildProfileOption(
                icon: Icons.directions_car_outlined,
                title: 'Vehicle Information',
                onTap: () => context.push('/vehicle-info'),
              ).animate().fadeIn(delay: 80.ms, duration: 300.ms, curve: Curves.easeOut).slideX(begin: 0.05, end: 0),
              const SizedBox(height: 16),
              _buildProfileOption(
                icon: Icons.badge_outlined,
                title: 'ID Verification Documents',
                onTap: () => context.push('/driver-id-documents'),
              ).animate().fadeIn(delay: 160.ms, duration: 300.ms, curve: Curves.easeOut).slideX(begin: 0.05, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.15),
        highlightColor: AppColors.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark) ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: (Theme.of(context).brightness == Brightness.dark) ? AppColors.white : AppColors.black),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: (Theme.of(context).brightness == Brightness.dark) ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: (Theme.of(context).brightness == Brightness.dark) ? Colors.grey.shade500 : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}


