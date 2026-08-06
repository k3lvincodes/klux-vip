import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/feedback/shimmer_loading.dart';
import 'package:provider/provider.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedMethod = 'Credit/Debit card';

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<PaymentProvider>().fetchPaymentMethods(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rideProv = context.watch<RideProvider>();
    final fareAmount = rideProv.currentRideDetails?['fare_amount'] ?? 200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Payment method'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Saved cards',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                Consumer<PaymentProvider>(
                  builder: (context, payProv, _) {
                    if (payProv.isLoading && payProv.paymentMethods.isEmpty) {
                      return const SizedBox(
                        height: 160,
                        child: ShimmerLoading(width: 260, height: 160, borderRadius: 20),
                      );
                    }
                    if (payProv.paymentMethods.isEmpty) {
                      return SizedBox(
                        height: 160,
                        child: Center(
                          child: Text(
                            'No saved cards. Add a new card below.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: payProv.paymentMethods.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final method = payProv.paymentMethods[index];
                          final methodId = method.id;
                          final isSelected = _selectedMethod == methodId;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMethod = methodId),
                            child: _buildCreditCard(
                              color: index % 2 == 0
                                  ? cs.tertiary
                                  : cs.error,
                              cardNumber:
                                  '**** **** **** ${method.last4 ?? '****'}',
                              isSelected: isSelected,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.add_circle_outline, color: cs.onSurface),
                  title: Text('Add new cards',
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTap: () => _showAddCardModal(context),
                ),
                const SizedBox(height: 24),
                Text('Other ways to pay',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                _buildPaymentOption(icon: Icons.money, title: 'Cash'),
                const SizedBox(height: 8),
                _buildPaymentOption(
                    icon: Icons.credit_card, title: 'Credit/Debit card'),
                const SizedBox(height: 8),
                _buildPaymentOption(icon: Icons.paypal, title: 'Paypal'),
                const SizedBox(height: 8),
                _buildPaymentOption(icon: Icons.apple, title: 'Apple pay'),
                const SizedBox(height: 8),
                _buildPaymentOption(
                    icon: Icons.g_mobiledata, title: 'Google pay'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Amount to pay ',
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '\$$fareAmount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<PaymentProvider>(
                  builder: (context, payProv, _) {
                    return Column(
                      children: [
                        if (payProv.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              payProv.errorMessage!,
                              style: TextStyle(color: cs.error, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        CustomButton(
                          title: payProv.isLoading
                              ? 'Processing...'
                              : 'Proceed to pay',
                          onPress: payProv.isLoading
                              ? () {}
                              : () async {
                                  final auth = context.read<AuthProvider>();
                                  final rideId = rideProv.currentRideId;
                                  if (auth.currentUser == null || rideId == null) {
                                    return;
                                  }
                                  final result = await payProv.processRidePayment(
                                    userId: auth.currentUser!.id,
                                    rideId: rideId,
                                    amount: (fareAmount as num).toDouble(),
                                  );
                                  if (!context.mounted) return;
                                  if (result['requires_action'] == true &&
                                      result['payment_intent_client_secret'] != null) {
                                    try {
                                      await stripe.Stripe.instance.confirmPayment(
                                        paymentIntentClientSecret: result[
                                                'payment_intent_client_secret']
                                            as String,
                                      );
                                      if (context.mounted) {
                                        context.push('/payment-successful');
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '3D Secure authentication failed: $e')),
                                      );
                                    }
                                  } else if (result['success'] == true &&
                                      context.mounted) {
                                    context.push('/payment-successful');
                                  }
                                },
                          variant: ButtonVariant.primary,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard({
    required Color color,
    required String cardNumber,
    bool isSelected = false,
  }) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.memory, color: Colors.white, size: 30),
              const Icon(Icons.credit_card, color: Colors.white, size: 30),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const Expanded(child: SizedBox()),
          const Text(
            'User',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedMethod == title;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
        ),
        onTap: () => setState(() => _selectedMethod = title),
      ),
    );
  }

  void _showAddCardModal(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final card = stripe.CardFormEditController();
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isSaving = false;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Card',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 24),
                    stripe.CardFormField(
                      controller: card,
                      style: stripe.CardFormStyle(
                        backgroundColor: cs.surfaceContainerLow,
                        textColor: cs.onSurface,
                        placeholderColor: cs.onSurfaceVariant,
                        borderWidth: 1,
                        borderRadius: 16,
                        borderColor: cs.outline,
                        cursorColor: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      title: 'Save Card',
                      isLoading: isSaving,
                      onPress: () async {
                        if (!card.details.complete) return;
                        setModalState(() => isSaving = true);
                        try {
                          final paymentMethod =
                              await stripe.Stripe.instance.createPaymentMethod(
                            params: const stripe.PaymentMethodParams.card(
                              paymentMethodData: stripe.PaymentMethodData(),
                            ),
                          );
                          if (!ctx.mounted) return;
                          final auth = ctx.read<AuthProvider>();
                          if (auth.currentUser != null) {
                            if (!ctx.mounted) return;
                            final payProv = ctx.read<PaymentProvider>();
                            final success = await payProv.addPaymentMethod(
                              userId: auth.currentUser!.id,
                              paymentMethodId: paymentMethod.id,
                              customerId: auth.currentUser!.id,
                            );
                            if (success && ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Card added successfully!')),
                              );
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to save card: $e')),
                            );
                          }
                        }
                        setModalState(() => isSaving = false);
                      },
                      variant: ButtonVariant.primary,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
