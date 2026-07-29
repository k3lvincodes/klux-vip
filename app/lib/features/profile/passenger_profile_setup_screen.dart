import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/cloudinary_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerProfileSetupScreen extends StatefulWidget {
  const PassengerProfileSetupScreen({super.key});

  @override
  State<PassengerProfileSetupScreen> createState() => _PassengerProfileSetupScreenState();
}

class _PassengerProfileSetupScreenState extends State<PassengerProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _gender = '';
  String _country = '';
  String _travelPreferences = '';
  bool _isLoading = false;
  File? _pickedImage;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  final List<String> _countries = [
    'Nigeria', 'Ghana', 'South Africa', 'Kenya', 'Egypt',
    'United States', 'United Kingdom', 'Canada', 'Australia',
    'Germany', 'France', 'Italy', 'Spain', 'Netherlands',
    'United Arab Emirates', 'Saudi Arabia', 'Qatar', 'South Korea',
    'Japan', 'China', 'India', 'Brazil', 'Mexico',
  ];

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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
        CustomToast.showError(context, 'Image upload failed. Please try again.');
      }
    }
  }

  Future<void> _handleContinue() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _gender.isEmpty ||
        _country.isEmpty ||
        _travelPreferences.isEmpty) {
      CustomToast.showError(context, 'Please fill all fields (Image is optional)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    String filter = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = _countries.where((c) =>
                c.toLowerCase().contains(filter.toLowerCase())).toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 12,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Select Country',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: searchController,
                          onChanged: (v) => setSheetState(() => filter = v),
                          decoration: InputDecoration(
                            hintText: 'Search countries...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            icon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, size: 20),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No countries found',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final country = filtered[i];
                                  final isSelected = country == _country;
                                  return ListTile(
                                    dense: true,
                                    title: Row(
                                      children: [
                                        Text(
                                          _flagFor(country),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          country,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isDark ? AppColors.white : AppColors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                                        : null,
                                    onTap: () {
                                      setState(() => _country = country);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _flagFor(String country) {
    const flags = {
      'Nigeria': '🇳🇬', 'Ghana': '🇬🇭', 'South Africa': '🇿🇦', 'Kenya': '🇰🇪', 'Egypt': '🇪🇬',
      'United States': '🇺🇸', 'United Kingdom': '🇬🇧', 'Canada': '🇨🇦', 'Australia': '🇦🇺',
      'Germany': '🇩🇪', 'France': '🇫🇷', 'Italy': '🇮🇹', 'Spain': '🇪🇸', 'Netherlands': '🇳🇱',
      'United Arab Emirates': '🇦🇪', 'Saudi Arabia': '🇸🇦', 'Qatar': '🇶🇦', 'South Korea': '🇰🇷',
      'Japan': '🇯🇵', 'China': '🇨🇳', 'India': '🇮🇳', 'Brazil': '🇧🇷', 'Mexico': '🇲🇽',
    };
    return flags[country] ?? '🌍';
  }

  void _showPickerSheet(String title, List<String> options, Function(String) onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final isSelected = (title == 'Select Gender' && opt == _gender) ||
                      (title == 'Select Preferences' && opt == _travelPreferences);
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : null,
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.white : AppColors.black),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                        : null,
                    onTap: () {
                      onSelect(opt);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tell us a bit about yourself',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.darkBackground : Colors.white,
                          ),
                          child: _pickedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _pickedImage!,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                                ),
                        ),
                      ),
                      if (_isUploadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            _pickedImage != null ? Icons.edit : Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              _buildInput(
                controller: _firstNameController,
                hintText: 'First name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _buildInput(
                controller: _lastNameController,
                hintText: 'Last name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _buildSelector(
                value: _gender,
                hintText: 'Gender',
                icon: Icons.wc,
                onTap: () => _showPickerSheet(
                  'Select Gender',
                  _genders,
                  (val) => setState(() => _gender = val),
                ),
              ),
              const SizedBox(height: 14),
              _buildSelector(
                value: _country,
                hintText: 'Country of residence',
                icon: Icons.public_outlined,
                onTap: _showCountryPicker,
              ),
              const SizedBox(height: 14),
              _buildSelector(
                value: _travelPreferences,
                hintText: 'Travel preferences',
                icon: Icons.flight_takeoff_outlined,
                onTap: () => _showPickerSheet(
                  'Select Preferences',
                  _preferences.map((p) => p['label']!).toList(),
                  (val) => setState(() => _travelPreferences = val),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: CustomButton(
                  title: _isLoading ? 'Setting up...' : 'Continue',
                  onPress: _isLoading ? () {} : _handleContinue,
                  variant: ButtonVariant.primary,
                  height: 48,
                  borderRadius: 16,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String value,
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap();
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hasValue ? value : hintText,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue
                      ? (isDark ? AppColors.white : AppColors.black)
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
