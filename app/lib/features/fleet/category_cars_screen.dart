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

class CategoryCarsScreen extends StatefulWidget {
  const CategoryCarsScreen({
    super.key,
    required this.tier,
    this.cars = const [],
    this.baseFare,
  });

  final FleetCategoryTier tier;
  final List<FleetVehicleItem> cars;
  final double? baseFare;

  @override
  State<CategoryCarsScreen> createState() => _CategoryCarsScreenState();
}

class _CategoryCarsScreenState extends State<CategoryCarsScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  List<FleetVehicleItem> _tierCars = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    final matched = widget.cars
        .where((c) =>
            c.category == widget.tier.name &&
            c.category.isNotEmpty &&
            c.category.toLowerCase() != 'none')
        .toList();
    if (matched.isNotEmpty) {
      _tierCars = matched;
    } else {
      _loadRealFleetCars();
    }
  }

  Future<void> _loadRealFleetCars() async {
    setState(() => _isLoading = true);
    final allCars = await FleetService.getAllFleetCarsWithChauffeurStatus();
    if (mounted) {
      setState(() {
        _tierCars = allCars
            .where((c) =>
                c.category == widget.tier.name &&
                c.category.isNotEmpty &&
                c.category.toLowerCase() != 'none')
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _calculateFare(double baseAmount) {
    if (baseAmount <= 0) {
      return (141.47 * widget.tier.priceMultiplier);
    }
    return (baseAmount * widget.tier.priceMultiplier);
  }

  void _onSelectSpecificCar(FleetVehicleItem car) {
    HapticFeedback.lightImpact();
    final bookingProv = context.read<BookingProvider>();
    final baseFare = widget.baseFare ?? bookingProv.fareAmount ?? 141.47;
    final finalFare = _calculateFare(baseFare);

    final assignedImage = (car.imageUrl != null && car.imageUrl!.isNotEmpty)
        ? car.imageUrl!
        : null;
    final carDisplayName = '${car.make} ${car.model}';

    // Store in booking provider: specific chosen car under this category
    bookingProv.setVehicle('${widget.tier.name} ($carDisplayName)', assignedImage);
    bookingProv.setFare(finalFare, bookingProv.distanceKm);

    context.push('/confirm-reservation', extra: {
      'category': widget.tier.name,
      'subtitle': '$carDisplayName • Guaranteed vehicle',
      'fare': finalFare,
      'passengers': widget.tier.passengers,
      'luggage': widget.tier.luggage,
      'image': assignedImage,
      'carId': car.id,
      'carName': carDisplayName,
      'isSpecificVehicle': true,
    });
  }

  void _onSelectAnyCarInCategory() {
    if (_tierCars.isEmpty) return;
    HapticFeedback.lightImpact();
    final bookingProv = context.read<BookingProvider>();
    final baseFare = widget.baseFare ?? bookingProv.fareAmount ?? 141.47;
    final finalFare = _calculateFare(baseFare);

    final firstCar = _tierCars.firstOrNull;
    final assignedImage = (firstCar?.imageUrl != null && firstCar!.imageUrl!.isNotEmpty)
        ? firstCar.imageUrl!
        : null;

    bookingProv.setVehicle(widget.tier.name, assignedImage);
    bookingProv.setFare(finalFare, bookingProv.distanceKm);

    context.push('/confirm-reservation', extra: {
      'category': widget.tier.name,
      'subtitle': widget.tier.subtitle,
      'fare': finalFare,
      'passengers': widget.tier.passengers,
      'luggage': widget.tier.luggage,
      'image': assignedImage,
      'carName': '${widget.tier.name} (Chauffeur Choice)',
      'isSpecificVehicle': false,
    });
  }

  void _showApplyOfferSheet() async {
    final code = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, anim, secAnim) => const OffersRewardsScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );

    if (code != null && code.isNotEmpty && mounted) {
      CustomToast.showSuccess(context, 'Offer $code applied to your ride');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bookingProv = context.watch<BookingProvider>();
    final baseFare = widget.baseFare ?? bookingProv.fareAmount ?? 141.47;
    final finalFare = _calculateFare(baseFare);
    final fareText = CurrencyService.format(finalFare);

    final subtleDivider = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    final currentCar = _tierCars.isNotEmpty && _currentPage < _tierCars.length
        ? _tierCars[_currentPage]
        : null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(cs, isDark),

            // Carousel Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : _tierCars.isEmpty
                      ? Center(
                          child: Text(
                            'No vehicles found in this category',
                            style: GoogleFonts.poppins(color: cs.onSurfaceVariant),
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _tierCars.length,
                          onPageChanged: (idx) {
                            HapticFeedback.selectionClick();
                            setState(() => _currentPage = idx);
                          },
                          itemBuilder: (context, index) {
                            final car = _tierCars[index];
                            return _buildVehicleCard(
                              car: car,
                              fareText: fareText,
                              isDark: isDark,
                              cs: cs,
                            );
                          },
                        ),
            ),

            // Dots indicator & Offer Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Column(
                children: [
                  if (_tierCars.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_tierCars.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Subtle divider
                  Divider(height: 1, color: subtleDivider),
                  const SizedBox(height: 6),

                  // Apply offer button
                  InkWell(
                    onTap: _showApplyOfferSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Apply offer',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom CTA Buttons
            _buildBottomBar(currentCar, fareText, isDark, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.tier.name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${_tierCars.length} models in fleet',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({
    required FleetVehicleItem car,
    required String fareText,
    required bool isDark,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            // Top Image Area with Category Gradient
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            widget.tier.gradientColors[0].withValues(alpha: 0.25),
                            AppColors.darkSurface,
                          ]
                        : widget.tier.gradientColors,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildVehicleImage(car, isDark),
                ),
              ),
            ),

            // Vehicle Specs & Title
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
                      Expanded(
                        child: Text(
                          '${car.make} ${car.model}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.tier.passengers}',
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
                        '${widget.tier.luggage}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${car.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (car.features.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      car.features.replaceAll('\n', ' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(FleetVehicleItem car, bool isDark) {
    if (car.imageUrl != null && car.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
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
        errorWidget: (ctx, err, stack) => _buildPlaceholder(car, isDark),
      );
    }

    return _buildPlaceholder(car, isDark);
  }

  Widget _buildPlaceholder(FleetVehicleItem car, bool isDark) {
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
            '${car.make} ${car.model}',
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

  Widget _buildBottomBar(
    FleetVehicleItem? car,
    String fareText,
    bool isDark,
    ColorScheme cs,
  ) {
    final carLabel = car != null ? '${car.make} ${car.model}' : widget.tier.name;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Button: Select this specific car
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: car != null ? () => _onSelectSpecificCar(car) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF111827),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Select $carLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Secondary Option: Any car in the category can pick user
          TextButton(
            onPressed: _tierCars.isNotEmpty ? _onSelectAnyCarInCategory : null,
            child: Text(
              'Any ${widget.tier.name} Vehicle (Chauffeur Choice)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
