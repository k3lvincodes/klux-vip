import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/document_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _nextRoute;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      _determineNextRoute(),
      Future.delayed(const Duration(milliseconds: 4000)),
    ]);
    if (mounted) {
      context.go(_nextRoute ?? '/onboarding');
    }
  }

  Future<void> _determineNextRoute() async {
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;

      if (user != null) {
        final role = user.userMetadata?['role'];
        if (role == 'Driver' || role == 'Affiliate') {
          final results = await Future.wait([
            ProfileRepository().getDriverProfile(user.id),
            DocumentRepository().getDocumentByType(user.id, 'driver_license'),
          ]);
          final profile = results[0];
          final idDoc = results[1];

          if (profile == null || (profile as Map)['first_name'] == null) {
            _nextRoute = '/driver-profile-setup';
          } else if (idDoc == null) {
            _nextRoute = '/driver-id-verification';
          } else {
            _nextRoute = '/driver-home';
          }
        } else {
          final profile = await ProfileRepository().getPassengerProfile(user.id);
          if (profile == null || profile['first_name'] == null) {
            _nextRoute = '/passenger-profile-setup';
          } else {
            _nextRoute = '/passenger-home';
          }
        }
      }
    } catch (e) {
      _nextRoute = '/onboarding';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = constraints.maxWidth * 0.45;
            return Center(
              child: Image.asset(
                    isDark ? 'assets/images/kenick_logo_transparent_dark.png' : 'assets/images/kenick_logo_transparent_light.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  )
                  .animate()
                  // Grow from tiny to full size with an elastic bounce
                  .scaleXY(
                    begin: 0.01,
                    end: 1.0,
                    duration: 1200.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 800.ms)
                  .then(delay: 400.ms)
                  // First scale bounce
                  .scaleXY(begin: 1.0, end: 1.2, duration: 300.ms, curve: Curves.easeOutQuad)
                  .then()
                  .scaleXY(begin: 1.2, end: 1.0, duration: 300.ms, curve: Curves.bounceOut)
                  .then(delay: 200.ms)
                  // Second scale bounce (smaller)
                  .scaleXY(begin: 1.0, end: 1.1, duration: 250.ms, curve: Curves.easeOutQuad)
                  .then()
                  .scaleXY(begin: 1.1, end: 1.0, duration: 250.ms, curve: Curves.bounceOut)
                  .then(delay: 300.ms)
                  .fadeOut(duration: 400.ms),
            );
          },
        ),
      ),
    );
  }
}
