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
            darkTheme: _buildDarkTheme(baseTextTheme),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme(TextTheme baseTextTheme) {
    final colorScheme = AppColors.lightColorScheme;
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: colorScheme.onSurface),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: colorScheme.onSurface),
      displaySmall: baseTextTheme.displaySmall?.copyWith(color: colorScheme.onSurface),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: colorScheme.onSurface),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
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
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFFD1D5DB),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 3,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
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

  ThemeData _buildDarkTheme(TextTheme baseTextTheme) {
    final colorScheme = AppColors.darkColorScheme;
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: colorScheme.onSurface),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: colorScheme.onSurface),
      displaySmall: baseTextTheme.displaySmall?.copyWith(color: colorScheme.onSurface),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: colorScheme.onSurface),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
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
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF4B5563),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 3,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
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
