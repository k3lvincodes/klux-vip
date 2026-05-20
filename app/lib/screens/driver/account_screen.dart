import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payProv = context.watch<PaymentProvider>();
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFCD34D),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.black, size: 20),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Account',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/driver-profile'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Balance
                GestureDetector(
                  onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total balance',
                        style: const TextStyle(fontSize: 12, color: AppColors.black),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 16,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBalanceVisible ? '\$${payProv.totalEarnings.toStringAsFixed(2)}' : '****',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    final isSelected = _selectedActionIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedActionIndex = index);
                        if (index == 1) {
                          context.push('/withdraw-method');
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFF6B6B3D)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppColors.black.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Icon(
                                _actionIcons[index],
                                color: isSelected ? AppColors.white : AppColors.black,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _actionLabels[index],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Tabs or "View all"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _selectedActionIndex == 2
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View all',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_tabLabels.length, (index) {
                      final isSelected = _selectedTabIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              _tabLabels[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.black
                                    : (isDark ? Colors.grey.shade400 : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  ),
              ),

          // Transaction List
          Expanded(
            child: payProv.transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: payProv.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = payProv.transactions[index];
                      final bool isOutgoing = tx['type'] == 'withdrawal';
                      final amount = tx['amount'] ?? 0;
                      final date = tx['created_at'] != null
                          ? DateTime.tryParse(tx['created_at'])?.toLocal().toString().split(' ')[0] ?? ''
                          : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOutgoing ? Icons.arrow_outward : Icons.south_west,
                                size: 18,
                                color: isDark ? AppColors.white : AppColors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOutgoing ? 'Withdrawal' : 'Ride Payment',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.white : AppColors.black,
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isOutgoing ? "-" : "+"}\$$amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isOutgoing ? Colors.red : (isDark ? Colors.greenAccent : Colors.green.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
