import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';

class PaymentSuccessfulScreen extends StatelessWidget {
  const PaymentSuccessfulScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Padding to center the title
                  ],
                ),
              ),
              
              Expanded(child: SizedBox()),
              
              // Success Icon
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Text
              Text(
                'Payment successful!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Driver on it\'s way!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              
              Expanded(flex: 2, child: SizedBox()),
              
              // Track driver button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: CustomButton(
                  title: 'Track driver',
                  onPress: () {
                    // Navigate to driver tracking screen or return home
                  },
                  variant: ButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

