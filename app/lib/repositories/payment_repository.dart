import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<String> addPaymentMethod({
    required String userId,
    required String paymentMethodId,
    required String last4,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments',
        body: {
          'action': 'create-setup-intent',
          'data': {
            'user_id': userId,
            'payment_method_id': paymentMethodId,
            'last4': last4,
          },
        },
      );

      if (response.data == null || response.data['error'] != null) {
        throw Exception(
          response.data?['error'] ?? 'Failed to add payment method',
        );
      }

      return response.data['id'] ?? paymentMethodId;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  Future<Map<String, dynamic>> processRidePayment({
    required String userId,
    required String rideId,
    required double amount,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments',
        body: {
          'action': 'process-ride-payment',
          'data': {'user_id': userId, 'ride_id': rideId, 'amount': amount},
        },
      );

      if (response.data == null || response.data['error'] != null) {
        throw Exception(response.data?['error'] ?? 'Payment failed');
      }

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

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

  Future<String> payoutDriver({
    required String driverId,
    required String rideId,
    required double amount,
    required String stripeConnectId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments',
        body: {
          'action': 'payout-driver',
          'data': {
            'driver_id': driverId,
            'ride_id': rideId,
            'amount': amount,
            'stripe_connect_id': stripeConnectId,
          },
        },
      );

      if (response.data == null || response.data['error'] != null) {
        throw Exception(response.data?['error'] ?? 'Payout failed');
      }

      return response.data['transfer_id'] as String;
    } catch (e) {
      throw Exception('Failed to payout driver: $e');
    }
  }
}
