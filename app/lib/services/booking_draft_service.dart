import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a paused / in-progress booking session draft.
class BookingDraft {
  BookingDraft({
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.rideType = 'One way',
    this.byTheHourDuration = 2,
    this.passengerMode,
    this.guestName,
    this.guestPhone,
    this.scheduledTime,
    this.returnTime,
    this.eventType,
    this.customEventType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BookingDraft.fromJson(Map<String, dynamic> json) => BookingDraft(
        pickupAddress: json['pickupAddress'] as String?,
        dropoffAddress: json['dropoffAddress'] as String?,
        pickupLat: (json['pickupLat'] as num?)?.toDouble(),
        pickupLng: (json['pickupLng'] as num?)?.toDouble(),
        dropoffLat: (json['dropoffLat'] as num?)?.toDouble(),
        dropoffLng: (json['dropoffLng'] as num?)?.toDouble(),
        rideType: json['rideType'] as String? ?? 'One way',
        byTheHourDuration: (json['byTheHourDuration'] as num?)?.toInt() ?? 2,
        passengerMode: json['passengerMode'] as String?,
        guestName: json['guestName'] as String?,
        guestPhone: json['guestPhone'] as String?,
        scheduledTime: json['scheduledTime'] != null
            ? DateTime.tryParse(json['scheduledTime'] as String)
            : null,
        returnTime: json['returnTime'] != null
            ? DateTime.tryParse(json['returnTime'] as String)
            : null,
        eventType: json['eventType'] as String?,
        customEventType: json['customEventType'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String rideType; // 'One way', 'Round trip', 'By-the-hour', 'Event', 'Out of state'
  final int byTheHourDuration;
  final String? passengerMode;
  final String? guestName;
  final String? guestPhone;
  final DateTime? scheduledTime;
  final DateTime? returnTime;
  final String? eventType;
  final String? customEventType;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'rideType': rideType,
        'byTheHourDuration': byTheHourDuration,
        'passengerMode': passengerMode,
        'guestName': guestName,
        'guestPhone': guestPhone,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'returnTime': returnTime?.toIso8601String(),
        'eventType': eventType,
        'customEventType': customEventType,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Validates whether the draft is under the 24-hour expiration threshold.
  bool get isFresh {
    return DateTime.now().difference(createdAt).inHours < 24;
  }
}

/// Represents a past destination for quick 1-tap rebooking.
class RecentDestination {
  RecentDestination({
    required this.placeName,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.rideCount = 1,
  });

  final String placeName;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final int rideCount;
}

class BookingDraftService {
  static const String _draftKey = 'kenick_paused_booking_draft_v1';
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Saves a draft of the current in-progress booking.
  static Future<void> saveDraft(BookingDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey, jsonEncode(draft.toJson()));
    } catch (_) {}
  }

  /// Retrieves the active paused draft.
  /// If the draft has expired (> 24 hours), it automatically clears it and returns null.
  static Future<BookingDraft?> getActiveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final draft = BookingDraft.fromJson(data);

      if (!draft.isFresh) {
        // Expired after 24 hours -> clear automatically
        await clearDraft();
        return null;
      }
      return draft;
    } catch (_) {
      return null;
    }
  }

  /// Clears the saved draft (e.g. after booking completes or is discarded).
  static Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  /// Fetches the passenger's most frequent or recent completed destination.
  /// Returns null if the passenger has not completed any rides yet.
  static Future<RecentDestination?> getRecentDestination() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final rows = await _supabase
          .from('rides')
          .select('dropoff_address, dropoff_latitude, dropoff_longitude, status, created_at')
          .eq('passenger_id', user.id)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(12);

      if (rows.isEmpty) return null;

      // Group by dropoff address to detect most frequent or latest
      final counts = <String, int>{};
      final rowMap = <String, Map<String, dynamic>>{};

      for (final r in rows) {
        final address = r['dropoff_address'] as String?;
        if (address != null && address.trim().isNotEmpty) {
          final norm = address.trim();
          counts[norm] = (counts[norm] ?? 0) + 1;
          rowMap.putIfAbsent(norm, () => r);
        }
      }

      if (counts.isEmpty) return null;

      // Find the destination with the highest count (or most recent if equal)
      String? topAddress;
      int highest = 0;
      for (final entry in counts.entries) {
        if (entry.value > highest) {
          highest = entry.value;
          topAddress = entry.key;
        }
      }

      final chosen = rowMap[topAddress ?? counts.keys.first]!;
      final fullAddr = topAddress ?? counts.keys.first;
      final placeName = fullAddr.split(',').first.trim();
      final lat = (chosen['dropoff_latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (chosen['dropoff_longitude'] as num?)?.toDouble() ?? 0.0;

      return RecentDestination(
        placeName: placeName,
        fullAddress: fullAddr,
        latitude: lat,
        longitude: lng,
        rideCount: highest,
      );
    } catch (_) {
      return null;
    }
  }
}
