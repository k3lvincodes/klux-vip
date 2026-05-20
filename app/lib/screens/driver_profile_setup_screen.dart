import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenick_vip/services/cloudinary_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverProfileSetupScreen extends StatefulWidget {
  const DriverProfileSetupScreen({super.key});

  @override
  State<DriverProfileSetupScreen> createState() => _DriverProfileSetupScreenState();
}

class _DriverProfileSetupScreenState extends State<DriverProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _dob = '';
  String _gender = '';
  String _country = '';
  bool _isLoading = false;
  File? _pickedImage;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

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
      } else {
        CustomToast.showSuccess(context, 'Image uploaded successfully!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 30.0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Personal information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Profile Picture Placeholder
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                        ),
                        child: _pickedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _pickedImage!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person, size: 60, color: Color(0xFFE0E0E0)),
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
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
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
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _pickedImage != null ? Icons.edit : Icons.add,
                            size: 20,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // First Name
              _buildInput(
                controller: _firstNameController,
                hintText: 'First name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              // Last Name
              _buildInput(
                controller: _lastNameController,
                hintText: 'Last name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              // Date of Birth
              _buildSelector(
                hintText: _dob.isEmpty ? 'Date of birth' : _dob,
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dob = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
                  }
                },
              ),
              const SizedBox(height: 20),
              // Gender
              _buildSelector(
                hintText: _gender.isEmpty ? 'Gender' : _gender,
                icon: Icons.wc,
                onTap: () => _showSelectionDialog('Select Gender', ['Male', 'Female', 'Other'], (val) => setState(() => _gender = val)),
                showChevron: true,
              ),
              const SizedBox(height: 20),
              // Country
              _buildSelector(
                hintText: _country.isEmpty ? 'Country of residence' : _country,
                icon: Icons.public_outlined,
                onTap: () => _showSelectionDialog('Select Country', ['United States', 'United Kingdom', 'Canada', 'Australia'], (val) => setState(() => _country = val)),
                showChevron: true,
              ),
              const SizedBox(height: 80),
              CustomButton(
                title: _isLoading ? 'Saving...' : 'Continue',
                onPress: _isLoading ? () {} : _handleContinue,
                variant: ButtonVariant.primary,
                height: 40,
              ),
              const SizedBox(height: 20),
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
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.white : AppColors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
    bool showChevron = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  fontSize: 12,
                  color: hintText.contains(' ') && !hintText.startsWith('Country') 
                      ? const Color(0xFF9CA3AF) 
                      : (isDark ? AppColors.white : AppColors.black),
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: isDark ? AppColors.white : AppColors.black),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _dob.isEmpty ||
        _gender.isEmpty ||
        _country.isEmpty) {
      CustomToast.showError(context, 'Please fill all fields (Image is optional)');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await ProfileRepository().createOrUpdateDriverProfile(user.id, {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'rating': 0.0,
          if (_profileImageUrl != null) 'profile_image_url': _profileImageUrl,
        });
      }
      if (mounted) context.push('/driver-id-verification');
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to save profile');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSelectionDialog(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...options.map((option) => ListTile(
                title: Text(option),
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  onSelect(option);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

