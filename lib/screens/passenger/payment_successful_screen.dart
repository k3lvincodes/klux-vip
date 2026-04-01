import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';

class PaymentSuccessfulScreen extends StatelessWidget {
  const PaymentSuccessfulScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0B3), Color(0xFFF3EDEC)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
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
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Padding to center the title
                  ],
                ),
              ),
              
              const Expanded(child: SizedBox()),
              
              // Success Icon
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Text
              const Text(
                'Payment successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Driver on it\'s way!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              
              const Expanded(flex: 2, child: SizedBox()),
              
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
