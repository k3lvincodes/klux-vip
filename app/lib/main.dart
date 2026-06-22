import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/screens/driver_profile_setup_screen.dart';
import 'package:kenick_vip/screens/driver_id_verification_screen.dart';
import 'package:kenick_vip/screens/driver/account_screen.dart';
import 'package:kenick_vip/screens/driver/active_ride_screen.dart';
import 'package:kenick_vip/screens/driver/add_bank_account_screen.dart';
import 'package:kenick_vip/screens/driver/confirm_arrival_screen.dart';
import 'package:kenick_vip/screens/driver/driver_home_screen.dart';
import 'package:kenick_vip/screens/driver/end_ride_confirmation_screen.dart';
import 'package:kenick_vip/screens/driver/ride_payment_received_screen.dart';
import 'package:kenick_vip/screens/driver/start_ride_screen.dart';
import 'package:kenick_vip/screens/driver/withdraw_method_screen.dart';
import 'package:kenick_vip/screens/driver/withdraw_to_bank_screen.dart';
import 'package:kenick_vip/screens/onboarding_screen.dart';
import 'package:kenick_vip/screens/passenger/booking_selection_screen.dart';
import 'package:kenick_vip/screens/passenger/instant_booking_screen.dart';
import 'package:kenick_vip/screens/passenger/passenger_home_screen.dart';
import 'package:kenick_vip/screens/passenger/payment_method_screen.dart';
import 'package:kenick_vip/screens/passenger/payment_successful_screen.dart';
import 'package:kenick_vip/screens/passenger/schedule_booking_screen.dart';
import 'package:kenick_vip/screens/passenger/special_booking_screen.dart';
import 'package:kenick_vip/screens/passenger/ride_history_screen.dart';
import 'package:kenick_vip/screens/passenger/saved_places_screen.dart';
import 'package:kenick_vip/screens/passenger/notifications_screen.dart';
import 'package:kenick_vip/screens/settings_screen.dart';
import 'package:kenick_vip/screens/support_screen.dart';
import 'package:kenick_vip/screens/vehicle_registration_screen.dart';
import 'package:kenick_vip/screens/ride_review_screen.dart';
import 'package:kenick_vip/screens/driver/driver_ride_history_screen.dart';
import 'package:kenick_vip/screens/driver/vehicle_management_screen.dart';
import 'package:kenick_vip/screens/driver/driver_performance_screen.dart';
import 'package:kenick_vip/screens/driver/rate_client_screen.dart';
import 'package:kenick_vip/screens/passenger/trip_summary_screen.dart';
import 'package:kenick_vip/screens/passenger/passenger_profile_screen.dart';
import 'package:kenick_vip/screens/driver/driver_profile_screen.dart';
import 'package:kenick_vip/screens/driver/driver_edit_profile_screen.dart';
import 'package:kenick_vip/screens/driver/vehicle_info_screen.dart';
import 'package:kenick_vip/screens/driver/id_verification_documents_screen.dart';
import 'package:kenick_vip/screens/passenger/edit_profile_screen.dart';
import 'package:kenick_vip/screens/privacy_policy_screen.dart';
import 'package:kenick_vip/screens/terms_of_service_screen.dart';
import 'package:kenick_vip/screens/otp_screen.dart';
import 'package:kenick_vip/screens/passenger_profile_setup_screen.dart';
import 'package:kenick_vip/screens/forgot_password_screen.dart';
import 'package:kenick_vip/screens/new_password_screen.dart';
import 'package:kenick_vip/screens/role_selection_screen.dart';
import 'package:kenick_vip/screens/sign_in_screen.dart';
import 'package:kenick_vip/screens/sign_up_screen.dart';
import 'package:kenick_vip/screens/splash_screen.dart';
import 'package:kenick_vip/theme/app_colors.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kenick_vip/providers/theme_provider.dart';
import 'package:kenick_vip/widgets/biometric_lock_screen.dart';
import 'package:local_auth/local_auth.dart';

