import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/services/airport_detection_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Schedule ride screen matching the reference designs (Images 1 & 3):
///   - Top header with circular back button and "Schedule ride" title
///   - "Date" selector row with dropdown arrow
///   - "Pickup time" row with dropdown/up arrow (toggles inline clock picker)
///   - Inline clock picker card (Image 1) with digital readout, interactive clock dial, and OK/Cancel
///   - 3 bullet items: Estimated drop-off time, Complimentary wait time, Flexible cancellation
///   - Bottom CTA button: "Pickup at <time>"
///
/// Strictly complies with rules.json:
///   - GoogleFonts.poppins typography with restrained boldness (w500 / w600)
///   - Kenick Gold (#EAB308 / AppColors.primary)
///   - "ride" nomenclature throughout
class ScheduleBookingScreen extends StatefulWidget {
  const ScheduleBookingScreen({super.key});

  @override
  State<ScheduleBookingScreen> createState() => _ScheduleBookingScreenState();
}

class _ScheduleBookingScreenState extends State<ScheduleBookingScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool _isTimePickerOpen = false;
  bool _isHourMode = true;
  late int _tempHour;
  late int _tempMinute;
  late bool _tempIsAm;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final bookingProv = context.read<BookingProvider>();

    // Initial scheduled time: from provider if available, or 2 hours from now
    final initialDate = bookingProv.scheduledTime ??
        DateTime.now().add(const Duration(hours: 2));

    _selectedDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
    _selectedTime = TimeOfDay.fromDateTime(initialDate);

    _syncTempTime();
  }

  void _syncTempTime() {
    final h = _selectedTime.hourOfPeriod;
    _tempHour = h == 0 ? 12 : h;
    _tempMinute = _selectedTime.minute;
    _tempIsAm = _selectedTime.period == DayPeriod.am;
    _isHourMode = true;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    return '$hour:$minute $period';
  }

  String _getEstimatedDropoffTime() {
    final bookingProv = context.read<BookingProvider>();
    // Default estimated ride duration = 2 hours if not calculated
    final durationSeconds = bookingProv.distanceKm != null
        ? ((bookingProv.distanceKm! / 40.0) * 3600).round()
        : 7200;

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final dropoffDateTime =
        startDateTime.add(Duration(seconds: durationSeconds));

    return DateFormat('h:mm a').format(dropoffDateTime);
  }

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Color(0xFF111827),
                    surface: AppColors.darkSurface,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Color(0xFF111827),
                    onSurface: Color(0xFF111827),
                  ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirmTimePicker() {
    HapticFeedback.selectionClick();
    int hour24 = _tempHour % 12;
    if (!_tempIsAm) hour24 += 12;

    setState(() {
      _selectedTime = TimeOfDay(hour: hour24, minute: _tempMinute);
      _isTimePickerOpen = false;
    });
  }

  void _cancelTimePicker() {
    HapticFeedback.selectionClick();
    setState(() {
      _syncTempTime();
      _isTimePickerOpen = false;
    });
  }

  Future<void> _handleConfirmSchedule() async {
    HapticFeedback.lightImpact();
    final bookingProv = context.read<BookingProvider>();

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now().add(const Duration(minutes: 15)))) {
      CustomToast.showError(
        context,
        'Scheduled time must be at least 15 minutes from now',
      );
      return;
    }

    bookingProv.setBookingType('scheduled', scheduledTime: scheduledDateTime);

    // If pickup address is already set (e.g. user initiated from home screen)
    if (bookingProv.pickupAddress != null &&
        bookingProv.pickupAddress!.isNotEmpty) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && bookingProv.fareAmount != null) {
        setState(() => _isSubmitting = true);
        try {
          final requestId = await RideRepository().requestRide(
            passengerId: user.id,
            pickupLat: bookingProv.pickupLat ?? 0,
            pickupLng: bookingProv.pickupLng ?? 0,
            pickupAddress: bookingProv.pickupAddress!,
            dropoffLat: bookingProv.dropoffLat ?? 0,
            dropoffLng: bookingProv.dropoffLng ?? 0,
            dropoffAddress: bookingProv.dropoffAddress ?? 'Hourly Service',
            fareAmount: bookingProv.fareAmount!,
            type: 'scheduled',
            scheduledTime: scheduledDateTime,
            passengerNote: bookingProv.passengerNote,
          );

          bookingProv.setRideId(requestId);
          if (mounted) {
            final confirmationCode =
                'BK-${requestId.substring(0, math.min(8, requestId.length)).toUpperCase()}';
            _showBookingConfirmedDialog(
              context: context,
              confirmationCode: confirmationCode,
              scheduledTime: scheduledDateTime,
              vehicleName: bookingProv.vehicleType,
              fare: bookingProv.fareAmount!,
              pickup: bookingProv.pickupAddress!,
              dropoff: bookingProv.dropoffAddress ?? 'Hourly Service',
            );
          }
        } catch (e) {
          if (mounted) {
            CustomToast.showError(context, 'Failed to schedule ride: $e');
          }
        } finally {
          if (mounted) setState(() => _isSubmitting = false);
        }
        return;
      }

      // If airport transfer detected, route to dedicated airport flow
      final dropoffText = bookingProv.dropoffAddress ?? '';
      final pickupText = bookingProv.pickupAddress ?? '';
      if (!bookingProv.isAirportTransfer) {
        if (AirportDetectionService.isAirport(dropoffText)) {
          final code = AirportDetectionService.extractAirportCode(dropoffText);
          bookingProv.setAirportTransfer(
            isAirportTransfer: true,
            airportTransferType: 'dropoff',
            airportCode: code,
          );
          context.push('/airport-transfer', extra: {
            'isDropoff': true,
            'airportName': dropoffText,
            'airportCode': code,
          });
          return;
        } else if (AirportDetectionService.isAirport(pickupText)) {
          final code = AirportDetectionService.extractAirportCode(pickupText);
          bookingProv.setAirportTransfer(
            isAirportTransfer: true,
            airportTransferType: 'pickup',
            airportCode: code,
          );
          context.push('/airport-transfer', extra: {
            'isDropoff': false,
            'airportName': pickupText,
            'airportCode': code,
          });
          return;
        }
      }

      // Proceed to fleet selection if fare/car not picked yet
      context.push('/fleet-selection');
    } else {
      // Direct user to book journey screen to set pickup location
      context.push('/book-journey');
    }
  }

  void _showBookingConfirmedDialog({
    required BuildContext context,
    required String confirmationCode,
    required DateTime scheduledTime,
    required String vehicleName,
    required double fare,
    required String pickup,
    required String dropoff,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chauffeur Reserved',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Confirmation #$confirmationCode',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF7F5F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service Time',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, h:mm a').format(scheduledTime),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vehicle',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          vehicleName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/passenger-home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

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
                      onTap: () => context.pop(),
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
                    'Schedule ride',
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

            // ── Scrollable Form & Content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Date Field
                    Text(
                      'Date',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w400,
                                color: cs.onSurface,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: cs.onSurface,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.12),
                    ),

                    const SizedBox(height: 22),

                    // 2. Pickup Time Field
                    Text(
                      'Pickup time',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isTimePickerOpen = !_isTimePickerOpen;
                          if (_isTimePickerOpen) _syncTempTime();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_selectedTime),
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w400,
                                color: cs.onSurface,
                              ),
                            ),
                            Icon(
                              _isTimePickerOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: cs.onSurface,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: _isTimePickerOpen ? 2.0 : 1.0,
                      width: double.infinity,
                      color: _isTimePickerOpen
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.12)),
                    ),

                    // ── Inline Time Picker Card (Image 1) ───────────────────
                    if (_isTimePickerOpen) ...[
                      const SizedBox(height: 16),
                      _buildInlineClockPicker(isDark, cs),
                    ],

                    const SizedBox(height: 32),

                    // ── 3 Information Items (Images 1 & 3) ───────────────────
                    _buildInfoBullet(
                      icon: Icons.access_time_rounded,
                      title: 'Estimated drop-off time',
                      subtitle:
                          'Arrive at destination at approx. ${_getEstimatedDropoffTime()}',
                      cs: cs,
                    ),

                    const SizedBox(height: 22),

                    _buildInfoBullet(
                      icon: Icons.person_outline_rounded,
                      title: 'Complimentary wait time',
                      subtitle: 'Chauffeur will wait 15 minutes free of charge',
                      cs: cs,
                    ),

                    const SizedBox(height: 22),

                    _buildInfoBullet(
                      icon: Icons.alt_route_rounded,
                      title: 'Flexible cancellation',
                      subtitle:
                          'Free of charge cancellation up to 1 hour before pickup',
                      cs: cs,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA Button: "Pickup at <time>" ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleConfirmSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF111827),
                          ),
                        )
                      : Text(
                          'Pickup at ${_formatTime(_selectedTime)}',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
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

  // ── Info Bullet Widget ──────────────────────────────────────────────────────
  Widget _buildInfoBullet({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme cs,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: cs.onSurface,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Inline Clock Picker Card (Exact layout in Image 1) ──────────────────────
  Widget _buildInlineClockPicker(bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Digital Display Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour Box
              GestureDetector(
                onTap: () => setState(() => _isHourMode = true),
                child: Container(
                  width: 72,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isHourMode
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.22)
                            : const Color(0xFFDCEAFE))
                        : (isDark
                            ? const Color(0xFF2B2B32)
                            : const Color(0xFFF1F3F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _tempHour.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      color: _isHourMode
                          ? (isDark ? AppColors.primary : const Color(0xFF1D4ED8))
                          : cs.onSurface,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),

              // Minute Box
              GestureDetector(
                onTap: () => setState(() => _isHourMode = false),
                child: Container(
                  width: 72,
                  height: 60,
                  decoration: BoxDecoration(
                    color: !_isHourMode
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.22)
                            : const Color(0xFFDCEAFE))
                        : (isDark
                            ? const Color(0xFF2B2B32)
                            : const Color(0xFFF1F3F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _tempMinute.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      color: !_isHourMode
                          ? (isDark ? AppColors.primary : const Color(0xFF1D4ED8))
                          : cs.onSurface,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // AM / PM Column Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _tempIsAm = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _tempIsAm
                              ? (isDark
                                  ? AppColors.primary
                                  : const Color(0xFF1D4ED8))
                              : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(9),
                          ),
                        ),
                        child: Text(
                          'AM',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _tempIsAm
                                ? (isDark ? const Color(0xFF111827) : Colors.white)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _tempIsAm = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: !_tempIsAm
                              ? (isDark
                                  ? AppColors.primary
                                  : const Color(0xFF1D4ED8))
                              : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(9),
                          ),
                        ),
                        child: Text(
                          'PM',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_tempIsAm
                                ? (isDark ? const Color(0xFF111827) : Colors.white)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Analog Clock Dial ──
          SizedBox(
            width: 220,
            height: 220,
            child: GestureDetector(
              onPanUpdate: (details) => _handleDialTouch(details.localPosition),
              onTapDown: (details) => _handleDialTouch(details.localPosition),
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _ClockDialPainter(
                  isHourMode: _isHourMode,
                  selectedHour: _tempHour,
                  selectedMinute: _tempMinute,
                  isDark: isDark,
                  primaryColor: isDark ? AppColors.primary : const Color(0xFF1D4ED8),
                  textColor: cs.onSurface,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Bottom Actions Row ──
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: cs.onSurfaceVariant,
                onPressed: () => _showManualTimeEntryDialog(),
              ),
              const Spacer(),
              TextButton(
                onPressed: _cancelTimePicker,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primary : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _confirmTimePicker,
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primary : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDialTouch(Offset localPos) {
    HapticFeedback.selectionClick();
    const center = Offset(110, 110);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    var angle = math.atan2(dy, dx) * 180 / math.pi + 90;
    if (angle < 0) angle += 360;

    if (_isHourMode) {
      final calc = ((angle + 15) ~/ 30) % 12;
      final hour = calc == 0 ? 12 : calc;
      setState(() => _tempHour = hour);
    } else {
      final minute = ((angle + 3) ~/ 6) % 60;
      setState(() => _tempMinute = minute);
    }
  }

  void _showManualTimeEntryDialog() {
    final hourCtrl = TextEditingController(text: _tempHour.toString());
    final minCtrl =
        TextEditingController(text: _tempMinute.toString().padLeft(2, '0'));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter Time',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: hourCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(labelText: 'Hour (1-12)'),
              ),
            ),
            const SizedBox(width: 12),
            const Text(':', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(labelText: 'Minute (0-59)'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final h = int.tryParse(hourCtrl.text.trim());
              final m = int.tryParse(minCtrl.text.trim());
              if (h != null && h >= 1 && h <= 12 && m != null && m >= 0 && m <= 59) {
                setState(() {
                  _tempHour = h;
                  _tempMinute = m;
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF111827),
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

// ── Custom Clock Dial Painter (Image 1) ──────────────────────────────────────
class _ClockDialPainter extends CustomPainter {
  _ClockDialPainter({
    required this.isHourMode,
    required this.selectedHour,
    required this.selectedMinute,
    required this.isDark,
    required this.primaryColor,
    required this.textColor,
  });

  final bool isHourMode;
  final int selectedHour;
  final int selectedMinute;
  final bool isDark;
  final Color primaryColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dial background circle
    final dialBgPaint = Paint()
      ..color = isDark ? const Color(0xFF26262D) : const Color(0xFFEFF2F6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialBgPaint);

    // Pivot center dot
    final pivotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, pivotPaint);

    final numRadius = radius - 22;

    // Calculate angle for current selected hand
    final double handAngle = isHourMode
        ? (selectedHour * 30 - 90) * math.pi / 180
        : (selectedMinute * 6 - 90) * math.pi / 180;

    final handTarget = Offset(
      center.dx + numRadius * math.cos(handAngle),
      center.dy + numRadius * math.sin(handAngle),
    );

    // Draw clock hand line
    final handPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, handTarget, handPaint);

    // Draw circle over selected number
    final selectionCirclePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handTarget, 16.5, selectionCirclePaint);

    // Draw numbers
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    if (isHourMode) {
      for (int i = 1; i <= 12; i++) {
        final angle = (i * 30 - 90) * math.pi / 180;
        final pos = Offset(
          center.dx + numRadius * math.cos(angle),
          center.dy + numRadius * math.sin(angle),
        );

        final isSelected = i == selectedHour;
        textPainter.text = TextSpan(
          text: '$i',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF111827) : textColor,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
        );
      }
    } else {
      // 5-minute increments
      for (int i = 0; i < 60; i += 5) {
        final angle = (i * 6 - 90) * math.pi / 180;
        final pos = Offset(
          center.dx + numRadius * math.cos(angle),
          center.dy + numRadius * math.sin(angle),
        );

        final isSelected = i == selectedMinute;
        textPainter.text = TextSpan(
          text: i.toString().padLeft(2, '0'),
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF111827) : textColor,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ClockDialPainter oldDelegate) {
    return oldDelegate.isHourMode != isHourMode ||
        oldDelegate.selectedHour != selectedHour ||
        oldDelegate.selectedMinute != selectedMinute ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}
