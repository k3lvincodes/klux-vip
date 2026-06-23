import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/shimmer_loading.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideProv = context.watch<RideProvider>();
    final fareAmount = rideProv.currentRideDetails?['fare_amount'] ?? 200;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Payment method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Padding to center the title
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Save cards section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Save cards',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Card List
              Consumer<PaymentProvider>(
                builder: (context, payProv, _) {
                  if (payProv.isLoading && payProv.paymentMethods.isEmpty) {
                    return const SizedBox(
                      height: 160,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: ShimmerLoading(width: 260, height: 160, borderRadius: 20),
                      ),
                    );
                  }
                  
                  if (payProv.paymentMethods.isEmpty) {
                    return const SizedBox(
                      height: 160,
                      child: Center(
                        child: Text(
                          'No saved cards. Add a new card below.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: payProv.paymentMethods.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final method = payProv.paymentMethods[index];
                        final methodId = method.id;
                        final isSelected = _selectedMethod == methodId;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMethod = methodId;
                            });
                          },
                          child: _buildCreditCard(
                            color: index % 2 == 0 ? const Color(0xFF5D3FD3) : const Color(0xFFE53935),
                            logo: Icons.credit_card,
                            cardNumber: '**** **** **** ${method.last4 ?? '****'}',
                            name: 'User',
                            expiry: '',
                            isSelected: isSelected,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Add new cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: () {
                    _showAddCardModal(context);
                  },
                  child: Row(
                    children:  [
                      Icon(Icons.add_circle_outline, color: isDark ? AppColors.white : AppColors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Add new cards',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Other ways to pay section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Other ways to pay',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
                    _buildPaymentOption(
                      icon: Icons.money,
                      title: 'Cash',
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      icon: Icons.credit_card,
                      title: 'Credit/Debit card',
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      icon: Icons.paypal, // Will use text equivalent if paypal icon is unavailable
                      title: 'Paypal',
                      isImage: true,
                      imagePath: 'assets/paypal.png', // Placeholder
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      icon: Icons.apple,
                      title: 'Apple pay',
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      icon: Icons.g_mobiledata, // Google pay
                      title: 'Google pay',
                    ),
                  ],
                ),
              ),
              
              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Amount to pay ',
                        style: TextStyle(
                          color: isDark ? AppColors.white : AppColors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '\$$fareAmount',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
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
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            CustomButton(
                              title: payProv.isLoading ? 'Processing...' : 'Proceed to pay',
                              onPress: payProv.isLoading ? () {} : () async {
                                final auth = context.read<AuthProvider>();
                                final rideId = rideProv.currentRideId;
                                if (auth.currentUser == null || rideId == null) return;

                                final result = await payProv.processRidePayment(
                                  userId: auth.currentUser!.id,
                                  rideId: rideId,
                                  amount: (fareAmount as num).toDouble(),
                                );

                                if (!context.mounted) return;

                                if (result['requires_action'] == true && result['payment_intent_client_secret'] != null) {
                                  try {
                                    await Stripe.instance.confirmPayment(
                                      paymentIntentClientSecret: result['payment_intent_client_secret'] as String,
                                    );
                                    if (context.mounted) {
                                      context.push('/payment-successful');
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('3D Secure authentication failed: $e')),
                                    );
                                  }
                                } else if (result['success'] == true && context.mounted) {
                                  context.push('/payment-successful');
                                }
                              },
                              variant: ButtonVariant.primary,
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCard({
    required Color color,
    required IconData logo,
    required String cardNumber,
    required String name,
    required String expiry,
    bool isSelected = false,
  }) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.memory, color: Colors.white, size: 30),
              Icon(logo, color: Colors.white, size: 30),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              if (expiry.isNotEmpty)
                Text(
                  expiry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    bool isImage = false,
    String? imagePath,
  }) {
    final isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: (Theme.of(context).brightness == Brightness.dark) ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (Theme.of(context).brightness == Brightness.dark) ? Colors.grey.shade800 : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: (Theme.of(context).brightness == Brightness.dark) ? AppColors.white : AppColors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: (Theme.of(context).brightness == Brightness.dark) ? AppColors.white : AppColors.black,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? AppColors.white : null,
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

  void _showAddCardModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final card = CardFormEditController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isSaving = false;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add New Card',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PCI-compliant card form via flutter_stripe
                    CardFormField(
                      controller: card,
                      style: CardFormStyle(
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
                        textColor: isDark ? AppColors.white : AppColors.black,
                        placeholderColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        borderWidth: 1,
                        borderRadius: 16,
                        borderColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        cursorColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    CustomButton(
                      title: 'Save Card',
                      isLoading: isSaving,
                      onPress: () async {
                        if (!card.details.complete) return;
                        setModalState(() => isSaving = true);

                        try {
                          final paymentMethod = await Stripe.instance.createPaymentMethod(
                            params: const PaymentMethodParams.card(
                              paymentMethodData: PaymentMethodData(
                                
                              ),
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
                                const SnackBar(content: Text('Card added successfully!')),
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
          }
        );
      },
    );
  }
}

