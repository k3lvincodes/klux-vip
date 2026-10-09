import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/cloudinary_service.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerProfileSetupScreen extends StatefulWidget {
  const PassengerProfileSetupScreen({super.key});

  @override
  State<PassengerProfileSetupScreen> createState() =>
      _PassengerProfileSetupScreenState();
}

class _PassengerProfileSetupScreenState
    extends State<PassengerProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _gender = '';
  String _country = 'United States';
  String _travelPreferences = 'No preference';
  bool _isLoading = false;
  File? _pickedImage;
  String? _profileImageUrl;
  bool _isUploadingImage = false;


  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<Map<String, String>> _preferences = [
    {'label': 'Quiet ride', 'icon': '🤫'},
    {'label': 'Chatty', 'icon': '💬'},
    {'label': 'Music playing', 'icon': '🎵'},
    {'label': 'No preference', 'icon': '🙌'},
  ];

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

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      final String? fullName = user.userMetadata?['name'];
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
                'gender': _gender,
                'country': _country,
                'travel_preferences': _travelPreferences,
                if (_profileImageUrl != null) 'avatar_url': _profileImageUrl,
              },
            ),
          );
        } catch (_) {}

        await ProfileRepository().createOrUpdatePassengerProfile(user.id, {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          if (_profileImageUrl != null) 'avatar_url': _profileImageUrl,
        });
      }
      if (mounted) context.go('/passenger-home');
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCountryPicker() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Select Country',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: cs.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                  title: Text(
                    'United States',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  trailing: Icon(
                    Icons.check_circle_rounded,
                    color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Select Gender',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ..._genders.map((opt) {
                  final isSelected = opt == _gender;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: isSelected
                          ? cs.primary.withValues(alpha: 0.1)
                          : cs.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: Text(
                        opt,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: cs.primary,
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

  void _showTravelPreferencesPicker() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Travel Preferences',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ..._preferences.map((pref) {
                  final label = pref['label']!;
                  final icon = pref['icon']!;
                  final isSelected = label == _travelPreferences;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: isSelected
                          ? cs.primary.withValues(alpha: 0.1)
                          : cs.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      leading: Text(icon, style: const TextStyle(fontSize: 20)),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: cs.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: cs.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() => _travelPreferences = label);
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: cs.outlineVariant,
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: cs.outlineVariant,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: cs.primary,
              width: 1.8,
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
  }) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = value.isNotEmpty;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap();
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outlineVariant,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hintText,
                style: TextStyle(
                  color: hasValue
                      ? cs.onSurface
                      : cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: cs.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarUploader() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTap: _isUploadingImage ? null : _pickAndUploadImage,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerLowest,
                    border: Border.all(
                      color: cs.outlineVariant,
                      width: 1.5,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: _pickedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _pickedImage!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person_outline_rounded,
                          size: 44,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                ),
                if (_isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: cs.primary,
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? cs.surface : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _pickedImage != null
                          ? Icons.edit_rounded
                          : Icons.camera_alt_rounded,
                      size: 14,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _pickedImage != null ? 'Change photo' : 'Add photo (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                    const SizedBox(height: 32),

                    // Headline & Subtitle
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      slideOffset: 0.04,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Your Profile',
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              letterSpacing: -0.5,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your personal details to continue.',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Avatar Photo Uploader
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 60),
                      slideOffset: 0.04,
                      child: _buildAvatarUploader(),
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
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Gender Selector
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 140),
                      slideOffset: 0.04,
                      child: _buildSelectorField(
                        value: _gender,
                        hintText: 'Gender*',
                        onTap: _showGenderPicker,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Country Selector (USA only)
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 160),
                      slideOffset: 0.04,
                      child: _buildSelectorField(
                        value: _country,
                        hintText: 'Country of residence*',
                        onTap: _showCountryPicker,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Travel Preferences Selector
                    FadeSlideIn(
                      duration: AppDurations.slow,
                      delay: const Duration(milliseconds: 180),
                      slideOffset: 0.04,
                      child: _buildSelectorField(
                        value: _travelPreferences,
                        hintText: 'Travel preferences',
                        onTap: _showTravelPreferencesPicker,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Pinned Bottom "Continue" Pill Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isLoading
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
                          'Continue',
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
