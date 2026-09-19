import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedActionIndex = 0;
  int _selectedTabIndex = 0;
  bool _isBalanceVisible = true;

  final List<String> _actionLabels = ['Earnings', 'Withdraw', 'History'];
  final List<IconData> _actionIcons = [
    Icons.monetization_on_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.history,
  ];

  final List<String> _tabLabels = ['Earnings', 'Bonuses', 'Commission'];

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<PaymentProvider>().fetchDriverEarnings(userId);
      context.read<PaymentProvider>().fetchTransactions(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final payProv = context.watch<PaymentProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            'Earnings & Wallet',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.black),
                          onPressed: () => context.push('/driver-profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Total balance',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isBalanceVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isBalanceVisible
                            ? '\$${payProv.totalEarnings.toStringAsFixed(2)}'
                            : '••••••',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        final isSelected = _selectedActionIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedActionIndex = index);
                            if (index == 1) {
                              context.push('/withdraw-method');
                            } else if (index == 2) {
                              context.push('/driver-ride-history');
                            }
                          },
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.black.withValues(alpha: 0.75)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Icon(
                                  _actionIcons[index],
                                  color: isSelected ? cs.primary : Colors.black,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _actionLabels[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_tabLabels.length, (index) {
                  final isSelected = _selectedTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(_tabLabels[index]),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedTabIndex = index),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: payProv.transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: cs.outline),
                        const SizedBox(height: 12),
                        Text('No transactions yet', style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: payProv.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = payProv.transactions[index];
                      final bool isOutgoing = tx.type == 'withdrawal';
                      final amount = tx.amount;
                      final date = tx.createdAt.toLocal().toString().split(' ')[0];
                      const green = Color(0xFF22C55E);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isOutgoing ? Icons.arrow_outward : Icons.south_west,
                              size: 18,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            isOutgoing ? 'Withdrawal' : 'Ride Payment',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(date),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${isOutgoing ? "-" : "+"}\$$amount',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isOutgoing ? cs.error : green,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fade(delay: (index * 50).ms, duration: 300.ms)
                          .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutCubic);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
