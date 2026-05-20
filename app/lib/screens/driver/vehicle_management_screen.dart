import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/repositories/vehicle_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final VehicleRepository _repo = VehicleRepository();
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final vehicles = await _repo.getDriverVehicles(user.id);
      if (mounted) setState(() => _vehicles = vehicles);
    } catch (_) {
      if (mounted) setState(() => _vehicles = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setActive(String vehicleId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _repo.setActiveVehicle(user.id, vehicleId);
    _fetchVehicles();
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    await _repo.deleteVehicle(vehicleId);
    _fetchVehicles();
  }

  void _showAddVehicleSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 24),
                  Text('Add Vehicle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.black)),
                  const SizedBox(height: 24),
                  _buildField(makeCtrl, 'Make', 'e.g. Toyota', isDark),
                  const SizedBox(height: 12),
                  _buildField(modelCtrl, 'Model', 'e.g. Camry', isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField(yearCtrl, 'Year', 'e.g. 2024', isDark, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField(colorCtrl, 'Color', 'e.g. Black', isDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(plateCtrl, 'License Plate', 'e.g. ABC-1234', isDark),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) return;
                        await _repo.registerVehicle(
                          driverId: user.id,
                          make: makeCtrl.text.trim(),
                          model: modelCtrl.text.trim(),
                          year: int.parse(yearCtrl.text.trim()),
                          color: colorCtrl.text.trim(),
                          licensePlate: plateCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchVehicles();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Save Vehicle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint, bool isDark, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 14, color: isDark ? AppColors.white : AppColors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
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
        title: Text('Vehicle Management', style: TextStyle(color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: isDark ? AppColors.white : AppColors.black),
            onPressed: _showAddVehicleSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No vehicles registered', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddVehicleSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add your first vehicle'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final v = _vehicles[index];
                      final isActive = v['is_active'] == true;
                      final make = v['make'] ?? '';
                      final model = v['model'] ?? '';
                      final year = v['year'] ?? '';
                      final color = v['color'] ?? '';
                      final plate = v['license_plate'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.primary.withValues(alpha: 0.15) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.directions_car, color: isActive ? AppColors.black : (isDark ? AppColors.white : Colors.black54), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$make $model', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.black)),
                                      Text('$year  $color', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                    child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.black)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.confirmation_number, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 8),
                                  Text(plate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: isDark ? AppColors.white : AppColors.black)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (!isActive)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _setActive(v['id']),
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: const Text('Set Active', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ),
                                if (!isActive) const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
                                        title: const Text('Delete Vehicle'),
                                        content: const Text('Are you sure you want to remove this vehicle?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _deleteVehicle(v['id']);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: BorderSide(color: Colors.red.shade300),
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
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
    );
  }
}
