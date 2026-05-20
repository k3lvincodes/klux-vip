import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Privacy Center',
          style: TextStyle(color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Last updated: May 2026',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                isDark,
                '1. Information We Collect',
                'We collect information you provide directly to us, such as when you create or modify your account, request on-demand services, contact customer support, or otherwise communicate with us. This information may include: name, email, phone number, profile picture, payment method, and other information you choose to provide.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '2. How We Use Information',
                'We may use the information we collect about you to: Provide, maintain, and improve our services; Perform internal operations; Send you communications; Personalize and improve the services.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '3. Location Information',
                'When you use our services for transportation, we collect precise location data from the app running in the foreground or background of your device to help match you with drivers, calculate fares, and provide support.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '4. Sharing of Information',
                'We may share the information we collect about you with drivers to enable them to provide the services you request. For example, we share your name, pickup and drop-off locations with the driver.',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(bool isDark, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
