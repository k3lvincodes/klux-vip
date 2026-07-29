import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WithdrawToBankScreen extends StatefulWidget {
  const WithdrawToBankScreen({super.key});

  @override
  State<WithdrawToBankScreen> createState() => _WithdrawToBankScreenState();
}

class _WithdrawToBankScreenState extends State<WithdrawToBankScreen> {
  String _bankName = '---';
  String _accountName = '---';
  String _accountNumber = '---';

  @override
  void initState() {
    super.initState();
    _fetchBankData();
  }

  Future<void> _fetchBankData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('payment_methods')
          .select('payment_method_id')
          .eq('user_id', user.id)
          .eq('type', 'bank_transfer')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && mounted) {
        final pmId = response['payment_method_id'] as String? ?? '';
        // Parse bank info from payment_method_id format: bank_<name>_<last4>
        final parts = pmId.split('_');
        if (parts.length >= 3) {
          setState(() {
            _bankName = parts[1].toUpperCase();
            _accountNumber = '••••${parts.last}';
            _accountName = user.email?.split('@').first.toUpperCase() ?? 'ACCOUNT HOLDER';
          });
          return;
        }
      }
    } catch (e) {
      // Bank data stays as defaults ('---')
    }
  }

  void _showVerifyPinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _VerifyPinSheet(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
                    ),
                    Expanded(
                      child: Text(
                        'Withdraw to bank',
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
              const SizedBox(height: 8),

              // Bank info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance, color: AppColors.white, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _accountName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                        Text(
                          '$_accountNumber $_bankName',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bottom section: Confirm bank details
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5EFEE),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accountName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bank name field (read-only)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFEE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:  Text(
                          _bankName,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.white : AppColors.black),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Account number field (read-only)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFEE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:  Text(
                          _accountNumber,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.white : AppColors.black),
                        ),
                      ),
                      const Spacer(),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showVerifyPinDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child:  Text(
                            'Confirm',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Verify Transaction Pin Sheet
class _VerifyPinSheet extends StatefulWidget {
  const _VerifyPinSheet();

  @override
  State<_VerifyPinSheet> createState() => _VerifyPinSheetState();
}

class _VerifyPinSheetState extends State<_VerifyPinSheet> {
  final List<String> _pin = ['', '', '', ''];
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isComplete => _pin.every((d) => d.isNotEmpty);

  Future<void> _verifyPin() async {
    if (!_isComplete) return;
    setState(() => _isVerifying = true);
    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isVerifying = false);
      Navigator.of(context).pop();
      context.go('/account');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Withdrawal confirmed'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

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
            'Enter your pin to verify\ntransaction',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Pin fields with real input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 48,
                height: 48,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_pin[index].isEmpty && index > 0) {
                        setState(() => _pin[index - 1] = '');
                        _focusNodes[index - 1].requestFocus();
                      }
                    }
                  },
                  child: TextField(
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF5EFEE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      setState(() => _pin[index] = value);
                      if (_isComplete) _verifyPin();
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Fingerprint icon
          Icon(
            Icons.fingerprint,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Or use fingerprints',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),

          // Done Button
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : (_isComplete ? _verifyPin : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                  : Text(
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

