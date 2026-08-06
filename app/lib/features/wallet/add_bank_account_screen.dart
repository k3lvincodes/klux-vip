import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
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
      builder: (context) => const _SetPinSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Bank Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Icon(
                  Icons.account_balance,
                  size: 100,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text('Bank name', style: tt.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  hintText: 'Enter bank name',
                  prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),
              Text('Account holder name', style: tt.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _holderNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),
              Text('Account number', style: tt.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter account number',
                  prefixIcon: const Icon(Icons.tag, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 40),
              Consumer<PaymentProvider>(
                builder: (context, payProv, _) {
                  return CustomButton(
                    title: payProv.isLoading ? 'Saving...' : 'Add bank account',
                    onPress: payProv.isLoading
                        ? () {}
                        : () async {
                            if (_bankNameController.text.isEmpty ||
                                _holderNameController.text.isEmpty ||
                                _accountNumberController.text.isEmpty) {
                              CustomToast.showError(context, 'Please fill all fields');
                              return;
                            }
                            final auth = context.read<AuthProvider>();
                            if (auth.currentUser == null) return;

                            final last4 = _accountNumberController.text.length >= 4
                                ? _accountNumberController.text.substring(
                                    _accountNumberController.text.length - 4,
                                  )
                                : _accountNumberController.text;

                            final success = await payProv.addPaymentMethod(
                              userId: auth.currentUser!.id,
                              paymentMethodId: 'bank_${_bankNameController.text.toLowerCase()}_$last4',
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
    );
  }
}

class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet();

  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  final List<String> _pin = ['', '', '', ''];
  final List<String> _confirmPin = ['', '', '', ''];
  bool _isConfirming = false;
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  final List<FocusNode> _confirmFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final node in [..._pinFocusNodes, ..._confirmFocusNodes]) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isPinComplete => _pin.every((d) => d.isNotEmpty);
  bool get _isConfirmComplete => _confirmPin.every((d) => d.isNotEmpty);
  bool get _isDone => _isPinComplete && _isConfirmComplete && _pin.join() == _confirmPin.join();

  List<FocusNode> get _activeFocusNodes => _isConfirming ? _confirmFocusNodes : _pinFocusNodes;
  List<String> get _activePin => _isConfirming ? _confirmPin : _pin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isConfirming ? 'Confirm your pin' : 'Set up withdrawal pin',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            _isConfirming ? 'Re-enter your 4 digit pin' : 'Enter your 4 digit pin',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 48,
                height: 48,
                child: TextField(
                  focusNode: _activeFocusNodes[index],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _activePin[index] = value);
                    if (value.isNotEmpty && index < 3) {
                      _activeFocusNodes[index + 1].requestFocus();
                    }
                    if (_activePin.every((d) => d.isNotEmpty)) {
                      if (!_isConfirming) {
                        setState(() => _isConfirming = true);
                        _confirmFocusNodes[0].requestFocus();
                      }
                    }
                  },
                ),
              );
            }),
          ),
          if (!_isConfirming) ...[
            const SizedBox(height: 16),
            Text(
              'Pins do not match',
              style: tt.bodySmall?.copyWith(
                color: _isPinComplete && _confirmPin.isNotEmpty && !_isDone
                    ? cs.error
                    : Colors.transparent,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: FilledButton(
              onPressed: _isDone
                  ? () {
                      Navigator.of(context).pop();
                      context.push('/withdraw-to-bank');
                    }
                  : null,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
