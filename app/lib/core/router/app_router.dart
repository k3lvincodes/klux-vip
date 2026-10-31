import 'package:go_router/go_router.dart';
import 'package:kenick_vip/features/auth/forgot_password_screen.dart';
import 'package:kenick_vip/features/auth/new_password_screen.dart';
import 'package:kenick_vip/features/auth/otp_screen.dart';
import 'package:kenick_vip/features/auth/sign_in_screen.dart';
import 'package:kenick_vip/features/auth/sign_up_screen.dart';
import 'package:kenick_vip/features/booking/add_guest_screen.dart';
import 'package:kenick_vip/features/booking/book_journey_screen.dart';
import 'package:kenick_vip/features/booking/booking_selection_screen.dart';
import 'package:kenick_vip/features/booking/confirm_reservation_screen.dart';
import 'package:kenick_vip/features/booking/edit_addresses_screen.dart';
import 'package:kenick_vip/features/booking/instant_booking_screen.dart';
import 'package:kenick_vip/features/booking/passenger_home_screen.dart';
import 'package:kenick_vip/features/booking/ride_history_screen.dart';
import 'package:kenick_vip/features/booking/ride_review_screen.dart';
import 'package:kenick_vip/features/booking/saved_places_screen.dart';
import 'package:kenick_vip/features/booking/schedule_booking_screen.dart';
import 'package:kenick_vip/features/booking/set_pickup_location_screen.dart';
import 'package:kenick_vip/features/booking/special_booking_screen.dart';
import 'package:kenick_vip/features/booking/trip_summary_screen.dart';
import 'package:kenick_vip/features/driver-performance/driver_performance_screen.dart';
import 'package:kenick_vip/features/driver-performance/driver_ride_history_screen.dart';
import 'package:kenick_vip/features/fleet/fleet_selection_screen.dart';
import 'package:kenick_vip/features/legal/legal_information_screen.dart';
import 'package:kenick_vip/features/legal/legal_notice_screen.dart';
import 'package:kenick_vip/features/legal/privacy_policy_screen.dart';
import 'package:kenick_vip/features/legal/terms_of_service_screen.dart';
import 'package:kenick_vip/features/newsfeed/newsfeed_screen.dart';
import 'package:kenick_vip/features/notifications/notifications_screen.dart';
import 'package:kenick_vip/features/onboarding/onboarding_screen.dart';
import 'package:kenick_vip/features/onboarding/role_selection_screen.dart';
import 'package:kenick_vip/features/onboarding/splash_screen.dart';
import 'package:kenick_vip/features/payment/booking_invoice_screen.dart';
import 'package:kenick_vip/features/payment/booking_payment_screen.dart';
import 'package:kenick_vip/features/payment/payment_method_screen.dart';
import 'package:kenick_vip/features/payment/payment_successful_screen.dart';
import 'package:kenick_vip/features/payment/tip_selection_screen.dart';
import 'package:kenick_vip/features/profile/contact_details_screen.dart';
import 'package:kenick_vip/features/profile/driver_edit_profile_screen.dart';
import 'package:kenick_vip/features/profile/driver_profile_screen.dart';
import 'package:kenick_vip/features/profile/driver_profile_setup_screen.dart';
import 'package:kenick_vip/features/profile/edit_email_screen.dart';
import 'package:kenick_vip/features/profile/edit_profile_screen.dart';
import 'package:kenick_vip/features/profile/passenger_profile_screen.dart';
import 'package:kenick_vip/features/profile/passenger_profile_setup_screen.dart';
import 'package:kenick_vip/features/rewards/offers_rewards_screen.dart';
import 'package:kenick_vip/features/ride/active_ride_screen.dart';
import 'package:kenick_vip/features/ride/confirm_arrival_screen.dart';
import 'package:kenick_vip/features/ride/driver_home_screen.dart';
import 'package:kenick_vip/features/ride/end_ride_confirmation_screen.dart';
import 'package:kenick_vip/features/ride/rate_client_screen.dart';
import 'package:kenick_vip/features/ride/ride_payment_received_screen.dart';
import 'package:kenick_vip/features/ride/start_ride_screen.dart';
import 'package:kenick_vip/features/settings/settings_screen.dart';
import 'package:kenick_vip/features/support/call_numbers_screen.dart';
import 'package:kenick_vip/features/support/messages_screen.dart';
import 'package:kenick_vip/features/support/support_screen.dart';
import 'package:kenick_vip/features/support/ticket_detail_screen.dart';
import 'package:kenick_vip/features/support/urgent_support_screen.dart';
import 'package:kenick_vip/features/vehicle/vehicle_info_screen.dart';
import 'package:kenick_vip/features/vehicle/vehicle_management_screen.dart';
import 'package:kenick_vip/features/vehicle/vehicle_registration_screen.dart';
import 'package:kenick_vip/features/verification/driver_id_verification_screen.dart';
import 'package:kenick_vip/features/verification/id_verification_documents_screen.dart';
import 'package:kenick_vip/features/wallet/account_screen.dart';
import 'package:kenick_vip/features/wallet/add_bank_account_screen.dart';
import 'package:kenick_vip/features/wallet/withdraw_method_screen.dart';
import 'package:kenick_vip/features/wallet/withdraw_to_bank_screen.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final location = state.uri.path;

    final publicRoutes = <String>{
      '/', '/onboarding', '/sign-in', '/sign-up', '/forgot-password',
      '/new-password', '/otp', '/role-selection', '/home',
      '/privacy-policy', '/terms-of-service', '/legal-notice', '/legal-information',
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
      path: '/passenger-profile/contact-details',
      builder: (context, state) {
        final extra = state.extra as Map<String, String?>? ?? {};
        return ContactDetailsScreen(
          initialFirstName: extra['first_name'],
          initialLastName:  extra['last_name'],
          initialPhone:     extra['phone_number'],
        );
      },
    ),
    GoRoute(
      path: '/passenger-profile/email',
      builder: (context, state) {
        final extra = state.extra as Map<String, String?>? ?? {};
        return EditEmailScreen(
          initialEmail: extra['email'],
        );
      },
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
      path: '/fleet-selection',
      builder: (context, state) => const FleetSelectionScreen(),
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
      path: '/booking-payment',
      builder: (context, state) => const BookingPaymentScreen(),
    ),
    GoRoute(
      path: '/booking-invoice',
      builder: (context, state) => const BookingInvoiceScreen(),
    ),
    GoRoute(
      path: '/tip-selection',
      builder: (context, state) => const TipSelectionScreen(),
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
      path: '/edit-addresses',
      builder: (context, state) => const EditAddressesScreen(),
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
      path: '/support/messages',
      builder: (context, state) => const MessagesScreen(),
    ),
    GoRoute(
      path: '/support/urgent',
      builder: (context, state) => const UrgentSupportScreen(),
    ),
    GoRoute(
      path: '/support/call',
      builder: (context, state) => const UrgentSupportScreen(),
    ),
    GoRoute(
      path: '/support/call-numbers',
      builder: (context, state) => const CallNumbersScreen(),
    ),
    GoRoute(
      path: '/support/ticket/:id',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return TicketDetailScreen(
          ticketId: state.pathParameters['id']!,
          subject: extra['subject'] as String? ?? '',
          status: extra['status'] as String? ?? 'open',
        );
      },
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
      path: '/id-verification-documents',
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
    GoRoute(
      path: '/legal-information',
      builder: (context, state) => const LegalInformationScreen(),
    ),
    GoRoute(
      path: '/legal-notice',
      builder: (context, state) => const LegalNoticeScreen(),
    ),
    GoRoute(
      path: '/book-journey',
      builder: (context, state) => const BookJourneyScreen(),
    ),
    GoRoute(
      path: '/confirm-reservation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ConfirmReservationScreen(
          category: extra['category'] as String? ?? 'Business Class',
          subtitle: extra['subtitle'] as String? ?? 'Mercedes-Benz EQE or similar',
          fare: (extra['fare'] as num?)?.toDouble() ?? 141.47,
          passengers: (extra['passengers'] as num?)?.toInt() ?? 3,
          luggage: (extra['luggage'] as num?)?.toInt() ?? 2,
          imageUrl: extra['image'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/add-guest',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return AddGuestScreen(
          initialTitle: extra['title'] as String?,
          initialFirstName: extra['first_name'] as String?,
          initialLastName: extra['last_name'] as String?,
          initialEmail: extra['email'] as String?,
          initialPhone: extra['phone_number'] as String?,
          initialDialCode: extra['dial_code'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/offers',
      builder: (context, state) => const OffersRewardsScreen(),
    ),
    GoRoute(
      path: '/newsfeed',
      builder: (context, state) => const NewsfeedScreen(),
    ),
    GoRoute(
      path: '/set-pickup-location',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          return SetPickupLocationScreen(
            initialLocation: map['initialLocation'] as LocationSearchResult?,
            title: map['title'] as String? ?? 'Set pickup location',
            label: map['label'] as String? ?? 'Pickup location',
            confirmButtonText: map['confirmButtonText'] as String? ?? 'Confirm pickup location',
          );
        }
        final initial = state.extra as LocationSearchResult?;
        return SetPickupLocationScreen(initialLocation: initial);
      },
    ),
  ],
);
