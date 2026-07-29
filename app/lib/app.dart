import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/core/router/app_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/theme_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/overlays/biometric_lock_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

enum _LockTier { none, soft, hard }

class KenickVipApp extends StatefulWidget {
  const KenickVipApp({super.key});

  @override
  State<KenickVipApp> createState() => _KenickVipAppState();
}

class _KenickVipAppState extends State<KenickVipApp>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isLocked = false;
  bool _faceIdEnabled = false;
  bool _canAuthenticate = false;
  DateTime? _backgroundedAt;
  _LockTier _lockTier = _LockTier.none;
  late final AnimationController _lockOverlayController;

  static const Duration _shortLockThreshold = Duration(minutes: 2);
  static const Duration _mediumLockThreshold = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockOverlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadBiometricPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockOverlayController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      if (_faceIdEnabled) {
        setState(() => _isLocked = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked && _faceIdEnabled && _backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        if (elapsed < _shortLockThreshold) {
          _unlockImmediately();
        } else if (elapsed < _mediumLockThreshold) {
          setState(() => _lockTier = _LockTier.soft);
          _lockOverlayController.forward();
        } else {
          setState(() => _lockTier = _LockTier.hard);
          _lockOverlayController.forward();
        }
      }
      _backgroundedAt = null;
    }
  }

  void _unlockImmediately() {
    setState(() {
      _isLocked = false;
      _lockTier = _LockTier.none;
    });
    _lockOverlayController.reset();
  }

  void _handleUnlocked() {
    _lockOverlayController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _lockTier = _LockTier.none;
        });
      }
    });
  }

  void _handleSoftDismiss() {
    _lockOverlayController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _lockTier = _LockTier.none;
        });
      }
    });
  }

  Future<void> _loadBiometricPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('face_id_enabled') ?? false;
    final localAuth = LocalAuthentication();
    final canAuth = enabled && await localAuth.canCheckBiometrics;
    if (mounted) {
      setState(() {
        _faceIdEnabled = enabled;
        _canAuthenticate = canAuth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    );

    return ToastificationWrapper(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Kenick',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              final auth = context.watch<AuthProvider>();
              final isLoggedIn = auth.currentUser != null;

              return Stack(
                children: [
                  child!,
                  if (_isLocked && isLoggedIn)
                    AnimatedBuilder(
                      animation: _lockOverlayController,
                      builder: (context, _) {
                        final opacity = _lockOverlayController.value;
                        return Opacity(
                          opacity: opacity,
                          child: AbsorbPointer(
                            absorbing: opacity < 0.95,
                            child: BiometricLockScreen(
                              canAuthenticate: _canAuthenticate,
                              lockMode: _lockTier == _LockTier.soft
                                  ? LockMode.soft
                                  : LockMode.hard,
                              onUnlocked: _handleUnlocked,
                              onSoftDismiss: _lockTier == _LockTier.soft
                                  ? _handleSoftDismiss
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
            theme: _buildLightTheme(baseTextTheme),
            darkTheme: _buildDarkTheme(),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme(TextTheme baseTextTheme) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
      ),
      useMaterial3: true,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F0EF),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SmoothPageTransitionBuilder(),
          TargetPlatform.iOS: _SmoothPageTransitionBuilder(),
          TargetPlatform.windows: _SmoothPageTransitionBuilder(),
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.darkSurface,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SmoothPageTransitionBuilder(),
          TargetPlatform.iOS: _SmoothPageTransitionBuilder(),
          TargetPlatform.windows: _SmoothPageTransitionBuilder(),
        },
      ),
    );
  }
}

class _SmoothPageTransitionBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: AppCurves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppCurves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
