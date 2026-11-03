import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:provider/provider.dart';

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
    final rideProv = context.watch<RideProvider>();
    final rideDetails = rideProv.currentRideDetails;
    final fareAmount = rideDetails?['fare_amount'];
    final displayAmount = fareAmount != null
        ? '\$${(fareAmount as num).toStringAsFixed(2)}'
        : '\$0.00';
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Circular back button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18.0, top: 12.0),
                  child: PressScale(
                    onTap: () {
                      context.pushReplacement('/rate-client');
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E2026) : Colors.white,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE4E4E7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                        size: 16,
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
                                  ? const Color(0xFF141416)
                                  : Colors.white,
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
                            Icons.check_rounded,
                            color: Color(0xFF111827),
                            size: 76,
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
                '$displayAmount Received',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                  letterSpacing: -0.3,
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
              const SizedBox(height: 18),

              // View payment details button - signature gold pill or styled outline
              PressScale(
                onTap: () => context.push('/account'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE4E4E7),
                    ),
                  ),
                  child: Text(
                    'View payment details',
                    style: GoogleFonts.poppins(
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

              const SizedBox(height: 20),

              // Continue to rating CTA button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.pushReplacement('/rate-client'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Rate Client',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 500.ms,
                    delay: 900.ms,
                    curve: Curves.easeOut,
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
