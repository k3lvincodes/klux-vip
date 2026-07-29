import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';

class PaymentSuccessfulScreen extends StatefulWidget {
  const PaymentSuccessfulScreen({super.key});

  @override
  State<PaymentSuccessfulScreen> createState() =>
      _PaymentSuccessfulScreenState();
}

class _PaymentSuccessfulScreenState extends State<PaymentSuccessfulScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Scale-up entrance for the check circle
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Pulsing gold ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start entrance
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
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
              // Header with glassmorphic back button
              Padding(
                padding:
                    const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                child: Row(
                  children: [
                    PressScale(
                      onTap: () => context.pop(),
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
                    Expanded(
                      child: Center(
                        child: Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44), // Balance the back button width
                  ],
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: 100.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: -0.08,
                    end: 0,
                    duration: 400.ms,
                    delay: 100.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const Expanded(child: SizedBox()),

              // Success icon with pulsing gold ring
              ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gold gradient glow
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.25),
                              AppColors.primary.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Pulsing gold ring
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 2.5,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Payment successful text - staggered
              Text(
                'Payment successful!',
                style: TextStyle(
                  fontSize: 11,
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
              const SizedBox(height: 12),

              // Subtitle - staggered
              const Text(
                'Chauffeur on it\'s way!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 500.ms,
                    delay: 750.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 500.ms,
                    delay: 750.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const Expanded(flex: 2, child: SizedBox()),

              // Track chauffeur button with shimmer sweep
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                child: CustomButton(
                  title: 'Track chauffeur',
                  onPress: () => context.go('/passenger-home'),
                  variant: ButtonVariant.primary,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 500.ms,
                    delay: 900.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 500.ms,
                    delay: 900.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .then(delay: 300.ms)
                  .shimmer(
                    duration: 1200.ms,
                    color: Colors.white.withValues(alpha: 0.15),
                    angle: 0.5,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

