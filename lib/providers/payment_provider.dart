import 'package:flutter/material.dart';
import 'package:klux_vip/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _paymentRepository = PaymentRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _transactions = [];
  double _totalEarnings = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get paymentMethods => _paymentMethods;
  List<Map<String, dynamic>> get transactions => _transactions;
  double get totalEarnings => _totalEarnings;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // ─── Payment Methods ────────────────────────────────────────

  Future<void> fetchPaymentMethods(String userId) async {
    try {
      _setLoading(true);
      _setError(null);
      _paymentMethods = await _paymentRepository.getPaymentMethods(userId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addPaymentMethod({
    required String userId,
    required String type,
    required String last4,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      await _paymentRepository.addPaymentMethod(
        userId: userId,
        type: type,
        last4: last4,
      );
      await fetchPaymentMethods(userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Transactions ───────────────────────────────────────────

  Future<bool> processRidePayment({
    required String userId,
    required String rideId,
    required double amount,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      await _paymentRepository.createRidePayment(
        userId: userId,
        rideId: rideId,
        amount: amount,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTransactions(String userId) async {
    try {
      _setLoading(true);
      _setError(null);
      _transactions = await _paymentRepository.getTransactions(userId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDriverEarnings(String driverId) async {
    try {
      _setLoading(true);
      _setError(null);
      _totalEarnings = await _paymentRepository.getDriverEarnings(driverId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ─── Withdrawals ────────────────────────────────────────────

  Future<bool> requestWithdrawal({
    required String userId,
    required double amount,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      await _paymentRepository.requestWithdrawal(
        userId: userId,
        amount: amount,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
