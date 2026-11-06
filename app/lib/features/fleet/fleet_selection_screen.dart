import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/features/rewards/offers_rewards_screen.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/services/currency_service.dart';
import 'package:kenick_vip/services/fleet_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';

/// "Your experience" screen matching reference designs (Images 1, 4, 5):
///   - Top header with circular back button and "Your experience" title
///   - Swipeable card carousel displaying the VIP categories:
///       • Sedans (mint gradient, 3 pax, 2 bags)
///       • SUVs   (blue gradient, 5 pax, 4 bags)
///       • Vans   (peach gradient, 7 pax, 6 bags)
///       • Buses  (purple gradient, 16 pax, 14 bags)
///   - Under card: vehicle subtitle, subtle divider, and "+ Apply offer" button
///   - Bottom CTA button: "Select Category Name"
///
/// Strictly complies with rules.json:
///   - GoogleFonts.poppins typography with restrained boldness (w500 / w600)
///   - Kenick primary gold (#EAB308 / AppColors.primary)
///   - "ride" nomenclature throughout
class FleetSelectionScreen extends StatefulWidget {
  const FleetSelectionScreen({super.key});

  @override
  State<FleetSelectionScreen> createState() => _FleetSelectionScreenState();
}

class _FleetSelectionScreenState extends State<FleetSelectionScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<FleetVehicleItem> _fleetCars = [];
  bool _isLoading = true;

  // Track the currently displayed car index for each category
  final Map<String, int> _categoryCarIndex = {};
  Timer? _carCycleTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _fetchFleetCars();
  }

  @override
  void dispose() {
    _carCycleTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchFleetCars() async {
    setState(() => _isLoading = true);
    final cars = await FleetService.getAllFleetCarsWithChauffeurStatus();
    if (mounted) {
      setState(() {
        _fleetCars = cars;
        _isLoading = false;

        final availableCategories = FleetService.experienceCategories
            .where((tier) => _fleetCars.any((c) => c.category == tier.name))
            .toList();

        // Initialize random car index for each available category tier from real fleet
        final random = math.Random();
        for (final tier in availableCategories) {
          final tierCars = _fleetCars.where((c) => c.category == tier.name).toList();
          if (tierCars.isNotEmpty) {
            _categoryCarIndex[tier.name] = random.nextInt(tierCars.length);
          }
        }

        if (_currentPage >= availableCategories.length) {
          _currentPage = math.max(0, availableCategories.length - 1);
        }
      });

      _startCarCycleTimer();
    }
  }

  void _startCarCycleTimer() {
    _carCycleTimer?.cancel();
    // Smoothly cycle cars every 4 seconds to showcase real fleet options
    _carCycleTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final availableCategories = FleetService.experienceCategories
          .where((tier) => _fleetCars.any((c) => c.category == tier.name))
          .toList();
      setState(() {
        for (final tier in availableCategories) {
          final tierCars = _fleetCars.where((c) => c.category == tier.name).toList();
          if (tierCars.length > 1) {
            final current = _categoryCarIndex[tier.name] ?? 0;
            _categoryCarIndex[tier.name] = (current + 1) % tierCars.length;
          }
        }
      });
    });
  }

  double _calculateFareForTier(FleetCategoryTier tier, double baseAmount) {
    if (baseAmount <= 0) {
      // Default baseline pricing matching design reference: €141.47 for 2h
      return (141.47 * tier.priceMultiplier);
    }
    return (baseAmount * tier.priceMultiplier);
  }

  FleetVehicleItem? _getActiveCarForTier(FleetCategoryTier tier) {
    final tierCars = _fleetCars.where((c) => c.category == tier.name).toList();
    if (tierCars.isEmpty) return null;
    final idx = (_categoryCarIndex[tier.name] ?? 0) % tierCars.length;
    return tierCars[idx];
  }

  void _openCategoryCars(FleetCategoryTier tier) {
    HapticFeedback.lightImpact();
    final bookingProv = context.read<BookingProvider>();
    final baseFare = bookingProv.fareAmount ?? 141.47;

    context.push(
      '/fleet/category-cars',
      extra: {
        'tier': tier,
        'cars': _fleetCars.where((c) => c.category == tier.name).toList(),
        'baseFare': baseFare,
      },
    );
  }

  void _onSelectExperience(FleetCategoryTier tier) {
    final bookingProv = context.read<BookingProvider>();
    final baseFare = bookingProv.fareAmount ?? 141.47;
    final finalFare = _calculateFareForTier(tier, baseFare);
    final activeCar = _getActiveCarForTier(tier);

    final assignedImage = (activeCar?.imageUrl != null && activeCar!.imageUrl!.isNotEmpty)
        ? activeCar.imageUrl!
        : null;
    final carDisplayName = activeCar != null ? '${activeCar.make} ${activeCar.model}' : tier.name;

    bookingProv.setVehicle(tier.name, assignedImage);
    bookingProv.setFare(finalFare, bookingProv.distanceKm);

    // Navigate to Confirm Reservation screen
    context.push('/confirm-reservation', extra: {
      'category': tier.name,
      'subtitle': activeCar != null ? '${activeCar.make} ${activeCar.model}' : tier.subtitle,
      'fare': finalFare,
      'passengers': tier.passengers,
      'luggage': tier.luggage,
      'image': assignedImage,
      'carId': activeCar?.id,
      'carName': carDisplayName,
    });
  }

  void _showApplyOfferSheet() async {
    final code = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OffersRewardsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
    if (code != null && code.isNotEmpty && mounted) {
      CustomToast.showSuccess(context, 'Offer code "$code" applied!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFFBF8F4);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final availableCategories = FleetService.experienceCategories
        .where((tier) => _fleetCars.any((c) => c.category == tier.name))
        .toList();

    final bookingProv = context.watch<BookingProvider>();
    final baseFare = bookingProv.fareAmount ?? 141.47;
    final safeIndex = availableCategories.isEmpty
        ? 0
        : _currentPage.clamp(0, availableCategories.length - 1);
    final currentTier = availableCategories.isNotEmpty
        ? availableCategories[safeIndex]
        : null;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardColor,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.05,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Your experience',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Carousel View ───────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : availableCategories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 56,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No vehicles available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'There are currently no vehicle categories with active fleet cars.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // PageView Carousel
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: availableCategories.length,
                                onPageChanged: (idx) => setState(() => _currentPage = idx),
                                itemBuilder: (ctx, idx) {
                                  final tier = availableCategories[idx];
                                  final fare = _calculateFareForTier(tier, baseFare);
                                  final formattedFare = CurrencyService.format(fare);

                                  return _buildCarouselCard(
                                    tier: tier,
                                    fareText: formattedFare,
                                    isDark: isDark,
                                    cs: cs,
                                  );
                                },
                              ),
                            ),

                            // Subtitle & "+ Apply offer" Section below card
                            if (currentTier != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      child: Text(
                                        _getActiveCarForTier(currentTier) != null
                                            ? '${_getActiveCarForTier(currentTier)!.make} ${_getActiveCarForTier(currentTier)!.model} or similar'
                                            : currentTier.subtitle,
                                        key: ValueKey(
                                          '${currentTier.name}_${_getActiveCarForTier(currentTier)?.id ?? ""}',
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (_getActiveCarForTier(currentTier) != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _getActiveCarForTier(currentTier)!.hasDriverAssigned
                                                  ? const Color(0xFF22C55E)
                                                  : cs.onSurfaceVariant.withValues(alpha: 0.6),
                                              shape: BoxShape.circle,
                                              boxShadow: _getActiveCarForTier(currentTier)!.hasDriverAssigned
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                                                        blurRadius: 4,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _getActiveCarForTier(currentTier)!.hasDriverAssigned
                                                ? 'Active chauffeur on duty'
                                                : 'No active chauffeur currently assigned',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: _getActiveCarForTier(currentTier)!.hasDriverAssigned
                                                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                                                  : cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Divider(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(alpha: 0.1),
                                      height: 1,
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: _showApplyOfferSheet,
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Apply offer',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w500,
                                              color: cs.onSurfaceVariant,
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
            ),

            // ── Bottom Action Button: Select <Category> ─────────────────────
            if (currentTier != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _onSelectExperience(currentTier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Select ${currentTier.name}',
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Carousel Card Builder ─────────────────────────────────────────────────
  Widget _buildCarouselCard({
    required FleetCategoryTier tier,
    required String fareText,
    required bool isDark,
    required ColorScheme cs,
  }) {
    final activeCar = _getActiveCarForTier(tier);
    final tierCars = _fleetCars.where((c) => c.category == tier.name).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GestureDetector(
        onTap: () => _openCategoryCars(tier),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Vehicle Image Gradient Area with animated car transitions
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  tier.gradientColors[0].withValues(alpha: 0.25),
                                  AppColors.darkSurface,
                                ]
                              : tier.gradientColors,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: _buildVehicleImage(activeCar, tier, isDark),
                      ),
                    ),
                    if (activeCar != null)
                      Positioned(
                        top: 12,
                        left: 14,
                        child: _buildChauffeurStatusPill(
                          hasChauffeur: activeCar.hasDriverAssigned,
                          isDark: isDark,
                          cs: cs,
                        ),
                      ),
                  ],
                ),
              ),

              // Vehicle Category & Specs
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          tier.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          fareText,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (activeCar != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${activeCar.make} ${activeCar.model} • ${activeCar.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tier.passengers}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.work_outline_rounded,
                          size: 17,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tier.luggage}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tierCars.isNotEmpty
                                  ? '${tierCars.length} models'
                                  : 'View models',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(FleetVehicleItem? car, FleetCategoryTier tier, bool isDark) {
    if (car != null && car.imageUrl != null && car.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CachedNetworkImage(
          imageUrl: car.imageUrl!,
          key: ValueKey('net_${car.id}_${car.imageUrl}'),
          fit: BoxFit.contain,
          placeholder: (ctx, url) => Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          errorWidget: (ctx, err, stack) => _buildPlaceholder(car, tier, isDark),
        ),
      );
    }

    return _buildPlaceholder(car, tier, isDark);
  }

  Widget _buildChauffeurStatusPill({
    required bool hasChauffeur,
    required bool isDark,
    required ColorScheme cs,
  }) {
    final statusColor = hasChauffeur ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);
    final bgColor = hasChauffeur
        ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.75) : const Color(0xFFDCFCE7))
        : (isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: hasChauffeur
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            hasChauffeur ? 'Active chauffeur' : 'No active chauffeur',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: hasChauffeur
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(FleetVehicleItem? car, FleetCategoryTier tier, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 52,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 8),
          Text(
            car != null ? '${car.make} ${car.model}' : tier.name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
