import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFAE3), Color(0xFFFFED92)],
          ),
        ),
        child: Stack(
          children: [
            // Yellow Circle Decoration
            Positioned(
              top: 176,
              left: 25,
              child: Container(
                width: 189,
                height: 189,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE55C),
                ),
              ).animate().fade(duration: 800.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),
            ),

            // Car Image
            Positioned(
              top: 20,
              left: 40,
              child: SizedBox(
                width: width * 1.2,
                height: 300,
                child: Image.asset(
                  'assets/images/car.png',
                  fit: BoxFit.contain,
                ),
              ).animate().fade(duration: 800.ms, delay: 200.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut),
            ),

            // Text and Button Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  const Text(
                    'Enjoy a luxury ride!',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.normal,
                      color: AppColors.black,
                      height: 1.2,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  const Text(
                    'Built for refined comfort, smooth movement, and effortless elegance.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 110),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 100,
                        child: CustomButton(
                          title: 'Next',
                          onPress: () => context.push('/sign-up'),
                          variant: ButtonVariant.primary,
                          height: 40,
                          borderRadius: 20,
                        ),
                      ).animate().fade(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
