import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class RidePaymentReceivedScreen extends StatelessWidget {
  const RidePaymentReceivedScreen({super.key});

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
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate back to driver home
                      context.go('/driver-home');
                    },
                    child: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
                  ),
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

              // Amount Received
              Text(
                '\$140 Received',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 16),

              // View payment details
              OutlinedButton(
                onPressed: () {
                  // Could navigate to payment details in future
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'View payment details',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

              Expanded(flex: 2, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}

