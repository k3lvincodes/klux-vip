import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';

class DriverRideHistoryScreen extends StatelessWidget {
  const DriverRideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title:  Text('Driver Ride History', style: TextStyle(color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text('Completed trips will appear here.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    );
  }
}


