import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/cloudinary_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverEditProfileScreen extends StatefulWidget {
  const DriverEditProfileScreen({super.key});

  @override
  State<DriverEditProfileScreen> createState() => _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState extends State<DriverEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _profileImageUrl;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      final file = File(pickedFile.path);
      final url = await CloudinaryService.uploadImage(file);
      if (mounted) {
        setState(() => _isUploadingImage = false);
        if (url != null) {
          setState(() => _profileImageUrl = url);
          CustomToast.showSuccess(context, 'Image uploaded! Press Save Changes to update your profile.');
        } else {
          CustomToast.showError(context, 'Failed to upload image.');
        }
      }
    }
  }

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
        if (profile != null && mounted) {
          _firstNameController.text = profile.firstName ?? '';
          _lastNameController.text = profile.lastName ?? '';
          _profileImageUrl = profile.avatarUrl;
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(context, 'Failed to load profile');
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await ProfileRepository().createOrUpdateDriverProfile(
          user.id,
          {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            if (_profileImageUrl != null) 'avatar_url': _profileImageUrl,
          },
        );
        if (mounted) {
          CustomToast.showSuccess(context, 'Profile updated successfully');
          context.pop(true);
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(context, 'Failed to update profile');
        }
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    'Edit Profile Details',
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF4F4F5),
                                      border: Border.all(color: AppColors.primary, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: _profileImageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Icon(
                                                Icons.person_rounded,
                                                size: 50,
                                                color: isDark ? Colors.white54 : Colors.black45,
                                              ),
                                              errorWidget: (context, url, error) => Icon(
                                                Icons.person_rounded,
                                                size: 50,
                                                color: isDark ? Colors.white54 : Colors.black45,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_rounded,
                                            size: 50,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _isUploadingImage ? null : _pickAndUploadImage,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _isUploadingImage
                                              ? (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8))
                                              : AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF141416) : Colors.white,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: _isUploadingImage
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF111827),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.camera_alt_rounded,
                                                color: Color(0xFF111827),
                                                size: 16,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Inputs
                            _buildInputField(
                              controller: _firstNameController,
                              label: 'First Name',
                              icon: Icons.person_outline_rounded,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              icon: Icons.person_outline_rounded,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 40),

                            // Signature Gold Pill Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: const Color(0xFF111827),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF111827),
                                        ),
                                      )
                                    : Text(
                                        'Save Changes',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF111827),
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white : const Color(0xFF18181B),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF121316) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
