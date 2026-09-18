import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/fleet_car.dart';
import 'package:kenick_vip/repositories/vehicle_repository.dart';
import 'package:kenick_vip/services/ai_vehicle_service.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final VehicleRepository _repo = VehicleRepository();
  List<FleetCar> _fleetCars = [];
  FleetCar? _selectedFleetCar;
  final TextEditingController _plateController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Custom proposal fields
  bool _isCustomMode = false;
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _customPlateCtrl = TextEditingController();
  String _selectedColor = 'Black';
  bool _isEvaluatingAi = false;

  final List<String> _colors = [
    'Black',
    'White',
    'Silver',
    'Gray',
    'Midnight Blue',
    'Red',
  ];

  @override
  void initState() {
    super.initState();
    _fetchFleet();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _customPlateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFleet() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _repo.getFleetCars();
      final fleet = raw.map((e) => FleetCar.fromJson(e)).toList();

      if (fleet.isEmpty) {
        fleet.addAll([
          FleetCar(
            id: 'fc-cadillac-1',
            make: 'Cadillac',
            model: 'Escalade Platinum',
            year: 2024,
            features: 'Massaging Seats, Panoramic Glass, Luxury Sound',
            isFeatured: true,
            createdAt: DateTime.now(),
          ),
          FleetCar(
            id: 'fc-gmc-1',
            make: 'GMC',
            model: 'Yukon Denali XL',
            year: 2024,
            features: 'Executive Captain Chairs, Chilled Console',
            isFeatured: true,
            createdAt: DateTime.now(),
          ),
          FleetCar(
            id: 'fc-ford-1',
            make: 'Ford',
            model: 'Expedition Max Stealth',
            year: 2023,
            features: 'Executive Seating, High-Performance Audio',
            createdAt: DateTime.now(),
          ),
        ]);
      }

      if (mounted) {
        setState(() {
          _fleetCars = fleet;
          if (fleet.isNotEmpty) _selectedFleetCar = fleet.first;
        });
      }
    } catch (_) {
      // Fallback already handled
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFleetCarSubmit() async {
    if (_selectedFleetCar == null) {
      CustomToast.showError(context, 'Please select an authorized fleet vehicle');
      return;
    }

    final plate = _plateController.text.trim();
    if (plate.isEmpty || plate.length < 3) {
      CustomToast.showError(context, 'Please enter a valid license plate number');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _repo.selectFleetCarForDriver(
        driverId: user.id,
        fleetCarId: _selectedFleetCar!.id,
        make: _selectedFleetCar!.make,
        model: _selectedFleetCar!.model,
        year: _selectedFleetCar!.year,
        licensePlate: plate.toUpperCase(),
        imageUrl: _selectedFleetCar!.imageUrl,
      );

      if (mounted) {
        CustomToast.showSuccess(
          context,
          '${_selectedFleetCar!.make} ${_selectedFleetCar!.model} activated for duty!',
        );
        context.go('/driver-home');
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to assign vehicle: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleCustomProposalSubmit() async {
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final year = int.tryParse(_yearCtrl.text.trim());
    final plate = _customPlateCtrl.text.trim();

    if (make.isEmpty || model.isEmpty || year == null || plate.isEmpty) {
      CustomToast.showError(context, 'Please fill out all custom vehicle details');
      return;
    }

    setState(() => _isEvaluatingAi = true);

    // AI inspection
    final result = await AiVehicleService.evaluateVehicle(
      make: make,
      model: model,
      year: year,
      color: _selectedColor,
    );

    setState(() => _isEvaluatingAi = false);

    if (!mounted) return;

    if (!result.isApproved) {
      // Declined by AI
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.block, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              const Text('Declined by Fleet AI'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_selectedColor $make $model', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(result.reason),
              const SizedBox(height: 10),
              const Text(
                'Discarded: Non-compliant requests are discarded and not forwarded to admin.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    } else {
      // Approved by AI -> Submit to DB
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _repo.submitVehicleRequest(
          chauffeurId: user.id,
          make: make,
          model: model,
          year: year,
          color: _selectedColor,
          licensePlate: plate.toUpperCase(),
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
                  SizedBox(width: 10),
                  Text('AI Inspection Passed'),
                ],
              ),
              content: Text(
                'Your proposal for $year $make $model in Obsidian Black has been submitted to the Fleet Admin for final review.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/driver-home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Continue to Dashboard'),
                ),
              ],
            ),
          );
        }
      }
    }
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
          'Vehicle Assignment',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Mode Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isCustomMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isCustomMode
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Admin Fleet',
                                    style: textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: !_isCustomMode
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isCustomMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isCustomMode
                                      ? const Color(0xFFD4AF37)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 14,
                                        color: _isCustomMode ? Colors.black : const Color(0xFFD4AF37),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Propose Custom',
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _isCustomMode
                                              ? Colors.black
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!_isCustomMode) ...[
                      // Admin Fleet Mode
                      Text(
                        'Select Your Fleet Vehicle',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select an authorized executive VIP car from the Kenick fleet.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fleet list cards
                      ..._fleetCars.map((car) {
                        final isSelected = _selectedFleetCar?.id == car.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFleetCar = car),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Vehicle Photo
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 100,
                                      height: 70,
                                      color: Colors.black.withValues(alpha: 0.4),
                                      child: car.imageUrl != null && car.imageUrl!.startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: car.imageUrl!,
                                              fit: BoxFit.contain,
                                              errorWidget: (context, url, error) => Image.asset(car.assetFallback, fit: BoxFit.contain),
                                            )
                                          : Image.asset(car.assetFallback, fit: BoxFit.contain),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          car.displayName,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${car.passengerCapacity} Passengers · ${car.luggageCapacity} Luggage',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Obsidian Black',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: const Color(0xFFD4AF37),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      Text(
                        'Assigned License Plate',
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. VIP-1029',
                          prefixIcon: Icon(Icons.tag, color: colorScheme.primary),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleFleetCarSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Confirm & Start Driving', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // Custom Proposal Mode (AI Vetted)
                      Text(
                        'Propose Your Own Vehicle',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vehicle must have an Obsidian Black exterior and meet executive luxury standards.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _makeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Make (e.g. Cadillac, Mercedes-Benz, GMC)',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _modelCtrl,
                        decoration: InputDecoration(
                          labelText: 'Model (e.g. Escalade, S-Class, Yukon Denali)',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _yearCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Year (Min 2018)',
                                filled: true,
                                fillColor: colorScheme.surfaceContainerLowest,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _customPlateCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'License Plate',
                                filled: true,
                                fillColor: colorScheme.surfaceContainerLowest,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Exterior Color (Black Only)', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _colors.map((c) {
                          final isSelected = _selectedColor == c;
                          return ChoiceChip(
                            label: Text(c),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedColor = c);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isEvaluatingAi ? null : _handleCustomProposalSubmit,
                          icon: _isEvaluatingAi
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, color: Colors.black),
                          label: Text(
                            _isEvaluatingAi ? 'AI Evaluating...' : 'Submit for AI Inspection',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/driver-home'),
                        child: Text(
                          'Skip for now',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
