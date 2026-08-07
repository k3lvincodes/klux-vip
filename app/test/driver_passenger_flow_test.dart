import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/features/booking/booking_selection_screen.dart';
import 'package:kenick_vip/features/booking/passenger_home_screen.dart';
import 'package:kenick_vip/features/ride/driver_home_screen.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/providers/theme_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/app_test_harness.dart';

Map<String, dynamic> completedRideJson({
  String id = 'ride-completed-1',
  double fare = 55.0,
}) {
  return {
    'id': id,
    'passenger_id': 'test-user-id-123',
    'driver_id': 'test-user-id-123',
    'pickup_location': 'POINT(-122.08 37.42)',
    'dropoff_location': 'POINT(-122.07 37.43)',
    'pickup_address': '123 Pickup St',
    'dropoff_address': '456 Dropoff Ave',
    'status': 'completed',
    'type': 'instant',
    'fare_amount': fare,
    'created_at': '2026-07-01T10:00:00.000Z',
    'updated_at': '2026-07-01T11:00:00.000Z',
  };
}

void main() {
  tearDown(() async {
    if (Supabase.instance.isInitialized) {
      await Supabase.instance.dispose();
    }
  });

  testWidgets('Passenger home renders and opens the location dialog',
      (tester) async {
    await initTestSupabase(FakeBackend());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RideProvider()),
          ChangeNotifierProvider(create: (_) => PaymentProvider()),
          ChangeNotifierProvider(create: (_) => BookingProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: AppColors.lightColorScheme, useMaterial3: true),
          home: const PassengerHomeScreen(),
        ),
      ),
    );

    // Give async profile/location fetches a chance to resolve.
    await tester.pump(const Duration(milliseconds: 300));

    // Passenger home core UI renders.
    expect(find.text('Choose pickup & destination'), findsOneWidget);
    expect(find.text('Select ride'), findsOneWidget);
    expect(find.text('Book ride'), findsOneWidget);

    // Select a vehicle card.
    await tester.tap(find.text('GMC Yukon'));
    await tester.pump();

    // Open the location dialog.
    await tester.tap(find.text('Choose pickup & destination'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Plan your ride'), findsOneWidget);
    expect(find.text('Confirm Route'), findsOneWidget);
  });

  testWidgets('Passenger Book ride navigates to booking selection',
      (tester) async {
    await initTestSupabase(FakeBackend());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RideProvider()),
          ChangeNotifierProvider(create: (_) => PaymentProvider()),
          ChangeNotifierProvider(create: (_) => BookingProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp.router(
          theme: ThemeData(colorScheme: AppColors.lightColorScheme, useMaterial3: true),
          routerConfig: GoRouter(
            initialLocation: '/passenger-home',
            routes: [
              GoRoute(
                  path: '/passenger-home',
                  builder: (context, state) => const PassengerHomeScreen()),
              GoRoute(
                  path: '/booking-selection',
                  builder: (context, state) => const BookingSelectionScreen()),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Book ride'));
    await tester.pump();
    await tester.tap(find.text('Book ride'), warnIfMissed: false);
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 600)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    // Should land on booking selection with instant/schedule options.
    expect(find.text('Book a Ride'), findsOneWidget);
    expect(find.text('Instant Booking'), findsOneWidget);
    expect(find.text('Schedule Booking'), findsOneWidget);
  });

  testWidgets('Driver shows tabs and completed rides', (tester) async {
    await initTestSupabase(
      FakeBackend(
        role: 'Chauffeur',
        completedRides: [
          completedRideJson(),
          completedRideJson(id: 'ride-completed-2', fare: 32.5),
        ],
      ),
    );

    final auth = AuthProvider();
    await auth.restoreSession();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => RideProvider()),
          ChangeNotifierProvider(create: (_) => PaymentProvider()),
          ChangeNotifierProvider(create: (_) => BookingProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: AppColors.lightColorScheme, useMaterial3: true),
          home: const DriverHomeScreen(),
        ),
      ),
    );

    // Let initState futures resolve (profile + completed rides).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Tabs render.
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);

    // Default tab is Available (index 1). Tap Completed to see history.
    await tester.tap(find.text('Completed'), warnIfMissed: false);
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 600)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    // Completed ride cards should render with fares.
    expect(find.text('\$55.00', skipOffstage: false), findsOneWidget);
    expect(find.text('\$32.50', skipOffstage: false), findsOneWidget);

    // Unmount the screen so the realtime StreamBuilder unsubscribes, then cancel
    // the realtime reconnect timer so no timer is left pending at teardown.
    await tester.pumpWidget(const SizedBox());
    Supabase.instance.client.realtime.reconnectTimer.reset();
  });
}