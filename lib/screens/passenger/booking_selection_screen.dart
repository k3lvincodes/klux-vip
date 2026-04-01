import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';

class BookingSelectionScreen extends StatelessWidget {
  const BookingSelectionScreen({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
                  onPressed: () => context.pop(),
                ),
              ),
              const Expanded(child: SizedBox()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomButton(
                  title: 'Instant Booking',
                  onPress: () {
                    context.push('/instant-booking');
                  },
                  variant: ButtonVariant.primary,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomButton(
                  title: 'Schedule Booking',
                  onPress: () {
                    context.push('/schedule-booking');
                  },
                  variant: ButtonVariant.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomButton(
                  title: 'Special Booking Request',
                  onPress: () {
                    context.push('/special-booking');
                  },
                  variant: ButtonVariant.secondary,
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
