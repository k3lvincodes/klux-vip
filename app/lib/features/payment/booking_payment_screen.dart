import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:provider/provider.dart';

class BookingPaymentScreen extends StatefulWidget {
  const BookingPaymentScreen({super.key});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  double _fareAmount = 0.0;
  double _tipAmount = 0.0;
  String? _selectedPaymentMethodId;
  bool _showNewCardForm = false;
  bool _isProcessing = false;
  final CardFormEditController _cardController = CardFormEditController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extras = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extras != null) {
      _fareAmount = (extras['fareAmount'] as num?)?.toDouble() ?? 0.0;
      _tipAmount = (extras['tipAmount'] as num?)?.toDouble() ?? 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<PaymentProvider>().fetchPaymentMethods(userId);
      }
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  double get _totalAmount => _fareAmount + _tipAmount;

  Future<void> _handleConfirmPay() async {
    if (_isProcessing) return;

    final auth = context.read<AuthProvider>();
    final rideProv = context.read<RideProvider>();
    final payProv = context.read<PaymentProvider>();

    if (auth.currentUser == null) {
      if (!mounted) return;
      CustomToast.showError(context, 'User not authenticated');
      return;
    }

    final rideId = rideProv.currentRideId;
    if (rideId == null) {
      if (!mounted) return;
      CustomToast.showError(context, 'No active ride found');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await payProv.processRidePayment(
        userId: auth.currentUser!.id,
        rideId: rideId,
        amount: _totalAmount,
        paymentMethodId: _selectedPaymentMethodId,
      );

      if (!mounted) return;

      if (result['requires_action'] == true &&
          result['payment_intent_client_secret'] != null) {
        try {
          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret:
                result['payment_intent_client_secret'] as String,
          );
          if (mounted) {
            _navigateToInvoice(rideId);
          }
        } catch (e) {
          if (!mounted) return;
          CustomToast.showError(
            context,
            '3D Secure authentication failed: $e',
          );
        }
      } else if (result['success'] == true) {
        if (mounted) {
          _navigateToInvoice(rideId);
        }
      } else {
        if (mounted) {
          CustomToast.showError(
            context,
            result['error'] ?? 'Payment failed',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Payment failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _navigateToInvoice(String rideId) {
    final pickup = context.read<RideProvider>().pickupLocation;
    final dropoff = context.read<RideProvider>().dropoffLocation;

    context.push(
      '/booking-invoice',
      extra: {
        'fareAmount': _fareAmount,
        'tipAmount': _tipAmount,
        'taxAmount': 0.0,
        'totalAmount': _totalAmount,
        'pickupAddress': pickup?.placeName ?? '',
        'dropoffAddress': dropoff?.placeName ?? '',
        'vehicleType': 'VIP Sedan',
        'tripDate': DateTime.now().toString().substring(0, 10),
        'paymentMethodLast4': _selectedPaymentMethodId != null
            ? _getLast4FromSelected()
            : 'XXXX',
        'bookingConfirmation': 'BK-${rideId.substring(0, 8).toUpperCase()}',
        'invoiceNumber':
            'KLX-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}-${rideId.substring(0, 4).toUpperCase()}',
      },
    );
  }

  String _getLast4FromSelected() {
    final payProv = context.read<PaymentProvider>();
    try {
      final method = payProv.paymentMethods.firstWhere(
        (m) => m.id == _selectedPaymentMethodId,
      );
      return method.last4 ?? 'XXXX';
    } catch (_) {
      return 'XXXX';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Payment',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Fare breakdown card
                    FadeSlideIn(
                      child: _buildFareBreakdownCard(isDark),
                    ),
                    const SizedBox(height: 32),

                    // Payment method section
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Text(
                        'Payment method',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Saved cards
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _buildSavedCardsSection(isDark),
                    ),
                    const SizedBox(height: 16),

                    // Pay with new card
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: _buildNewCardOption(isDark),
                    ),

                    // New card form
                    if (_showNewCardForm) ...[
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        child: _buildCardForm(isDark),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Confirm & Pay button
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    // Total display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                        Text(
                          '\$${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      title: _isProcessing ? 'Processing...' : 'Confirm & Pay',
                      onPress: _isProcessing ? () {} : _handleConfirmPay,
                      isLoading: _isProcessing,
                      variant: ButtonVariant.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareBreakdownCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFareRow(
            label: 'Base fare',
            value: _fareAmount,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFareRow(
            label: 'Trip fare',
            value: _fareAmount,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFareRow(
            label: 'Tip',
            value: _tipAmount,
            isDark: isDark,
            customLabel: _tipAmount == 0 ? 'No tip' : null,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.primary),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              Text(
                '\$${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow({
    required String label,
    required double value,
    required bool isDark,
    String? customLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          customLabel ?? label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.7)
                : AppColors.black.withValues(alpha: 0.6),
          ),
        ),
        Text(
          customLabel != null
              ? ''
              : '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.7)
                : AppColors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCardsSection(bool isDark) {
    return Consumer<PaymentProvider>(
      builder: (context, payProv, _) {
        if (payProv.isLoading && payProv.paymentMethods.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.white : AppColors.black,
                ),
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (payProv.paymentMethods.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No saved cards. Add a new card below.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.5)
                    : AppColors.black.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: payProv.paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethodId == method.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSavedCardTile(
                methodId: method.id,
                last4: method.last4 ?? '****',
                isSelected: isSelected,
                isDark: isDark,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSavedCardTile({
    required String methodId,
    required String last4,
    required bool isSelected,
    required bool isDark,
  }) {
    return PressScale(
      onTap: () {
        setState(() {
          _selectedPaymentMethodId = methodId;
          _showNewCardForm = false;
        });
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.secondary),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary)
              : Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.white : AppColors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '•••• •••• •••• $last4',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardOption(bool isDark) {
    return PressScale(
      onTap: () {
        setState(() {
          _showNewCardForm = !_showNewCardForm;
          if (_showNewCardForm) {
            _selectedPaymentMethodId = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _showNewCardForm
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.secondary),
          borderRadius: BorderRadius.circular(12),
          border: _showNewCardForm
              ? Border.all(color: AppColors.primary)
              : Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: _showNewCardForm
                  ? AppColors.primary
                  : (isDark ? AppColors.white : AppColors.black),
            ),
            const SizedBox(width: 12),
            Text(
              'Pay with new card',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CardFormField(
        controller: _cardController,
        style: CardFormStyle(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
          textColor: isDark ? AppColors.white : AppColors.black,
          placeholderColor:
              isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          borderWidth: 1,
          borderRadius: 12,
          borderColor:
              isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          cursorColor: AppColors.primary,
        ),
      ),
    );
  }
}
