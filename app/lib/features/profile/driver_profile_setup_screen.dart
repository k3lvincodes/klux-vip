import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/cloudinary_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverProfileSetupScreen extends StatefulWidget {
  const DriverProfileSetupScreen({super.key});

  @override
  State<DriverProfileSetupScreen> createState() =>
      _DriverProfileSetupScreenState();
}

class _DriverProfileSetupScreenState extends State<DriverProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _dob = '';
  String _gender = '';
  String _country = 'United States';
  bool _isLoading = false;
  File? _pickedImage;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  bool get _isAffiliate {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['role']?.toString().toLowerCase() ==
            'affiliate' ||
        user?.userMetadata?['is_organization'] == true;
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      final String? fullName =
          user.userMetadata?['name'] ?? user.userMetadata?['contact_person'];
      if (fullName != null && fullName.isNotEmpty) {
        final parts = fullName.trim().split(RegExp(r'\s+'));
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _isUploadingImage = true;
    });

    final url = await CloudinaryService.uploadImage(File(picked.path));

    if (mounted) {
      setState(() {
        _isUploadingImage = false;
        _profileImageUrl = url;
      });
      if (url == null) {
        CustomToast.showError(
            context, 'Image upload failed. Please try again.');
      }
    }
  }

  Future<void> _handleContinue() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _dob.isEmpty ||
        _gender.isEmpty ||
        _country.isEmpty) {
      CustomToast.showError(
          context, 'Please fill in all required fields (photo is optional)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'first_name': _firstNameController.text.trim(),
                'last_name': _lastNameController.text.trim(),
                'name':
                    '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                'dob': _dob,
                'gender': _gender,
                'country': _country,
                if (_profileImageUrl != null) 'avatar_url': _profileImageUrl,
              },
            ),
          );
        } catch (_) {}

        await ProfileRepository().createOrUpdateDriverProfile(user.id, {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          if (_profileImageUrl != null) 'avatar_url': _profileImageUrl,
        });
      }
      if (mounted) context.push('/driver-id-verification');
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFD4D4D8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Country',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: isDark ? const Color(0xFF1E2026) : const Color(0xFFF9F8F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                  title: Text(
                    'United States',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  onTap: () {
                    setState(() => _country = 'United States');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGenderPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFD4D4D8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Gender',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 18),
                ..._genders.map((opt) {
                  final isSelected = opt == _gender;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF1E2026) : const Color(0xFFF9F8F6)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: Text(
                        opt,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              size: 22,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() => _gender = opt);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 21)),
      firstDate: DateTime(1930),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (pickerCtx, child) {
        return Theme(
          data: Theme.of(pickerCtx).copyWith(
            colorScheme: Theme.of(pickerCtx).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: const Color(0xFF111827),
                  surface: cs.surface,
                  onSurface: cs.onSurface,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dob =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121316) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : const Color(0xFF18181B),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
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
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorField({
    required String value,
    required String hintText,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final hasValue = value.isNotEmpty;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121316) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hintText,
                style: GoogleFonts.poppins(
                  color: hasValue
                      ? (isDark ? Colors.white : const Color(0xFF18181B))
                      : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A)),
                  fontSize: 14.5,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarUploader(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _isUploadingImage ? null : _pickAndUploadImage,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF4F4F5),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _pickedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _pickedImage!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person_outline_rounded,
                          size: 46,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                ),
                if (_isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF141416) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _pickedImage != null
                          ? Icons.edit_rounded
                          : Icons.camera_alt_rounded,
                      size: 15,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _pickedImage != null ? 'Change photo' : 'Add photo (optional)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title =
        _isAffiliate ? 'Organization Profile' : 'Complete Your Profile';
    final subtitle = _isAffiliate
        ? 'Enter representative and company details to continue.'
        : 'Enter your personal details to continue.';

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
                    const SizedBox(height: 28),

                    // Headline & Subtitle (Poppins editorial scale)
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      slideOffset: 0.04,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 27,
                              letterSpacing: -0.4,
                              color: isDark ? Colors.white : const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Avatar Photo Uploader
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 60),
                      slideOffset: 0.04,
                      child: _buildAvatarUploader(isDark),
                    ),

                    const SizedBox(height: 28),

                    // First Name
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 100),
                      slideOffset: 0.04,
                      child: _buildInputField(
                        controller: _firstNameController,
                        hintText: 'First name*',
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Last Name
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 120),
                      slideOffset: 0.04,
                      child: _buildInputField(
                        controller: _lastNameController,
                        hintText: 'Last name*',
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Date of Birth Selector
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 140),
                      slideOffset: 0.04,
                      child: _buildSelectorField(
                        value: _dob,
                        hintText: 'Date of birth*',
                        onTap: _selectDateOfBirth,
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Gender Selector
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 160),
                      slideOffset: 0.04,
                      child: _buildSelectorField(
                        value: _gender,
                        hintText: 'Gender*',
                        onTap: _showGenderPicker,
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Country Selector (USA only)
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 180),
                      slideOffset: 0.04,
                      child: _buildSelectorField(
                        value: _country,
                        hintText: 'Country of residence*',
                        onTap: _showCountryPicker,
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Pinned Bottom "Continue" Gold Pill CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isLoading
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
                          'Continue',
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
