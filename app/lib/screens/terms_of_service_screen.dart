import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                'Terms of Service',
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
                '1. Acceptance of Terms',
                'By accessing or using Klux VIP, you agree to be bound by these Terms of Service. If you do not agree to all the terms, you may not access or use the service.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '2. Description of Service',
                'Klux VIP provides a platform connecting passengers with drivers for on-demand transportation services. We facilitate the booking and payment process but are not a transportation carrier.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '3. User Accounts',
                'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '4. Chauffeur Obligations',
                'Chauffeurs must maintain valid licenses, insurance, and vehicle registration. Chauffeurs are independent contractors and not employees of Klux VIP.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '5. Payment Terms',
                'Fares are calculated based on distance, time, and applicable surge pricing. Payments are processed through our secure payment gateway. All transactions are in the local currency.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '6. Limitation of Liability',
                'Klux VIP shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the service.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                isDark,
                '7. Termination',
                'We reserve the right to suspend or terminate your access to the service at any time, without prior notice, for conduct that we believe violates these terms or is harmful to other users.',
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
