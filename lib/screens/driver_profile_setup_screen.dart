import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';

class DriverProfileSetupScreen extends StatefulWidget {
  const DriverProfileSetupScreen({super.key});

  @override
  State<DriverProfileSetupScreen> createState() => _DriverProfileSetupScreenState();
}

class _DriverProfileSetupScreenState extends State<DriverProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final String _dob = '';
  final String _gender = '';
  final String _country = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBE5E4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 30),
              // Profile Picture Placeholder
              Center(
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
                      child: const Icon(Icons.person, size: 60, color: Color(0xFFE0E0E0)),
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
                        child: const Icon(Icons.add, size: 20, color: AppColors.white),
                      ),
                    ),
                  ],
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
                onTap: () {},
              ),
              const SizedBox(height: 20),
              // Gender
              _buildSelector(
                hintText: _gender.isEmpty ? 'Gender' : _gender,
                icon: Icons.wc,
                onTap: () {},
                showChevron: true,
              ),
              const SizedBox(height: 20),
              // Country
              _buildSelector(
                hintText: _country.isEmpty ? 'Country of residence' : _country,
                icon: Icons.public_outlined,
                onTap: () {},
                showChevron: true,
              ),
              const SizedBox(height: 20),
              // Upload documents
              _buildSelector(
                hintText: 'Upload documents',
                icon: Icons.description_outlined,
                onTap: _showDocumentsBottomSheet,
              ),
              const SizedBox(height: 40),
              CustomButton(
                title: 'Continue',
                onPress: _handleContinue,
                variant: ButtonVariant.primary,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
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
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  color: hintText.contains(' ') && !hintText.startsWith('Country') 
                      ? const Color(0xFF9CA3AF) 
                      : AppColors.black,
                ),
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: AppColors.black),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    context.push('/driver-selfie');
  }

  void _showDocumentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF3F4F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDocumentItem('License'),
              const SizedBox(height: 12),
              _buildDocumentItem('Vehicle registration'),
              const SizedBox(height: 12),
              _buildDocumentItem('Insurance'),
              const SizedBox(height: 12),
              _buildDocumentItem('ID', showChevron: true),
              const SizedBox(height: 24),
              CustomButton(
                title: 'Done',
                onPress: () => Navigator.pop(context),
                variant: ButtonVariant.primary,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentItem(String title, {bool showChevron = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE5E4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black)),
          if (showChevron) const Icon(Icons.chevron_right, size: 16, color: Colors.black),
        ],
      ),
    );
  }
}
