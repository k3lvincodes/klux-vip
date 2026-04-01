import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/payment_provider.dart';
import 'package:klux_vip/providers/ride_provider.dart';
import 'package:klux_vip/providers/auth_provider.dart';

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
    final rideProv = context.watch<RideProvider>();
    final fareAmount = rideProv.currentRideDetails?['fare_amount'] ?? 200;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0B3), Color(0xFFF3EDEC)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
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
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Payment method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Save cards',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Card List
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
                    _buildCreditCard(
                      color: const Color(0xFF5D3FD3), // Purple
                      logo: Icons.credit_card, // Placeholder for mastercard logo
                      cardNumber: '**** **** **** 1289',
                      name: 'David Joe',
                      expiry: '09/25',
                    ),
                    const SizedBox(width: 16),
                    _buildCreditCard(
                      color: const Color(0xFFE53935), // Red
                      logo: Icons.credit_card,
                      cardNumber: '**** **** **** 1289',
                      name: 'David Joe',
                      expiry: '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Add new cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: () {
                    context.push('/add-card');
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline, color: AppColors.black),
                      SizedBox(width: 8),
                      Text(
                        'Add new cards',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Other ways to pay section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Other ways to pay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
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
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 16,
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
                        return CustomButton(
                          title: payProv.isLoading ? 'Processing...' : 'Proceed to pay',
                          onPress: payProv.isLoading ? () {} : () async {
                            final auth = context.read<AuthProvider>();
                            final rideId = rideProv.currentRideId;
                            if (auth.currentUser == null || rideId == null) return;

                            final success = await payProv.processRidePayment(
                              userId: auth.currentUser!.id,
                              rideId: rideId,
                              amount: (fareAmount as num).toDouble(),
                            );

                            if (success && context.mounted) {
                              context.push('/payment-successful');
                            }
                          },
                          variant: ButtonVariant.primary,
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
  }) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 16,
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
                  fontSize: 14,
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
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
            Icon(icon, color: AppColors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
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
}
