import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:klux_vip/theme/app_colors.dart';

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
              ),
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
              ),
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
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Built for refined comfort, smooth movement, and effortless elegance.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 100,
                        child: CustomButton(
                          title: 'Skip',
                          onPress: () => context.push('/role-selection'),
                          variant: ButtonVariant.outline,
                          height: 40,
                          borderRadius: 20,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 30,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 100,
                        child: CustomButton(
                          title: 'Next',
                          onPress: () => context.push('/role-selection'),
                          variant: ButtonVariant.primary,
                          height: 40,
                          borderRadius: 20,
                        ),
                      ),
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
