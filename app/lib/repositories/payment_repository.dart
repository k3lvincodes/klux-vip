import 'package:kenick_vip/models/payment_method.dart';
import 'package:kenick_vip/models/transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch payment methods: $e');
    }
  }

  Future<String> addPaymentMethod({
    required String userId,
    required String paymentMethodId,
    required String customerId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments',
        body: {
          'action': 'create-setup-intent',
          'data': {
            'user_id': userId,
            'payment_method_id': paymentMethodId,
            'customer_id': customerId,
          },
        },
      );

      if (response.data == null || response.data['error'] != null) {
        throw Exception(
          response.data?['error'] ?? 'Failed to add payment method',
        );
      }

      return response.data['setup_intent'] as String;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  Future<Map<String, dynamic>> captureRidePayment({
    required String rideId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments',
        body: {
          'action': 'capture-ride-payment',
          'data': {'ride_id': rideId},
        },
      );

      if (response.data == null || response.data['error'] != null) {
        throw Exception(response.data?['error'] ?? 'Capture failed');
      }

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to capture payment: $e');
    }
  }

  Future<Map<String, dynamic>> cancelRidePayment({
    required String rideId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments',
        body: {
          'action': 'cancel-ride-payment',
          'data': {'ride_id': rideId},
        },
      );

      if (response.data == null || response.data['error'] != null) {
        throw Exception(response.data?['error'] ?? 'Cancellation failed');
      }

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to cancel payment: $e');
    }
  }

  Future<Map<String, dynamic>> processRidePayment({
    required String userId,
    required String rideId,
    required double amount,
    String? paymentMethodId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments',
        body: {
          'action': 'process-ride-payment',
          'data': {
            'user_id': userId,
            'ride_id': rideId,
            'amount': amount,
            'payment_method_id': ?paymentMethodId,
          },
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

  Future<List<Transaction>> getTransactions(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
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
