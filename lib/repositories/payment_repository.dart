import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Payment Methods (Cards) ────────────────────────────────

  /// Fetch all saved payment methods for a user
  Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch payment methods: $e');
    }
  }

  /// Add a new payment method (card)
  Future<String> addPaymentMethod({
    required String userId,
    required String type, // 'card', 'paypal', 'apple_pay', 'google_pay'
    required String last4,
    String? providerToken,
  }) async {
    try {
      final response = await _supabase.from('payment_methods').insert({
        'user_id': userId,
        'type': type,
        'last4': last4,
        'provider_token': providerToken ?? 'tok_placeholder',
      }).select().single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  // ─── Transactions ───────────────────────────────────────────

  /// Create a ride payment transaction
  Future<String> createRidePayment({
    required String userId,
    required String rideId,
    required double amount,
  }) async {
    try {
      final response = await _supabase.from('transactions').insert({
        'user_id': userId,
        'ride_id': rideId,
        'amount': amount,
        'type': 'ride_payment',
        'status': 'completed',
      }).select().single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  /// Fetch transaction history for a user
  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Get total earnings for a driver
  Future<double> getDriverEarnings(String driverId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('amount')
          .eq('user_id', driverId)
          .eq('type', 'ride_payment')
          .eq('status', 'completed');
      
      double total = 0;
      for (final row in response) {
        total += (row['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      throw Exception('Failed to fetch earnings: $e');
    }
  }

  // ─── Withdrawals ────────────────────────────────────────────

  /// Create a withdrawal request
  Future<String> requestWithdrawal({
    required String userId,
    required double amount,
  }) async {
    try {
      final response = await _supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'withdrawal',
        'status': 'pending',
      }).select().single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to request withdrawal: $e');
    }
  }
}
