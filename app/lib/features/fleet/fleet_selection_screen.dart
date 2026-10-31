import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/services/currency_service.dart';
import 'package:kenick_vip/services/fleet_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';

/// "Your experience" screen matching reference designs (Images 1, 4, 5):
///   - Top header with circular back button and "Your experience" title
///   - Swipeable card carousel displaying the 3 VIP categories:
///       • Business Class (mint gradient, 3 pax, 2 bags, e.g. Mercedes-Benz EQE or similar)
///       • Business Van   (peach gradient, 5 pax, 5 bags, e.g. Mercedes-Benz V-Class or similar)
///       • First Class    (powder blue gradient, 3 pax, 2 bags, e.g. Mercedes-Benz S-Class or similar)
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _fetchFleetCars();
  }

  @override
  void dispose() {
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
      });
    }
  }

  double _calculateFareForTier(FleetCategoryTier tier, double baseAmount) {
    if (baseAmount <= 0) {
      // Default baseline pricing matching design reference: €141.47 for 2h
      return (141.47 * tier.priceMultiplier);
    }
    return (baseAmount * tier.priceMultiplier);
  }

  String? _findAssignedCarName(FleetCategoryTier tier) {
    final matched = _fleetCars.where((c) => c.category == tier.name);
    if (matched.isNotEmpty) {
      return '${matched.first.make} ${matched.first.model}';
    }
    return null;
  }

  String? _findAssignedCarImage(FleetCategoryTier tier) {
    final matched = _fleetCars.where((c) => c.category == tier.name);
    if (matched.isNotEmpty && matched.first.imageUrl != null && matched.first.imageUrl!.isNotEmpty) {
      return matched.first.imageUrl;
    }
    return null;
  }

  void _onSelectExperience(FleetCategoryTier tier) {
    final bookingProv = context.read<BookingProvider>();
    final baseFare = bookingProv.fareAmount ?? 141.47;
    final finalFare = _calculateFareForTier(tier, baseFare);
    final assignedImage = _findAssignedCarImage(tier) ?? tier.defaultAsset;

    bookingProv.setVehicle(tier.name, assignedImage);
    bookingProv.setFare(finalFare, bookingProv.distanceKm);

    // Navigate to Confirm Reservation screen
    context.push('/confirm-reservation', extra: {
      'category': tier.name,
      'subtitle': tier.subtitle,
      'fare': finalFare,
      'passengers': tier.passengers,
      'luggage': tier.luggage,
      'image': assignedImage,
    });
  }

  void _showApplyOfferSheet() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apply promo code',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              cursorColor: AppColors.primary,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Enter promo code (e.g. VIP2026)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final code = codeCtrl.text.trim();
                  if (code.isNotEmpty) {
                    Navigator.pop(ctx);
                    CustomToast.showSuccess(context, 'Promo code applied successfully!');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Code',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFFBF8F4);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    const categories = FleetService.experienceCategories;

    final bookingProv = context.watch<BookingProvider>();
    final baseFare = bookingProv.fareAmount ?? 141.47;
    final currentTier = categories[_currentPage];

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
                  : Column(
                      children: [
                        // PageView Carousel
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: categories.length,
                            onPageChanged: (idx) => setState(() => _currentPage = idx),
                            itemBuilder: (ctx, idx) {
                              final tier = categories[idx];
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _findAssignedCarName(currentTier) != null
                                    ? '${_findAssignedCarName(currentTier)} or similar'
                                    : currentTier.subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
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
    final assignedImg = _findAssignedCarImage(tier);

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
            // Vehicle Image Gradient Area
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
                            tier.gradientColors[0].withValues(alpha: 0.25),
                            AppColors.darkSurface,
                          ]
                        : tier.gradientColors,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: assignedImg != null
                    ? Image.network(
                        assignedImg,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Image.asset(
                          tier.defaultAsset,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(
                        tier.defaultAsset,
                        fit: BoxFit.contain,
                      ),
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
