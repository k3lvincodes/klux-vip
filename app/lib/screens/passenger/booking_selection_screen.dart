import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';

class BookingSelectionScreen extends StatelessWidget {
  const BookingSelectionScreen({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header like My Profile
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'Book a Ride',
                  style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
              ),

              const Spacer(),

              // Buttons section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    CustomButton(
                      title: 'Instant Booking',
                      onPress: () {
                        context.push('/instant-booking');
                      },
                      variant: ButtonVariant.primary,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      title: 'Schedule Booking',
                      onPress: () {
                        context.push('/schedule-booking');
                      },
                      variant: ButtonVariant.secondary,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      title: 'Special Booking Request',
                      onPress: () {
                        context.push('/special-booking');
                      },
                      variant: ButtonVariant.outline,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
