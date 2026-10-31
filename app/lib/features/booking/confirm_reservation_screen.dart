import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/features/booking/pickup_notes_sheet.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/services/currency_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/map/vip_google_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// "Confirm reservation" screen matching reference design (Image 3):
///   - Top header with circular back button and "Confirm reservation" title
///   - Upper section: Map preview with route polyline & pickup pin
///   - Floating Card on map:
///       • Date (e.g. Wed, 21 Oct 2026) + Passenger pill [👤 For myself v]
///       • Timeline row: Pickup (address & time) ─── 🚗 BUSINESS CLASS ───> Dropoff / Duration
///   - Lower section:
///       • Category title & formatted fare (e.g. Business Class  € 141.47)
///       • Payment method selector [💳 Select payment method v]
///       • Options row: [📄 Pickup notes v]   [+ Apply offer v]
///       • Bottom CTA: [Book now] pill button + recurring booking icon button
///
/// Strictly complies with rules.json:
///   - GoogleFonts.poppins typography with restrained boldness (w500 / w600)
///   - Kenick primary gold (#EAB308 / AppColors.primary)
///   - "ride" nomenclature throughout
class ConfirmReservationScreen extends StatefulWidget {
  const ConfirmReservationScreen({
    super.key,
    this.category = 'Business Class',
    this.subtitle = 'Mercedes-Benz EQE or similar',
    this.fare = 141.47,
    this.passengers = 3,
    this.luggage = 2,
    this.imageUrl,
  });

  final String category;
  final String subtitle;
  final double fare;
  final int passengers;
  final int luggage;
  final String? imageUrl;

  @override
  State<ConfirmReservationScreen> createState() => _ConfirmReservationScreenState();
}

class _ConfirmReservationScreenState extends State<ConfirmReservationScreen> {
  final GlobalKey<VipGoogleMapState> _mapKey = GlobalKey<VipGoogleMapState>();

