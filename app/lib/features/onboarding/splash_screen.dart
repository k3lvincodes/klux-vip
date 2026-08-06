import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/services/auth_routing_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final AnimationController _ringController;
  late final Animation<double> _ringAngle;
  String? _nextRoute;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );
    _scaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _ringAngle = Tween<double>(begin: 0, end: 5 * math.pi * 2).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );
    _ringController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    final auth = context.read<AuthProvider>();

    final warmLaunch = auth.isInitialized;
    if (warmLaunch) {
      _resolveImmediately(auth);
      return;
    }

    _controller.forward();
    await _determineNextRoute();

    if (!mounted || _resolved) return;
    await _controller.forward(from: _controller.value);

    if (mounted && !_resolved) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted && !_resolved) _navigate();
    }
  }

  void _resolveImmediately(AuthProvider auth) {
    _resolved = true;
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) context.go('/onboarding');
      return;
    }
    final role = user.userMetadata?['role'];
    if (role == null) {
      if (mounted) context.go('/role-selection');
      return;
    }
    if (role == 'Chauffeur' || role == 'Affiliate') {
      if (mounted) context.go('/driver-home');
    } else {
      if (mounted) context.go('/passenger-home');
    }
  }

  Future<void> _determineNextRoute() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.restoreSession();
      final user = auth.currentUser;

      if (user != null) {
        final routingService = AuthRoutingService();
        _nextRoute = await routingService.determineRouteForUser(user);
      }
    } catch (e) {
      _nextRoute = '/onboarding';
    }
  }

  void _navigate() {
    if (_nextRoute != null && mounted) {
      context.go(_nextRoute!);
    } else if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [cs.surface, Colors.black]
                : [cs.primaryContainer, cs.surface],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.scale(
                  scale: _scaleIn.value,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ringAngle,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(120, 120),
                              painter: _GlowingRingPainter(
                                angle: _ringAngle.value,
                                color: cs.primary,
                              ),
                            );
                          },
                        ),
                        Image.asset(
                          isDark
                              ? 'assets/images/kenick_logo_transparent_dark.png'
                              : 'assets/images/kenick_logo_transparent_light.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlowingRingPainter extends CustomPainter {
  _GlowingRingPainter({required this.angle, required this.color});
  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const sweep = 0.7;

    for (int i = 3; i >= 0; i--) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + (3 - i) * 3.0
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, (3 - i) * 2.0 + 1.0)
        ..color = color.withValues(alpha: 0.08 * (4 - i));

      canvas.drawArc(rect, angle + i * 0.15, sweep - i * 0.1, false, paint);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, angle, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_GlowingRingPainter old) => old.angle != angle;
}
