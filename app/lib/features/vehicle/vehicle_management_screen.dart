import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/vehicle.dart';
import 'package:kenick_vip/repositories/vehicle_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final VehicleRepository _repo = VehicleRepository();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _error;

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
    } catch (e) {
      if (mounted) setState(() { _vehicles = []; _error = 'Failed to load vehicles'; });
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Add Vehicle',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildField(makeCtrl, 'Make', 'e.g. Toyota', colorScheme, textTheme),
                  const SizedBox(height: 12),
                  _buildField(modelCtrl, 'Model', 'e.g. Camry', colorScheme, textTheme),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField(yearCtrl, 'Year', 'e.g. 2024', colorScheme, textTheme, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField(colorCtrl, 'Color', 'e.g. Black', colorScheme, textTheme)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(plateCtrl, 'License Plate', 'e.g. ABC-1234', colorScheme, textTheme),
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
                          images: [],
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchVehicles();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('Save Vehicle', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
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

  Widget _buildField(TextEditingController ctrl, String label, String hint, ColorScheme colorScheme, TextTheme textTheme, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Vehicle Management', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: colorScheme.onSurface),
            onPressed: _showAddVehicleSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _fetchVehicles, child: const Text('Retry')),
                    ],
                  ),
                )
              : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No vehicles registered', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                      final isActive = v.isActive;
                      final make = v.make;
                      final model = v.model;
                      final year = v.year;
                      final color = v.color;
                      final plate = v.licensePlate;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.directions_car, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$make $model', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                        Text('$year  $color', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                                      child: Text('Active', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.confirmation_number, size: 14, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Text(plate, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.5, color: colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (!isActive)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _setActive(v.id),
                                        icon: const Icon(Icons.check_circle_outline, size: 16),
                                        label: const Text('Set Active', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          side: BorderSide(color: colorScheme.primary),
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
                                          backgroundColor: colorScheme.surfaceContainerLow,
                                          title: const Text('Delete Vehicle'),
                                          content: const Text('Are you sure you want to remove this vehicle?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteVehicle(v.id);
                                              },
                                              child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: BorderSide(color: colorScheme.error),
                                        foregroundColor: colorScheme.error,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
