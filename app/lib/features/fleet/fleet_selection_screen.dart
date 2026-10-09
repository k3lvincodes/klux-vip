import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/services/fleet_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';

class FleetSelectionScreen extends StatefulWidget {
  const FleetSelectionScreen({super.key});

  @override
  State<FleetSelectionScreen> createState() => _FleetSelectionScreenState();
}

class _FleetSelectionScreenState extends State<FleetSelectionScreen> {
  List<FleetVehicleItem> _fleetCars = [];
  bool _isLoading = true;
  String? _selectedCarId;

  @override
  void initState() {
    super.initState();
    final bookingProv = context.read<BookingProvider>();
    _selectedCarId = bookingProv.vehicleType;
    _fetchFleetCars();
  }

  Future<void> _fetchFleetCars() async {
    setState(() => _isLoading = true);
    final cars = await FleetService.getAllFleetCarsWithChauffeurStatus();
    if (mounted) {
      setState(() {
        _fleetCars = cars;
        _isLoading = false;
      });
    }
  }

  void _onSelectVehicle(FleetVehicleItem vehicle) {
    if (!vehicle.hasDriverAssigned) {
      CustomToast.showError(
        context,
        'No chauffeur is available for this car at the moment. Please select another vehicle or choose Any VIP Vehicle.',
      );
      return;
    }

    setState(() => _selectedCarId = vehicle.name);
    final bookingProv = context.read<BookingProvider>();
    bookingProv.setVehicle(
      vehicle.name,
      vehicle.imageUrl ?? vehicle.localAssetPath,
    );
    CustomToast.showSuccess(
      context,
      '${vehicle.name} selected with chauffeur assigned.',
    );
    Navigator.of(context).pop(vehicle);
  }

  void _onSelectAnyVehicle() {
    setState(() => _selectedCarId = 'Any VIP Vehicle');
    final bookingProv = context.read<BookingProvider>();
    final defaultImage = _fleetCars.isNotEmpty
        ? (_fleetCars.first.imageUrl ?? _fleetCars.first.localAssetPath)
        : 'assets/images/GMC.png';

    bookingProv.setVehicle('Any VIP Vehicle', defaultImage);
    CustomToast.showSuccess(
      context,
      'Any VIP Vehicle selected (Fastest Chauffeur Match).',
    );
    Navigator.of(context).pop(
      FleetVehicleItem(
        id: 'any_vip',
        name: 'Any VIP Vehicle',
        make: 'VIP',
        model: 'Fleet',
        year: 2024,
        localAssetPath: 'assets/images/GMC.png',
        hasDriverAssigned: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ),
        title: Text(
          'Executive Fleet',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.white : AppColors.black,
            ),
            tooltip: 'Refresh Fleet',
            onPressed: _fetchFleetCars,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Executive Fleet...',
                    style: tt.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchFleetCars,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  Text(
                    'Select Your Vehicle',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an executive car with an active chauffeur ready for dispatch.',
                    style: tt.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Option: Any VIP Vehicle
                  _buildAnyVehicleCard(isDark, cs, tt),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'VIP Fleet Catalog',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_fleetCars.length} Vehicles',
                        style: tt.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Car list
                  ..._fleetCars.map((car) => _buildFleetCard(car, isDark, cs, tt)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAnyVehicleCard(bool isDark, ColorScheme cs, TextTheme tt) {
    final isSelected = _selectedCarId == null ||
        _selectedCarId == 'Any VIP Vehicle' ||
        _selectedCarId == 'any_vip';

    return GestureDetector(
      onTap: _onSelectAnyVehicle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Any VIP Vehicle',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Fastest',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Automatically match with nearest available chauffeur',
                    style: tt.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white30 : Colors.black26),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildFleetCard(
    FleetVehicleItem car,
    bool isDark,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final isSelected = _selectedCarId == car.name;
    final hasChauffeur = car.hasDriverAssigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white10 : Colors.black12),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onSelectVehicle(car),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header: Make/Model + Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.name,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${car.year} • Executive Luxury',
                            style: tt.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildChauffeurStatusPill(hasChauffeur, isDark),
                  ],
                ),
                const SizedBox(height: 12),

                // Vehicle Image
                Center(
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: car.imageUrl != null && car.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: car.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (ctx, _) => Image.asset(
                              car.localAssetPath,
                              fit: BoxFit.contain,
                            ),
                            errorWidget: (ctx, url, err) => Image.asset(
                              car.localAssetPath,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            car.localAssetPath,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),

                if (car.features.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: car.features.split(',').take(3).map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          f.trim(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                const SizedBox(height: 12),

                // Action / Select button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasChauffeur ? 'Chauffeur on standby' : 'Currently unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasChauffeur
                            ? (isDark ? Colors.white70 : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasChauffeur
                            ? (isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.black87))
                            : (isDark ? Colors.white10 : Colors.black12),
                        foregroundColor: hasChauffeur
                            ? (isSelected ? AppColors.black : AppColors.white)
                            : Colors.grey,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _onSelectVehicle(car),
                      child: Text(
                        hasChauffeur
                            ? (isSelected ? 'Selected' : 'Select Car')
                            : 'Unavailable',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChauffeurStatusPill(bool hasChauffeur, bool isDark) {
    if (hasChauffeur) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
            SizedBox(width: 4),
            Text(
              'Chauffeur Available',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 12, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'No Chauffeur Available',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
