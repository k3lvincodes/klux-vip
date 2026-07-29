import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class WithdrawMethodScreen extends StatefulWidget {
  const WithdrawMethodScreen({super.key});

  @override
  State<WithdrawMethodScreen> createState() => _WithdrawMethodScreenState();
}

class _WithdrawMethodScreenState extends State<WithdrawMethodScreen> {
  int _selectedIndex = 0;

  final List<_MethodItem> _methods = [
    _MethodItem(
      icon: Icons.account_balance,
      iconColor: AppColors.white,
      iconBg: AppColors.primary,
      title: 'Bank transfer',
      subtitle: 'Support 180+ currencies',
    ),
    _MethodItem(
      icon: Icons.circle,
      iconColor: Colors.orange,
      iconBg: Colors.transparent,
      title: 'Payoneer',
      subtitle: 'Coming soon',
      isDisabled: true,
    ),
    _MethodItem(
      icon: Icons.circle,
      iconColor: Colors.blue,
      iconBg: Colors.transparent,
      title: 'Coinbase',
      subtitle: 'Coming soon',
      isDisabled: true,
    ),
    _MethodItem(
      icon: Icons.circle,
      iconColor: Colors.lightBlue,
      iconBg: Colors.transparent,
      title: 'Paypal',
      subtitle: 'Coming soon',
      isDisabled: true,
    ),
  ];

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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
                    ),
                    Expanded(
                      child: Text(
                        'Withdrawal Method',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'Select a withdraw method',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Method list
                ...List.generate(_methods.length, (index) {
                  final method = _methods[index];
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: method.isDisabled
                        ? null
                        : () {
                            setState(() => _selectedIndex = index);
                            if (index == 0) {
                              context.push('/add-bank-account');
                            }
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFF5F0EF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          if (index == 0)
                            Icon(Icons.account_balance, color: isSelected ? AppColors.white : AppColors.black, size: 28)
                          else
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: method.iconColor, width: 3),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.white : AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? AppColors.white.withValues(alpha: 0.5) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodItem {

  _MethodItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.isDisabled = false,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isDisabled;
}