enum _LockTier { none, soft, hard }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('${details.exception}');
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const KenickVipApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final location = state.uri.path;

    final publicRoutes = <String>{
      '/', '/onboarding', '/sign-in', '/sign-up', '/forgot-password',
      '/new-password', '/otp', '/role-selection', '/home',
      '/privacy-policy', '/terms-of-service',
    };

    if (session == null && !publicRoutes.contains(location)) {
      return '/onboarding';
    }

    if (location == '/home') {
      if (session == null) return '/onboarding';
      final role = session.user.userMetadata?['role'];
      if (role == 'Chauffeur' || role == 'Affiliate') {
        return '/driver-home';
      }
      return '/passenger-home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'];
        return SignUpScreen(role: role);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/new-password',
      builder: (context, state) => const NewPasswordScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'];
        final email = state.uri.queryParameters['email'];
        final isSignup = state.uri.queryParameters['isSignup'] == 'true';
        final isPasswordReset =
            state.uri.queryParameters['isPasswordReset'] == 'true';
        return OtpScreen(
          role: role,
          email: email,
          isSignup: isSignup,
          isPasswordReset: isPasswordReset,
        );
      },
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/driver-profile-setup',
      builder: (context, state) => const DriverProfileSetupScreen(),
    ),
    GoRoute(
      path: '/passenger-profile-setup',
      builder: (context, state) => const PassengerProfileSetupScreen(),
    ),
    GoRoute(
      path: '/passenger-profile',
      builder: (context, state) => const PassengerProfileScreen(),
    ),
    GoRoute(
      path: '/driver-id-verification',
      builder: (context, state) => const DriverIdVerificationScreen(),
    ),
    GoRoute(
      path: '/vehicle-registration',
      builder: (context, state) => const VehicleRegistrationScreen(),
    ),
    GoRoute(
      path: '/ride-review',
      builder: (context, state) {
        final rideId = state.uri.queryParameters['rideId']!;
        final revieweeId = state.uri.queryParameters['revieweeId']!;
        final revieweeName = state.uri.queryParameters['revieweeName']!;
        return RideReviewScreen(
          rideId: rideId,
          revieweeId: revieweeId,
          revieweeName: revieweeName,
        );
      },
    ),
    GoRoute(
      path: '/passenger-home',
      builder: (context, state) => const PassengerHomeScreen(),
    ),
    GoRoute(
      path: '/booking-selection',
      builder: (context, state) => const BookingSelectionScreen(),
    ),
    GoRoute(
      path: '/instant-booking',
      builder: (context, state) => const InstantBookingScreen(),
    ),
    GoRoute(
      path: '/schedule-booking',
      builder: (context, state) => const ScheduleBookingScreen(),
    ),
    GoRoute(
      path: '/special-booking',
      builder: (context, state) => const SpecialBookingScreen(),
    ),
    GoRoute(
      path: '/trip-summary',
      builder: (context, state) => const TripSummaryScreen(),
    ),
    GoRoute(
      path: '/payment-method',
      builder: (context, state) => const PaymentMethodScreen(),
    ),

    GoRoute(
      path: '/payment-successful',
      builder: (context, state) => const PaymentSuccessfulScreen(),
    ),
    GoRoute(
      path: '/ride-history',
      builder: (context, state) => const RideHistoryScreen(),
    ),
    GoRoute(
      path: '/saved-places',
      builder: (context, state) => const SavedPlacesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/driver-home',
      builder: (context, state) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: '/driver-profile',
      builder: (context, state) => const DriverProfileScreen(),
    ),
    GoRoute(
      path: '/confirm-arrival',
      builder: (context, state) => const ConfirmArrivalScreen(),
    ),
    GoRoute(
      path: '/start-ride',
      builder: (context, state) => const StartRideScreen(),
    ),
    GoRoute(
      path: '/active-ride',
      builder: (context, state) => const ActiveRideScreen(),
    ),
    GoRoute(
      path: '/end-ride-confirmation',
      builder: (context, state) => const EndRideConfirmationScreen(),
    ),
    GoRoute(
      path: '/ride-payment-received',
      builder: (context, state) => const RidePaymentReceivedScreen(),
    ),
    GoRoute(
      path: '/rate-client',
      builder: (context, state) => const RateClientScreen(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/withdraw-method',
      builder: (context, state) => const WithdrawMethodScreen(),
    ),
    GoRoute(
      path: '/add-bank-account',
      builder: (context, state) => const AddBankAccountScreen(),
    ),
    GoRoute(
      path: '/withdraw-to-bank',
      builder: (context, state) => const WithdrawToBankScreen(),
    ),
    GoRoute(
      path: '/driver-ride-history',
      builder: (context, state) => const DriverRideHistoryScreen(),
    ),
    GoRoute(
      path: '/vehicle-management',
      builder: (context, state) => const VehicleManagementScreen(),
    ),
    GoRoute(
      path: '/driver-performance',
      builder: (context, state) => const DriverPerformanceScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/driver-edit-profile',
      builder: (context, state) => const DriverEditProfileScreen(),
    ),
    GoRoute(
      path: '/vehicle-info',
      builder: (context, state) => const VehicleInfoScreen(),
    ),
    GoRoute(
      path: '/driver-id-documents',
      builder: (context, state) => const IdVerificationDocumentsScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
  ],
);

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
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
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
            ),
            darkTheme: ThemeData(
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
                  borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
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
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
