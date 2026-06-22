import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class RidePaymentReceivedScreen extends StatefulWidget {
  const RidePaymentReceivedScreen({super.key});

  @override
  State<RidePaymentReceivedScreen> createState() =>
      _RidePaymentReceivedScreenState();
}

class _RidePaymentReceivedScreenState extends State<RidePaymentReceivedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _ringController;

  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();

    // Scale-up entrance for the success circle
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotating gold ring
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Sparkle particles
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Start the entrance animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _ringController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

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
              // Glassmorphic back button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                  child: PressScale(
                  onTap: () {
                    context.pushReplacement('/rate-client');
                  },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark ? AppColors.white : AppColors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: 100.ms,
                    curve: Curves.easeOut,
                  )
                  .slideX(
                    begin: -0.1,
                    end: 0,
                    duration: 400.ms,
                    delay: 100.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const Expanded(child: SizedBox()),

              // Success icon with gold glow, rotating ring, and sparkles
              ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gold gradient glow behind the circle
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.primary.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Rotating gold ring
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _ringController.value * 2 * pi,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.transparent,
                              width: 2.5,
                            ),
                            gradient: SweepGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.0),
                                AppColors.primary.withValues(alpha: 0.6),
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.6),
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.white,
                            ),
                          ),
                        ),
                      ),

                      // Success circle
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

                      // Sparkle particles
                      ..._buildSparkles(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Amount Received - staggered fade-in
              Text(
                '\$140 Received',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 500.ms,
                    delay: 600.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 500.ms,
                    delay: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 16),

              // View payment details button - staggered fade-in
              PressScale(
                onTap: () {
                  // Could navigate to payment details in future
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
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
              )
                  .animate()
                  .fadeIn(
                    duration: 500.ms,
                    delay: 800.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 500.ms,
                    delay: 800.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds 8 sparkle dots evenly spaced around the circle
  List<Widget> _buildSparkles() {
    const int count = 8;
    const double radius = 90;
    return List.generate(count, (i) {
      final angle = (2 * pi / count) * i;
      final dx = cos(angle) * radius;
      final dy = sin(angle) * radius;

      return AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, child) {
          // Each particle has a phase offset
          final phase = (_sparkleController.value + i / count) % 1.0;
          // Fade in and out over the cycle
          final opacity = (sin(phase * pi * 2) * 0.5 + 0.5).clamp(0.0, 1.0);
          final scale = 0.4 + opacity * 0.6;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      );
    });
  }
}
