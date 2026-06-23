import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/vehicle.dart';
import 'package:kenick_vip/repositories/vehicle_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  bool _isLoading = true;
  Vehicle? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final vehicle = await VehicleRepository().getActiveVehicle(user.id);
        if (mounted) {
          setState(() {
            _vehicle = vehicle;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomToast.showError(context, 'Failed to load vehicle info');
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vehicle Information',
          style: TextStyle(color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/vehicle-management'),
            icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
            label: const Text('Manage', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _vehicle == null
            ? _buildEmptyState(isDark)
            : _buildVehicleDetails(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No vehicle registered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Register a vehicle to start accepting rides.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/vehicle-management'),
              icon: const Icon(Icons.add),
              label: const Text('Register Vehicle'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetails(bool isDark) {
    final String make = _vehicle?.make ?? '';
    final String model = _vehicle?.model ?? '';
    final int year = _vehicle?.year ?? 0;
    final String color = _vehicle?.color ?? '';
    final String licensePlate = _vehicle?.licensePlate ?? '';
    final List<String> images = _vehicle?.images ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (images.isNotEmpty)
            Container(
              height: 180,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(images.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          _buildDetailCard(isDark, [
            _buildDetailRow(Icons.directions_car, 'Make', make, isDark),
            _buildDetailRow(Icons.model_training, 'Model', model, isDark),
            _buildDetailRow(Icons.calendar_today, 'Year', year.toString(), isDark),
            _buildDetailRow(Icons.palette, 'Color', color, isDark),
            _buildDetailRow(Icons.confirmation_number, 'License Plate', licensePlate, isDark),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/vehicle-management'),
              icon: Icon(Icons.edit, size: 18, color: isDark ? AppColors.white : AppColors.black),
              label: Text('Manage Vehicles', style: TextStyle(color: isDark ? AppColors.white : AppColors.black)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: isDark ? Colors.grey.shade700 : AppColors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
