import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Terms of Service',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
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
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Last updated: May 2026',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                '1. Acceptance of Terms',
                'By accessing or using Klux VIP, you agree to be bound by these Terms of Service. If you do not agree to all the terms, you may not access or use the service.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '2. Description of Service',
                'Klux VIP provides a platform connecting passengers with drivers for on-demand transportation services. We facilitate the booking and payment process but are not a transportation carrier.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '3. User Accounts',
                'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '4. Chauffeur Obligations',
                'Chauffeurs must maintain valid licenses, insurance, and vehicle registration. Chauffeurs are independent contractors and not employees of Klux VIP.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '5. Payment Terms',
                'Fares are calculated based on distance, time, and applicable surge pricing. Payments are processed through our secure payment gateway. All transactions are in the local currency.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '6. Limitation of Liability',
                'Klux VIP shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the service.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
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

  Widget _buildSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
