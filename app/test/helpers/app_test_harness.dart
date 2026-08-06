import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stubs the geolocator platform method/event channels so screens that request
/// the current location don't throw MissingPluginException in widget tests.
void stubGeolocatorChannels() {
  const geolocator = MethodChannel('flutter.baseflow.com/geolocator');
  const geolocatorEvents = EventChannel('flutter.baseflow.com/geolocator/events');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(geolocator, (call) async {
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return true;
      case 'checkPermission':
        return 3; // LocationPermission.always
      case 'requestPermission':
        return 3; // LocationPermission.always
      case 'getLastKnownPosition':
        return {
          'latitude': 37.42796133580664,
          'longitude': -122.085749655962,
          'accuracy': 5.0,
          'time': DateTime.now().millisecondsSinceEpoch,
        };
      case 'getCurrentPosition':
        return {
          'latitude': 37.42796133580664,
          'longitude': -122.085749655962,
          'accuracy': 5.0,
          'time': DateTime.now().millisecondsSinceEpoch,
        };
      default:
        return null;
    }
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockStreamHandler(geolocatorEvents, _EmptyStreamHandler());
}

class _EmptyStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    events.endOfStream();
  }

  @override
  void onCancel(Object? arguments) {}
}

/// Initializes Supabase with a mocked HTTP client so the app runs without a
class FakeBackend {
  FakeBackend({
    this.userId = 'test-user-id-123',
    this.email = 'test@kenick.com',
    this.role = 'client',
    Map<String, dynamic>? profile,
    this.completedRides = const [],
    this.requestedRides = const [],
  }) : profile = profile;

  final String userId;
  final String email;
  final String role;
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> completedRides;
  final List<Map<String, dynamic>> requestedRides;
}

/// Initializes Supabase with a mocked HTTP client so the app runs without a
/// live backend. Seeds an authenticated [Session] so `auth.currentUser` and
/// `auth.currentSession` are populated.
Future<void> initTestSupabase(FakeBackend backend) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  stubGeolocatorChannels();

  final anonKey = 'test-anon-key';

  final profileData = backend.profile ??
      {
        'id': backend.userId,
        'email': backend.email,
        'first_name': 'Test',
        'last_name': 'User',
        'role': backend.role,
        'avatar_url': null,
        'verification_status': 'approved',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };

  final headers = {
    'content-type': 'application/json; charset=utf-8',
    'apikey': anonKey,
  };

  http.Response ok(http.Request req, Object body) {
    return http.Response(jsonEncode(body), 200, headers: headers, request: req);
  }

  final client = MockClient((request) async {
    final path = request.url.path;

    // Gotrue setSession -> POST /token?grant_type=refresh_token
    if (path.endsWith('/token')) {
      return ok(request, {
        'access_token': 'fake_access_token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'fake_refresh_token',
        'user': {
          'id': backend.userId,
          'email': backend.email,
          'aud': 'authenticated',
          'role': 'authenticated',
          'app_metadata': {'provider': 'email'},
          'user_metadata': {'role': backend.role, 'name': 'Test User'},
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
          'identities': <Object>[],
        },
      });
    }

    // Profiles table
    if (path == '/rest/v1/profiles') {
      return ok(request, [profileData]);
    }

    // Rides table (completed rides list)
    if (path == '/rest/v1/rides') {
      return ok(request, backend.completedRides);
    }

    // ride_requests table
    if (path == '/rest/v1/ride_requests') {
      return ok(request, backend.requestedRides);
    }

    return ok(request, <Object>[]);
  });

  await Supabase.initialize(
    url: 'https://test.supabase.co',
    anonKey: anonKey,
    httpClient: client,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: false,
      detectSessionInUri: false,
    ),
  );

  // Seed a session so auth.currentUser is populated.
  await Supabase.instance.client.auth.setSession('fake_refresh_token');
}

