import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klux_vip/screens/driver_profile_setup_screen.dart';
import 'package:klux_vip/screens/driver_selfie_screen.dart';
import 'package:klux_vip/screens/driver/account_screen.dart';
import 'package:klux_vip/screens/driver/active_ride_screen.dart';
import 'package:klux_vip/screens/driver/add_bank_account_screen.dart';
import 'package:klux_vip/screens/driver/confirm_arrival_screen.dart';
import 'package:klux_vip/screens/driver/driver_home_screen.dart';
import 'package:klux_vip/screens/driver/end_ride_confirmation_screen.dart';
import 'package:klux_vip/screens/driver/ride_payment_received_screen.dart';
import 'package:klux_vip/screens/driver/start_ride_screen.dart';
import 'package:klux_vip/screens/driver/withdraw_method_screen.dart';
import 'package:klux_vip/screens/driver/withdraw_to_bank_screen.dart';
import 'package:klux_vip/screens/onboarding_screen.dart';
import 'package:klux_vip/screens/passenger/add_card_screen.dart';
import 'package:klux_vip/screens/passenger/booking_selection_screen.dart';
import 'package:klux_vip/screens/passenger/instant_booking_screen.dart';
import 'package:klux_vip/screens/passenger/passenger_home_screen.dart';
import 'package:klux_vip/screens/passenger/payment_method_screen.dart';
import 'package:klux_vip/screens/passenger/payment_successful_screen.dart';
import 'package:klux_vip/screens/passenger/schedule_booking_screen.dart';
import 'package:klux_vip/screens/passenger/special_booking_screen.dart';
import 'package:klux_vip/screens/passenger/trip_summary_screen.dart';
import 'package:klux_vip/screens/otp_screen.dart';
import 'package:klux_vip/screens/passenger_profile_setup_screen.dart';
import 'package:klux_vip/screens/forgot_password_screen.dart';
import 'package:klux_vip/screens/new_password_screen.dart';
import 'package:klux_vip/screens/role_selection_screen.dart';
import 'package:klux_vip/screens/sign_in_screen.dart';
import 'package:klux_vip/screens/sign_up_screen.dart';
import 'package:klux_vip/screens/splash_screen.dart';
import 'package:klux_vip/theme/app_colors.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/auth_provider.dart';
import 'package:klux_vip/providers/ride_provider.dart';
import 'package:klux_vip/providers/payment_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: '.env');

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
      ],
      child: const KluxVipApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
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
        final isPasswordReset = state.uri.queryParameters['isPasswordReset'] == 'true';
        return OtpScreen(role: role, email: email, isSignup: isSignup, isPasswordReset: isPasswordReset);
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
      path: '/driver-selfie',
      builder: (context, state) => const DriverSelfieScreen(),
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
      path: '/add-card',
      builder: (context, state) => const AddCardScreen(),
    ),
    GoRoute(
      path: '/payment-successful',
      builder: (context, state) => const PaymentSuccessfulScreen(),
    ),
    // Driver Flow
    GoRoute(
      path: '/driver-home',
      builder: (context, state) => const DriverHomeScreen(),
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
    // Account & Withdraw Flow
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
  ],
);

class KluxVipApp extends StatelessWidget {
  const KluxVipApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return ToastificationWrapper(
      child: MaterialApp.router(
      title: 'Klux VIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: baseTextTheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.black),
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F0EF),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: _router,
    ),
    );
  }
}
