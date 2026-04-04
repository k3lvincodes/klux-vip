import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/payment_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedActionIndex = 0; // 0=Earnings, 1=Withdraw, 2=History
  int _selectedTabIndex = 0; // 0=Earnings, 1=Bonuses, 2=Commission

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
    final payProv = context.watch<PaymentProvider>();
    return Scaffold(
      body: Column(
        children: [
          // Yellow Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Top Row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios, color: AppColors.black),
                    ),
                    const Expanded(
                      child: Text(
                        'Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Balance
                const Text(
                  'Total balance 👁',
                  style: TextStyle(fontSize: 12, color: AppColors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${payProv.totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Icons (Earnings, Withdraw, History)
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
                      child: Column(
                        children: [
                          Container(
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
                    );
                  }),
                ),
              ],
            ),
          ),

          // Tabs (Earnings, Bonuses, Commission) or "View all"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _selectedActionIndex == 2
                ? const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View all',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  )
                : Row(
                    children: List.generate(_tabLabels.length, (index) {
                      final isSelected = _selectedTabIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              _tabLabels[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? AppColors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
          ),

          // Transaction List
          Expanded(
            child: payProv.transactions.isEmpty
                ? const Center(child: Text('No transactions yet'))
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
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isOutgoing
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.primary.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOutgoing
                              ? Icons.arrow_outward
                              : Icons.south_west,
                          size: 18,
                          color: AppColors.black,
                        ),
                      ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOutgoing ? 'Withdrawal' : 'Ride Payment',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOutgoing ? Colors.red : AppColors.black,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