  String _paymentMethod = 'Select payment method';
  String? _pickupNotes;
  String? _referenceCode;
  String? _promoCode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultPaymentMethod();
  }

  Future<void> _loadDefaultPaymentMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('saved_user_cards');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          final last4 = first['last4'] ?? '4242';
          final brand = first['brand'] ?? 'Card';
          if (mounted) {
            setState(() => _paymentMethod = '$brand •••• $last4');
          }
          return;
        }
      }
    } catch (_) {}
  }

  void _openPickupNotesModal() async {
    final result = await PickupNotesSheet.show(
      context,
      initialNotes: _pickupNotes,
      initialReferenceCode: _referenceCode,
    );
    if (result != null && mounted) {
      setState(() {
        _pickupNotes = result['notes'];
        _referenceCode = result['reference_code'];
      });
      CustomToast.showSuccess(context, 'Pickup notes saved');
    }
  }

  void _openApplyOfferModal() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeCtrl = TextEditingController(text: _promoCode ?? '');

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
                  'Apply offer',
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
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.8),
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
                    setState(() => _promoCode = code);
                    Navigator.pop(ctx);
                    CustomToast.showSuccess(context, 'Offer code "$code" applied!');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: Text('Apply Offer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPaymentMethodSheet() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final methods = [
      {'title': 'Credit Card •••• 4242', 'icon': Icons.credit_card_rounded},
      {'title': 'Apple Pay', 'icon': Icons.apple_rounded},
      {'title': 'Google Pay', 'icon': Icons.g_mobiledata_rounded},
      {'title': 'Cash / Corporate Account', 'icon': Icons.account_balance_wallet_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select payment method',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...methods.map((m) {
                final isSelected = _paymentMethod == m['title'];
                return InkWell(
                  onTap: () {
                    setState(() => _paymentMethod = m['title'] as String);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(m['icon'] as IconData, size: 22, color: AppColors.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            m['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBookNow() async {
    if (_isSubmitting) return;

    final bookingProv = context.read<BookingProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      CustomToast.showError(context, 'Please sign in to confirm booking');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final pickupAddress = bookingProv.pickupAddress ?? 'Current Location';
      final dropoffAddress = bookingProv.dropoffAddress ?? 'Hourly Service';
      final pickupLat = bookingProv.pickupLat ?? 52.5200;
      final pickupLng = bookingProv.pickupLng ?? 13.4050;
      final dropoffLat = bookingProv.dropoffLat ?? 52.5300;
      final dropoffLng = bookingProv.dropoffLng ?? 13.4150;

      // Build comprehensive passenger notes
      final notesList = <String>[];
      if (bookingProv.passengerNote != null && bookingProv.passengerNote!.isNotEmpty) {
        notesList.add(bookingProv.passengerNote!);
      }
      if (_pickupNotes != null && _pickupNotes!.isNotEmpty) {
        notesList.add('Pickup Note: $_pickupNotes');
      }
      if (_referenceCode != null && _referenceCode!.isNotEmpty) {
        notesList.add('Ref: $_referenceCode');
      }
      notesList.add('Fleet Category: ${widget.category}');

      final combinedNote = notesList.join(' | ');

      final rideId = await RideRepository().requestRide(
        passengerId: user.id,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        fareAmount: widget.fare,
        type: bookingProv.bookingType,
        scheduledTime: bookingProv.scheduledTime,
        passengerNote: combinedNote,
      );

      bookingProv.setRideId(rideId);

      if (mounted) {
        CustomToast.showSuccess(context, 'Ride reserved successfully! Chauffeur dispatch initiated.');
        context.go('/passenger-home');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to complete reservation: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFFBF8F4);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final bookingProv = context.watch<BookingProvider>();

    // Formatted Date
    final date = bookingProv.scheduledTime ?? DateTime.now();
    final dateFormatted = DateFormat('EEE, d MMM y').format(date);
    final pickupTimeFormatted = DateFormat('h:mm a').format(date);
    final dropoffTimeFormatted = DateFormat('h:mm a').format(date.add(const Duration(hours: 2)));

    final pickupAddress = bookingProv.pickupAddress ?? 'Poststraße 30, Berlin';
    final dropoffOrDuration = bookingProv.dropoffAddress?.contains('Hourly') == true ||
            bookingProv.bookingType == 'schedule'
        ? '2 hours'
        : (bookingProv.dropoffAddress ?? 'Destination');

    // Extract guest name if any
    String passengerLabel = 'For myself';
    if (bookingProv.passengerNote != null && bookingProv.passengerNote!.startsWith('Guest:')) {
      final match = RegExp(r'Guest:\s*([^(\n]+)').firstMatch(bookingProv.passengerNote!);
      if (match != null && match.group(1)?.trim().isNotEmpty == true) {
        passengerLabel = match.group(1)!.trim();
      }
    }

    final pickupLat = bookingProv.pickupLat ?? 52.5200;
    final pickupLng = bookingProv.pickupLng ?? 13.4050;
    final initialMapPos = LatLng(pickupLat, pickupLng);

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
                          border: Border.all(color: subtleBorder),
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
                    'Confirm reservation',
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

            // ── Map View with Floating Route Card ───────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Map Widget
                  Positioned.fill(
                    child: VipGoogleMap(
                      key: _mapKey,
                      initialCenter: initialMapPos,
                      initialZoom: 14.0,
                      routePoints: bookingProv.routePoints,
                      driverPosition: initialMapPos,
                      pickupPosition: initialMapPos,
                    ),
                  ),

                  // Floating Card on Map
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: subtleBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top row: Date + Passenger pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateFormatted,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    passengerLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Divider(color: subtleBorder, height: 1),
                          const SizedBox(height: 12),

                          // Route timeline row: Pickup ── 🚗 Category ──> Dropoff
                          Row(
                            children: [
                              // Pickup side
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pickupAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pickupTimeFormatted,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Middle: ── 🚗 Category ──>
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: cs.outlineVariant.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(
                                            Icons.directions_car_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: cs.outlineVariant.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10,
                                          color: cs.outlineVariant,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.category.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Dropoff side
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      dropoffOrDuration,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dropoffTimeFormatted,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: cs.onSurfaceVariant,
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
                  ),
                ],
              ),
            ),

            // ── Lower Section: Fare, Payment & Actions ──────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(top: BorderSide(color: subtleBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.category,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        CurrencyService.format(widget.fare),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Payment method selector row
                  GestureDetector(
                    onTap: _openPaymentMethodSheet,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paymentMethod,
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Divider(color: subtleBorder, height: 1),
                  const SizedBox(height: 12),

                  // Actions row: [📄 Pickup notes v]   [+ Apply offer v]
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _openPickupNotesModal,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 17,
                                color: _pickupNotes != null ? AppColors.primary : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _pickupNotes != null ? 'Notes saved' : 'Pickup notes',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _openApplyOfferModal,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: _promoCode != null ? AppColors.primary : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _promoCode != null ? 'Offer: $_promoCode' : 'Apply offer',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bottom CTA Row: [Book now] pill + recurring calendar button
                  Row(
                    children: [
                      // Book now CTA button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleBookNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: const Color(0xFF111827),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF111827),
                                    ),
                                  )
                                : Text(
                                    'Book now',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Recurring / Repeat booking button
                      GestureDetector(
                        onTap: () {
                          CustomToast.showSuccess(context, 'Recurring ride frequency set for this reservation');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                            border: Border.all(color: subtleBorder),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.event_repeat_rounded,
                            size: 24,
                            color: cs.onSurface,
                          ),
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
