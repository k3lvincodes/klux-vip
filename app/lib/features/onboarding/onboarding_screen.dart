import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Welcome to Kenick',
                        style: tt.bodyLarge?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            height: 1,
                            color: cs.outlineVariant,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms).slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Experience Premium Transportation\nand Black Car Service.',
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),
                  const Spacer(),
                  Text(
                    'Your Premium Ride\nAwaits.',
                    style: tt.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 300.ms).slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 14),
                  Text(
                    'Built for refined comfort, smooth movement,\nand effortless elegance.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ).animate().fade(duration: 600.ms, delay: 450.ms).slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 40),
                  CustomButton(
                    title: 'Get Started',
                    onPress: () => context.push('/sign-up'),
                    variant: ButtonVariant.primary,
                    textStyle: tt.labelLarge,
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
