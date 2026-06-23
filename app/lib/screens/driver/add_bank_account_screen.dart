import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _bankNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  @override
  void dispose() {
    _bankNameController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _showSetPinDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SetPinSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Add Bank Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Bank Icon
                      const Center(
                        child: Icon(
                          Icons.account_balance,
                          size: 100,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bank Name
                      const Text(
                        'Bank name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField('Enter  bank name', _bankNameController),
                      const SizedBox(height: 20),

                      // Account Holder Name
                      const Text(
                        'Account holder name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        'Enter your full name',
                        _holderNameController,
                      ),
                      const SizedBox(height: 20),

                      // Account Number
                      const Text(
                        'Account number',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        'Enter account number',
                        _accountNumberController,
                      ),
                      const SizedBox(height: 40),

                      Consumer<PaymentProvider>(
                        builder: (context, payProv, _) {
                          return CustomButton(
                            title: payProv.isLoading
                                ? 'Saving...'
                                : 'Add bank account',
                            onPress: payProv.isLoading
                                ? () {}
                                : () async {
                                    if (_bankNameController.text.isEmpty ||
                                        _holderNameController.text.isEmpty ||
                                        _accountNumberController.text.isEmpty) {
                                      CustomToast.showError(
                                        context,
                                        'Please fill all fields',
                                      );
                                      return;
                                    }
                                    final auth = context.read<AuthProvider>();
                                    if (auth.currentUser == null) return;

                                    final last4 =
                                        _accountNumberController.text.length >=
                                            4
                                        ? _accountNumberController.text
                                              .substring(
                                                _accountNumberController
                                                        .text
                                                        .length -
                                                    4,
                                              )
                                        : _accountNumberController.text;

                                    final success = await payProv.addPaymentMethod(
                                      userId: auth.currentUser!.id,
                                      paymentMethodId:
                                          'bank_${_bankNameController.text.toLowerCase()}_$last4',
                                      customerId: auth.currentUser!.id,
                                    );

                                    if (success && context.mounted) {
                                      _showSetPinDialog();
                                    }
                                  },
                            variant: ButtonVariant.primary,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark)
            ? AppColors.darkSurface
            : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: AppColors.white,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

// Set Up Withdrawal Pin Bottom Sheet
class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet();

  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  final List<String> _pin = ['', '', '', ''];
  final List<String> _confirmPin = ['', '', '', ''];
  final bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set up withdrawal pin',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Enter pin
          const Text('Enter your  4 digit pin', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final val = _pin[index];
              return Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EFEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  val.isEmpty
                      ? ''
                      : (index < 2 && !_isConfirming && _pin[index].isNotEmpty
                            ? val
                            : '•'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Confirm pin
          const Text(
            'Confirm pin',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final val = _confirmPin[index];
              return Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EFEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  val.isEmpty
                      ? ''
                      : (index < 2 &&
                                _isConfirming &&
                                _confirmPin[index].isNotEmpty
                            ? val
                            : '•'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Done Button
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to withdraw to bank or back to account
                context.push('/withdraw-to-bank');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Done',
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
