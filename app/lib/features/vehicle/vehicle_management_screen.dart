import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/fleet_car.dart';
import 'package:kenick_vip/models/vehicle.dart';
import 'package:kenick_vip/repositories/vehicle_repository.dart';
import 'package:kenick_vip/services/ai_vehicle_service.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final VehicleRepository _repo = VehicleRepository();
  List<FleetCar> _fleetCars = [];
  Vehicle? _activeVehicle;
  List<Map<String, dynamic>> _myRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch active assigned vehicle
      final active = await _repo.getActiveVehicle(user.id);

      // 2. Fetch fleet catalog from admin
      final fleetRaw = await _repo.getFleetCars();
      final fleet = fleetRaw.map((e) => FleetCar.fromJson(e)).toList();

      // If fleet catalog is empty in DB, provide default flagship Kenick cars
      if (fleet.isEmpty) {
        fleet.addAll([
          FleetCar(
            id: 'fc-cadillac-1',
            make: 'Cadillac',
            model: 'Escalade Platinum',
            year: 2024,
            features: 'Panoramic Sunroof, Massaging Seats, Wi-Fi, Privacy Glass',
            isFeatured: true,
            createdAt: DateTime.now(),
          ),
          FleetCar(
            id: 'fc-gmc-1',
            make: 'GMC',
            model: 'Yukon Denali XL',
            year: 2024,
            features: 'Rear Entertainment, Executive Seating, Chilled Console',
            isFeatured: true,
            createdAt: DateTime.now(),
          ),
          FleetCar(
            id: 'fc-ford-1',
            make: 'Ford',
            model: 'Expedition Max Stealth',
            year: 2023,
            features: 'Executive Captain Chairs, Luxury Audio, Tinted Windows',
            createdAt: DateTime.now(),
          ),
        ]);
      }

      // 3. Fetch custom proposals
      final requests = await _repo.getDriverVehicleRequests(user.id);

      if (mounted) {
        setState(() {
          _activeVehicle = active;
          _fleetCars = fleet;
          _myRequests = requests;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load fleet catalog');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Opens dialog to input license plate and activate a fleet car for shift
  void _promptSelectFleetCar(FleetCar car) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final plateCtrl = TextEditingController(
      text: _activeVehicle != null &&
              _activeVehicle!.make.toLowerCase() == car.make.toLowerCase()
          ? _activeVehicle!.licensePlate
          : '',
    );
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                ),
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
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.verified, color: colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select for Active Shift',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${car.year} ${car.make} ${car.model}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Authorized Kenick VIP Fleet Vehicle. Exterior: Obsidian Black.',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Assigned License Plate',
                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. VIP-8842',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          letterSpacing: 1,
                        ),
                        prefixIcon: Icon(Icons.tag, color: colorScheme.primary),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter the vehicle license plate';
                        }
                        if (v.trim().length < 3) {
                          return 'Enter a valid license plate';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                final user = Supabase.instance.client.auth.currentUser;
                                if (user == null) return;

                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _repo.selectFleetCarForDriver(
                                    driverId: user.id,
                                    fleetCarId: car.id,
                                    make: car.make,
                                    model: car.model,
                                    year: car.year,
                                    licensePlate: plateCtrl.text.trim().toUpperCase(),
                                    imageUrl: car.imageUrl,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (!mounted) return;
                                  CustomToast.showSuccess(
                                    context,
                                    '${car.make} ${car.model} activated for shift!',
                                  );
                                  _loadData();
                                } catch (e) {
                                  setSheetState(() => isSubmitting = false);
                                  if (!mounted) return;
                                  CustomToast.showError(
                                    context,
                                    'Failed to activate vehicle: $e',
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 2,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Activate for Active Shift',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Propose Custom VIP Vehicle with real-time Gemini AI vetting
  void _showProposeVehicleSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: DateTime.now().year.toString());
    final plateCtrl = TextEditingController();
    String selectedColor = 'Black';
    bool isEvaluating = false;

    final colors = [
      'Black',
      'White',
      'Silver',
      'Gray',
      'Midnight Blue',
      'Red',
      'Champagne Gold',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFD4AF37),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Propose Custom VIP Vehicle',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Vetted in real-time by Kenick Gemini AI',
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kenick VIP Protocol: Only Obsidian/Metallic Black exterior and Tier-1 Executive vehicles (Escalade, S-Class, Yukon Denali, Navigator) pass AI vetting.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Vehicle Make', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: makeCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Cadillac, Mercedes-Benz, GMC, Lincoln',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Model', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: modelCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Escalade Platinum, S580, Yukon Denali',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Model Year', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: yearCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'e.g. 2024',
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerLowest,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('License Plate', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: plateCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'e.g. VIP-7788',
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerLowest,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Exterior Color', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        final isBlack = c == 'Black';
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c == 'Black'
                                      ? Colors.black
                                      : c == 'White'
                                          ? Colors.white
                                          : c == 'Silver'
                                              ? Colors.grey.shade400
                                              : c == 'Midnight Blue'
                                                  ? Colors.blue.shade900
                                                  : c == 'Red'
                                                      ? Colors.red
                                                      : Colors.amber,
                                  border: Border.all(color: Colors.grey.shade600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(c),
                              if (isBlack) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star, size: 12, color: Color(0xFFD4AF37)),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedColor = c);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isEvaluating
                            ? null
                            : () async {
                                final make = makeCtrl.text.trim();
                                final model = modelCtrl.text.trim();
                                final year = int.tryParse(yearCtrl.text.trim());
                                final plate = plateCtrl.text.trim();

                                if (make.isEmpty || model.isEmpty || year == null || plate.isEmpty) {
                                  CustomToast.showError(context, 'Please complete all vehicle fields');
                                  return;
                                }

                                setSheetState(() => isEvaluating = true);

                                // Real-time AI Fleet Evaluation
                                final result = await AiVehicleService.evaluateVehicle(
                                  make: make,
                                  model: model,
                                  year: year,
                                  color: selectedColor,
                                );

                                setSheetState(() => isEvaluating = false);

                                if (!mounted) return;

                                if (!result.isApproved) {
                                  // DECLINED BY AI - DISCARD & EXPLAIN REASON
                                  _showAiDeclinedDialog(
                                    make: make,
                                    model: model,
                                    color: selectedColor,
                                    reason: result.reason,
                                  );
                                } else {
                                  // APPROVED BY AI - SUBMIT TO ADMIN
                                  final user = Supabase.instance.client.auth.currentUser;
                                  if (user != null) {
                                    try {
                                      await _repo.submitVehicleRequest(
                                        chauffeurId: user.id,
                                        make: make,
                                        model: model,
                                        year: year,
                                        color: selectedColor,
                                        licensePlate: plate.toUpperCase(),
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (!mounted) return;
                                      _showAiApprovedDialog(
                                        make: make,
                                        model: model,
                                        year: year,
                                        tier: result.executiveTier,
                                        reason: result.reason,
                                      );
                                      _loadData();
                                    } catch (e) {
                                      if (!mounted) return;
                                      CustomToast.showError(context, 'Failed to save submission: $e');
                                    }
                                  }
                                }
                              },
                        icon: isEvaluating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome, size: 20),
                        label: Text(
                          isEvaluating ? 'Gemini AI Evaluating...' : 'Submit for AI Inspection',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAiDeclinedDialog({
    required String make,
    required String model,
    required String color,
    required String reason,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.block, color: colorScheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Declined by Fleet AI',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$color $make $model',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reason,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Discarded: Non-compliant vehicles are not forwarded to admin.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understand'),
          ),
        ],
      ),
    );
  }

  void _showAiApprovedDialog({
    required String make,
    required String model,
    required int year,
    required String tier,
    required String reason,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Color(0xFFD4AF37), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Inspection Passed',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$year $make $model (Black)',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (tier.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tier,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                reason,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your request has been forwarded to the Kenick Fleet Admin with AI VIP certification.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVehicleHero() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_activeVehicle == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.car_crash_outlined, color: colorScheme.error, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Vehicle Selected for Shift',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an authorized Kenick VIP vehicle from the fleet catalog below to start accepting rides.',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final v = _activeVehicle!;
    // Find matched fleet car if any to get asset or image
    final matchedFleet = _fleetCars.where((f) =>
        f.id == v.fleetCarId ||
        (f.make.toLowerCase() == v.make.toLowerCase() &&
         f.model.toLowerCase() == v.model.toLowerCase())).firstOrNull;

    final assetPath = matchedFleet?.assetFallback ?? 'assets/images/cadillac.png';
    final imageUrl = v.images.isNotEmpty ? v.images.first : matchedFleet?.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ACTIVE SHIFT VEHICLE · READY FOR DISPATCH',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.check_circle, size: 16, color: Color(0xFFD4AF37)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    // Vehicle Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 110,
                        height: 75,
                        color: Colors.black.withValues(alpha: 0.4),
                        child: imageUrl != null && imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                errorWidget: (context, url, error) => Image.asset(assetPath, fit: BoxFit.contain),
                              )
                            : Image.asset(assetPath, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${v.year} ${v.make} ${v.model}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Exterior: Obsidian Black',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Embossed plate styling
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pin, size: 14, color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  v.licensePlate,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetCard(FleetCar car) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isActive = _activeVehicle != null &&
        (_activeVehicle!.fleetCarId == car.id ||
         (_activeVehicle!.make.toLowerCase() == car.make.toLowerCase() &&
          _activeVehicle!.model.toLowerCase() == car.model.toLowerCase()));

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Tier & Feature
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    car.tierLabel.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                ),
                const Spacer(),
                if (car.isFeatured)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 4),
                      Text(
                        'Featured Flagship',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Large High-Res Vehicle Photo Presentation
          Container(
            width: double.infinity,
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: car.imageUrl != null && car.imageUrl!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: car.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => Image.asset(car.assetFallback, fit: BoxFit.contain),
                    )
                  : Image.asset(
                      car.assetFallback,
                      fit: BoxFit.contain,
                      height: 130,
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.displayName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                // Specs pill row
                Row(
                  children: [
                    _buildSpecChip(Icons.people_outline, '${car.passengerCapacity} Seats'),
                    const SizedBox(width: 8),
                    _buildSpecChip(Icons.luggage_outlined, '${car.luggageCapacity} Luggage'),
                    const SizedBox(width: 8),
                    _buildSpecChip(Icons.circle, 'Black Only', iconColor: Colors.black),
                  ],
                ),
                if (car.features != null && car.features!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    car.features!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: isActive ? null : () => _promptSelectFleetCar(car),
                    icon: Icon(
                      isActive ? Icons.check_circle : Icons.directions_car,
                      size: 18,
                    ),
                    label: Text(
                      isActive ? 'Active on Current Shift' : 'Select for Shift',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primary,
                      foregroundColor: isActive
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String text, {Color? iconColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection() {
    if (_myRequests.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Your Proposed Vehicles',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ..._myRequests.map((req) {
          final status = req['status'] as String? ?? 'pending';
          final make = req['make'] ?? '';
          final model = req['model'] ?? '';
          final year = req['year'] ?? '';
          final isPending = status == 'pending';
          final isApproved = status == 'approved';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.withValues(alpha: 0.15)
                        : isPending
                            ? Colors.amber.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isApproved
                        ? Icons.check_circle
                        : isPending
                            ? Icons.hourglass_top
                            : Icons.cancel,
                    size: 20,
                    color: isApproved
                        ? Colors.green
                        : isPending
                            ? Colors.amber
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$year $make $model',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Plate: ${req['license_plate'] ?? ''} · Color: ${req['color'] ?? ''}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.withValues(alpha: 0.2)
                        : isPending
                            ? Colors.amber.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isApproved
                          ? Colors.green
                          : isPending
                              ? Colors.amber.shade800
                              : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
        title: Text(
          'Fleet & Vehicle Selection',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Propose Custom Vehicle',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            onPressed: _showProposeVehicleSheet,
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
                      TextButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Active Shift Vehicle
                      _buildActiveVehicleHero(),

                      // Section Title & Propose Button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Authorized Admin Fleet',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select an approved vehicle for your shift',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _showProposeVehicleSheet,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Propose Car', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD4AF37),
                              side: const BorderSide(color: Color(0xFFD4AF37)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fleet Catalog Cards
                      ..._fleetCars.map((car) => _buildFleetCard(car)),

                      // Chauffeur's previous custom proposals if any
                      _buildRequestsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}
