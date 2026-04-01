import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';

class DriverSelfieScreen extends StatelessWidget {
  const DriverSelfieScreen({super.key});

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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Take a selfie',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildInstructionItem('Take a clear picture of you in good light'),
              const SizedBox(height: 16),
              _buildInstructionItem('No filters, sunglasses, or masks'),
              const Spacer(flex: 2),
              // Face Scan Icon Placeholder
              Center(
                child: Icon(
                  Icons.face_retouching_natural,
                  size: 200,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(flex: 3),
              CustomButton(
                title: 'Take picture',
                onPress: () => context.go('/driver-home'),
                variant: ButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check, size: 14, color: AppColors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.black,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
