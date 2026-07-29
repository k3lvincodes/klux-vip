import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.grey,
                BlendMode.saturation,
              ),
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Image.asset(
                  'assets/images/mobile_1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Gradient overlay — light or dark mode
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black,
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white,
                        ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // "Welcome to Kenick" + horizontal line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Welcome to Kenick',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white70 : AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            height: 1,
                            color: isDark
                                ? Colors.white24
                                : Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms).slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Experience Premium Transportation\nand Black Car Service.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.black,
                      height: 1.4,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),

                  const Spacer(),

                  // Main heading
                  Text(
                    'Your Premium Ride\nAwaits.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.black,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 300.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 14),

                  // Description
                  Text(
                    'Built for refined comfort, smooth movement,\nand effortless elegance.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.grey.shade400 : AppColors.black.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 450.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 40),

                  // Get Started button
                  CustomButton(
                    title: 'Get Started',
                    onPress: () => context.push('/sign-up'),
                    variant: ButtonVariant.primary,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
