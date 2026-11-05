import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:provider/provider.dart';

class AirportTransferScreen extends StatefulWidget {
  const AirportTransferScreen({
    super.key,
    required this.isDropoff,
    this.airportName,
    this.airportCode,
  });

  final bool isDropoff;
  final String? airportName;
  final String? airportCode;

  @override
  State<AirportTransferScreen> createState() => _AirportTransferScreenState();
}

class _AirportTransferScreenState extends State<AirportTransferScreen> {
  // Mode toggle for Airport Pickup: 'flight_arrival' vs 'time'
  bool _isByFlightArrival = true;

  // Selected schedule
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  // Temporary values for cancel/confirm
  late DateTime _tempDate;

  // Inline picker expand states
  bool _isDateExpanded = false;
  bool _isTimeExpanded = false;
  bool _isBufferExpanded = false;

  // Flight details
  final TextEditingController _flightNumberController = TextEditingController();
  final FocusNode _flightFocusNode = FocusNode();

  // Buffer time for flight arrival (in minutes)
  int _bufferMinutes = 15;
  static const List<int> _bufferOptions = [15, 30, 45, 60, 75, 90, 120, 150, 180];

  @override
  void initState() {
    super.initState();
    final bookingProv = context.read<BookingProvider>();

    if (bookingProv.scheduledTime != null) {
      _selectedDate = DateTime(
        bookingProv.scheduledTime!.year,
        bookingProv.scheduledTime!.month,
        bookingProv.scheduledTime!.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(bookingProv.scheduledTime!);
    } else {
      final now = DateTime.now().add(const Duration(hours: 2));
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.fromDateTime(now);
    }

    _tempDate = _selectedDate;

    if (bookingProv.flightNumber != null && bookingProv.flightNumber!.isNotEmpty) {
      _flightNumberController.text = bookingProv.flightNumber!;
    }

    if (bookingProv.flightBufferMinutes != null) {
      _bufferMinutes = bookingProv.flightBufferMinutes!;
    }

    if (bookingProv.airportPickupMode == 'time') {
      _isByFlightArrival = false;
    }

    _flightNumberController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    _flightFocusNode.dispose();
    super.dispose();
  }

  String get _effectiveAirportCode {
    if (widget.airportCode != null && widget.airportCode!.isNotEmpty) {
      return widget.airportCode!;
    }
    return 'IND';
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt).toLowerCase();
  }

  DateTime _getCalculatedDropoffDateTime(int durationMinutes) {
    final pickupDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    return pickupDt.add(Duration(minutes: durationMinutes));
  }

  void _onConfirm() {
    HapticFeedback.lightImpact();

    final flightNum = _flightNumberController.text.trim();

    // If Airport Pickup in "By flight arrival" mode, flight number is required for tracking
    if (!widget.isDropoff && _isByFlightArrival) {
      if (flightNum.isEmpty) {
        CustomToast.showError(context, 'Please enter your arrival flight number for tracking');
        _flightFocusNode.requestFocus();
        return;
      }
    }

    final bookingProv = context.read<BookingProvider>();

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Update Airport Transfer configuration in BookingProvider
    bookingProv.setAirportTransfer(
      isAirportTransfer: true,
      airportTransferType: widget.isDropoff ? 'dropoff' : 'pickup',
      airportCode: _effectiveAirportCode,
      flightNumber: flightNum.isNotEmpty ? flightNum.toUpperCase() : null,
      airportPickupMode: !widget.isDropoff && _isByFlightArrival ? 'flight_arrival' : 'time',
      flightBufferMinutes: !widget.isDropoff && _isByFlightArrival ? _bufferMinutes : null,
    );

    bookingProv.setBookingType(
      'schedule',
      scheduledTime: scheduledDateTime,
      eventType: widget.isDropoff
          ? 'Airport Drop-off ($_effectiveAirportCode)'
          : 'Airport Pickup ($_effectiveAirportCode)',
      rideType: 'One way',
    );

    // Proceed to VIP fleet selection
    context.push('/fleet-selection');
  }

  void _showInfoSheet() {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exactly 1 drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B63CE).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
                        color: Color(0xFF0B63CE),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kenick Airport VIP Protocol',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildInfoRow(
                  icon: Icons.radar_rounded,
                  title: 'Real-Time Flight Tracking',
                  description:
                      'Kenick continuously monitors inbound & outbound flights. If your flight arrives early or is delayed, chauffeur dispatch automatically adjusts.',
                  cs: cs,
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  icon: Icons.timer_outlined,
                  title: '60 Minutes Complimentary Wait Time',
                  description:
                      'Enjoy 60 minutes of complimentary chauffeur waiting time from wheels-down for commercial flights to clear baggage and customs stress-free.',
                  cs: cs,
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  icon: Icons.person_pin_circle_outlined,
                  title: 'Personalized VIP Meet & Greet',
                  description:
                      'Your chauffeur will await you inside arrivals or at the curbside holding a personalized digital name sign to assist with luggage.',
                  cs: cs,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B63CE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Understood',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme cs,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0B63CE)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFFBF8F4);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);

    final bookingProv = context.watch<BookingProvider>();

    // Estimated duration from distance or reference fallback (13 mins)
    final estimatedDurationMinutes = (bookingProv.distanceKm != null && bookingProv.distanceKm! > 0)
        ? (bookingProv.distanceKm! * 1.5).round().clamp(10, 180)
        : 13;

    final calculatedDropoffDt = _getCalculatedDropoffDateTime(estimatedDurationMinutes);
    final calculatedDropoffFormatted =
        DateFormat('h:mm a').format(calculatedDropoffDt).toLowerCase();

    // Determine CTA Button state & label
    final isFlightInputValid = _flightNumberController.text.trim().isNotEmpty;
    final isCtaActive = widget.isDropoff || !_isByFlightArrival || isFlightInputValid;

    String ctaLabel;
    if (widget.isDropoff) {
      ctaLabel = 'Pickup at ${_formatTime(_selectedTime)}';
    } else if (!_isByFlightArrival) {
      ctaLabel = 'Pickup at ${_formatTime(_selectedTime)}';
    } else {
      ctaLabel = isFlightInputValid
          ? 'Pickup $_bufferMinutes min after arrival'
          : 'Select time';
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
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
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.isDropoff ? 'Airport drop-off' : 'Airport pickup',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showInfoSheet,
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
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle indicating target Airport e.g. "Your drop-off at IND" / "Your flight to IND"
            Text(
              widget.isDropoff
                  ? 'Your drop-off at $_effectiveAirportCode'
                  : (_isByFlightArrival
                      ? 'Your flight to $_effectiveAirportCode'
                      : 'Your pickup from $_effectiveAirportCode'),
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 14),

            // ── Pill Segmented Switcher for Airport Pickup (Images 2, 4) ───
            if (!widget.isDropoff)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      // "By flight arrival" Pill
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isByFlightArrival = true;
                              _isTimeExpanded = false;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _isByFlightArrival
                                  ? const Color(0xFF0B63CE)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'By flight arrival',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: _isByFlightArrival
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _isByFlightArrival ? Colors.white : cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // "By time" Pill
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isByFlightArrival = false;
                              _isBufferExpanded = false;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: !_isByFlightArrival
                                  ? const Color(0xFF0B63CE)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'By time',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: !_isByFlightArrival
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: !_isByFlightArrival ? Colors.white : cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Main Content Area ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. DATE SECTION (Images 1, 2, 3, 4, 6)
                    _buildSectionLabel('Date', cs),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isDateExpanded = !_isDateExpanded;
                          if (_isDateExpanded) {
                            _tempDate = _selectedDate;
                            _isTimeExpanded = false;
                            _isBufferExpanded = false;
                          }
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(_selectedDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: cs.onSurface,
                                ),
                              ),
                              Icon(
                                _isDateExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 22,
                                color: cs.onSurface,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: _isDateExpanded ? 2.0 : 1.0,
                            width: double.infinity,
                            color: _isDateExpanded
                                ? const Color(0xFF0B63CE)
                                : subtleBorder,
                          ),
                        ],
                      ),
                    ),

                    // Inline Expandable Date Picker Card (Images 3 & 6)
                    if (_isDateExpanded) ...[
                      const SizedBox(height: 12),
                      _buildInlineDatePicker(cardColor, isDark, cs),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 24),

                    // 2. PICKUP FLOW: By flight arrival vs By time
                    if (!widget.isDropoff && _isByFlightArrival) ...[
                      // FLIGHT NUMBER SECTION (Mandatory in arrival tracking)
                      _buildSectionLabel('Flight number', cs),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _flightNumberController,
                        focusNode: _flightFocusNode,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. LH 202, BA2490',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          suffixIcon: _flightNumberController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () => _flightNumberController.clear(),
                                )
                              : null,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: _flightFocusNode.hasFocus ? 2.0 : 1.0,
                        width: double.infinity,
                        color: _flightFocusNode.hasFocus
                            ? const Color(0xFF0B63CE)
                            : subtleBorder,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Real-time flight tracking ensures your chauffeur meets you exactly where and when you land.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // PICKUP TIME (BUFFER AFTER FLIGHT ARRIVAL)
                      _buildSectionLabel('Pickup time', cs),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isBufferExpanded = !_isBufferExpanded;
                            if (_isBufferExpanded) {
                              _isDateExpanded = false;
                            }
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_bufferMinutes minutes after flight arrival',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Icon(
                                  _isBufferExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 22,
                                  color: cs.onSurface,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: _isBufferExpanded ? 2.0 : 1.0,
                              width: double.infinity,
                              color: _isBufferExpanded
                                  ? const Color(0xFF0B63CE)
                                  : subtleBorder,
                            ),
                          ],
                        ),
                      ),

                      // Inline Expandable Buffer List Card (Image 5)
                      if (_isBufferExpanded) ...[
                        const SizedBox(height: 10),
                        _buildInlineBufferDropdown(cardColor, isDark, cs),
                        const SizedBox(height: 10),
                      ],
                    ] else ...[
                      // 3. TIME SECTION (For Drop-off OR Pickup by time)
                      _buildSectionLabel('Pickup time', cs),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isTimeExpanded = !_isTimeExpanded;
                            if (_isTimeExpanded) {
                              _isDateExpanded = false;
                              _isBufferExpanded = false;
                            }
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(_selectedTime),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Icon(
                                  _isTimeExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 22,
                                  color: cs.onSurface,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: _isTimeExpanded ? 2.0 : 1.0,
                              width: double.infinity,
                              color: _isTimeExpanded
                                  ? const Color(0xFF0B63CE)
                                  : subtleBorder,
                            ),
                          ],
                        ),
                      ),

                      // Inline Expandable Clock Time Picker Card (Image 7)
                      if (_isTimeExpanded) ...[
                        const SizedBox(height: 12),
                        _InlineClockTimePickerCard(
                          cardColor: cardColor,
                          isDark: isDark,
                          initialTime: _selectedTime,
                          onCancel: () {
                            setState(() => _isTimeExpanded = false);
                          },
                          onOk: (newTime) {
                            setState(() {
                              _selectedTime = newTime;
                              _isTimeExpanded = false;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Optional Flight number for Drop-off (Image 1)
                      if (widget.isDropoff) ...[
                        const SizedBox(height: 24),
                        _buildSectionLabel('Flight number (optional)', cs),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _flightNumberController,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. LH 202, BA2490',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                            suffixIcon: _flightNumberController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () => _flightNumberController.clear(),
                                  )
                                : null,
                          ),
                        ),
                        Container(
                          height: 1.0,
                          width: double.infinity,
                          color: subtleBorder,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We will drop you off at the correct terminal.',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Journey Duration & Approx Drop-off estimation row (Image 1)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.access_time_rounded,
                                size: 20,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Drop-off at approx. $calculatedDropoffFormatted',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Estimated journey duration of $estimatedDurationMinutes minutes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom Action Button (Images 1, 2, 4) ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isCtaActive ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCtaActive
                        ? const Color(0xFF0B63CE)
                        : (isDark ? Colors.white12 : const Color(0xFFB0B0B0)),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.white12 : const Color(0xFFB0B0B0),
                    disabledForegroundColor: isDark ? Colors.white38 : Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    ctaLabel,
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

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  // ── Inline Calendar DatePicker Card (Image 3 & 6) ─────────────────────────
  Widget _buildInlineDatePicker(Color cardColor, bool isDark, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: cs.copyWith(
                primary: const Color(0xFF0B63CE),
                onPrimary: Colors.white,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: _tempDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              onDateChanged: (newDate) {
                HapticFeedback.selectionClick();
                setState(() => _tempDate = newDate);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isDateExpanded = false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0B63CE),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _tempDate;
                    _isDateExpanded = false;
                  });
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B63CE),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Inline Buffer Dropdown Card (Image 5) ─────────────────────────────────
  Widget _buildInlineBufferDropdown(Color cardColor, bool isDark, ColorScheme cs) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _bufferOptions.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
          itemBuilder: (ctx, index) {
            final mins = _bufferOptions[index];
            final isSelected = _bufferMinutes == mins;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _bufferMinutes = mins;
                  _isBufferExpanded = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$mins minutes after flight arrival',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF0B63CE) : cs.onSurface,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF0B63CE),
                        size: 20,
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

// ── Inline Clock Time Picker Card (Image 7) ─────────────────────────────────
class _InlineClockTimePickerCard extends StatefulWidget {
  const _InlineClockTimePickerCard({
    required this.cardColor,
    required this.isDark,
    required this.initialTime,
    required this.onCancel,
    required this.onOk,
  });

  final Color cardColor;
  final bool isDark;
  final TimeOfDay initialTime;
  final VoidCallback onCancel;
  final ValueChanged<TimeOfDay> onOk;

  @override
  State<_InlineClockTimePickerCard> createState() => _InlineClockTimePickerCardState();
}

class _InlineClockTimePickerCardState extends State<_InlineClockTimePickerCard> {
  late int _selectedHour; // 1..12
  late int _selectedMinute; // 0..59
  late bool _isPm;
  bool _isSelectingHour = true; // true = hour, false = minute
  bool _isKeypadMode = false;

  late final TextEditingController _hourInputCtrl;
  late final TextEditingController _minuteInputCtrl;

  @override
  void initState() {
    super.initState();
    _isPm = widget.initialTime.period == DayPeriod.pm;
    _selectedHour = widget.initialTime.hourOfPeriod;
    if (_selectedHour == 0) _selectedHour = 12;
    _selectedMinute = widget.initialTime.minute;

    _hourInputCtrl = TextEditingController(text: _selectedHour.toString().padLeft(2, '0'));
    _minuteInputCtrl = TextEditingController(text: _selectedMinute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourInputCtrl.dispose();
    _minuteInputCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _currentTimeOfDay {
    int h = _selectedHour % 12;
    if (_isPm) h += 12;
    return TimeOfDay(hour: h, minute: _selectedMinute);
  }

  void _onDialTap(Offset localPos, double dialRadius) {
    HapticFeedback.selectionClick();
    final center = Offset(dialRadius, dialRadius);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Angle clockwise from top (12 o'clock)
    double angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    if (_isSelectingHour) {
      // 12 sectors of 30 deg each
      int hour = (angle / (math.pi / 6)).round();
      if (hour == 0) hour = 12;
      setState(() {
        _selectedHour = hour;
        _hourInputCtrl.text = hour.toString().padLeft(2, '0');
      });

      // After picking hour, smoothly switch to minute
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && _isSelectingHour) {
          setState(() => _isSelectingHour = false);
        }
      });
    } else {
      // 60 minutes
      final minute = (angle / (math.pi / 30)).round() % 60;
      setState(() {
        _selectedMinute = minute;
        _minuteInputCtrl.text = minute.toString().padLeft(2, '0');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subtleBorder = widget.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    const dialDiameter = 220.0;
    const dialRadius = dialDiameter / 2;

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Digital Display Box (Image 7) ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour Box
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isSelectingHour = true);
                },
                child: Container(
                  width: 78,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _isSelectingHour
                        ? const Color(0xFFE9F2FD)
                        : (widget.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F4F8)),
                    borderRadius: BorderRadius.circular(12),
                    border: _isSelectingHour
                        ? Border.all(color: const Color(0xFF0B63CE).withValues(alpha: 0.3), width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedHour.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: _isSelectingHour
                          ? const Color(0xFF0B63CE)
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
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isSelectingHour = false);
                },
                child: Container(
                  width: 78,
                  height: 58,
                  decoration: BoxDecoration(
                    color: !_isSelectingHour
                        ? const Color(0xFFE9F2FD)
                        : (widget.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F4F8)),
                    borderRadius: BorderRadius.circular(12),
                    border: !_isSelectingHour
                        ? Border.all(color: const Color(0xFF0B63CE).withValues(alpha: 0.3), width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedMinute.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: !_isSelectingHour
                          ? const Color(0xFF0B63CE)
                          : cs.onSurface,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // AM / PM Selector
              Container(
                width: 48,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: subtleBorder),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isPm = false);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isPm ? const Color(0xFF0B63CE) : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'AM',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !_isPm ? Colors.white : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: subtleBorder),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isPm = true);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isPm ? const Color(0xFF0B63CE) : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'PM',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isPm ? Colors.white : cs.onSurfaceVariant,
                            ),
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

          // ── Clock Dial Face OR Keypad (Image 7) ───────────────────────────
          if (!_isKeypadMode)
            GestureDetector(
              onPanUpdate: (details) => _onDialTap(details.localPosition, dialRadius),
              onTapDown: (details) => _onDialTap(details.localPosition, dialRadius),
              child: SizedBox(
                width: dialDiameter,
                height: dialDiameter,
                child: CustomPaint(
                  painter: _ClockDialPainter(
                    isSelectingHour: _isSelectingHour,
                    selectedHour: _selectedHour,
                    selectedMinute: _selectedMinute,
                    isDark: widget.isDark,
                    cs: cs,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _hourInputCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 2,
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 1 && parsed <= 12) {
                          setState(() => _selectedHour = parsed);
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _minuteInputCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 2,
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 0 && parsed <= 59) {
                          setState(() => _selectedMinute = parsed);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // ── Bottom Row: Pencil Mode Toggle + Cancel & OK Buttons ──────────
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isKeypadMode ? Icons.access_time_rounded : Icons.edit_outlined,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isKeypadMode = !_isKeypadMode);
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0B63CE),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onOk(_currentTimeOfDay),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B63CE),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Custom Dial Painter for Clock ───────────────────────────────────────────
class _ClockDialPainter extends CustomPainter {
  _ClockDialPainter({
    required this.isSelectingHour,
    required this.selectedHour,
    required this.selectedMinute,
    required this.isDark,
    required this.cs,
  });

  final bool isSelectingHour;
  final int selectedHour;
  final int selectedMinute;
  final bool isDark;
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dialRadius = size.width / 2;

    // Dial background circle
    final dialBgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFEEF3F8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dialRadius, dialBgPaint);

    // Calculate active angle & pointer
    final numberRadius = dialRadius * 0.76;
    double activeAngle;

    if (isSelectingHour) {
      activeAngle = (selectedHour % 12) * (math.pi / 6) - (math.pi / 2);
    } else {
      activeAngle = selectedMinute * (math.pi / 30) - (math.pi / 2);
    }

    final selectedCenter = Offset(
      center.dx + numberRadius * math.cos(activeAngle),
      center.dy + numberRadius * math.sin(activeAngle),
    );

    // Needle line
    final linePaint = Paint()
      ..color = const Color(0xFF0B63CE)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, selectedCenter, linePaint);

    // Center pivot dot
    final pivotPaint = Paint()
      ..color = const Color(0xFF0B63CE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, pivotPaint);

    // Selected circle highlight
    final circlePaint = Paint()
      ..color = const Color(0xFF0B63CE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(selectedCenter, 18, circlePaint);

    // Draw Numbers
    if (isSelectingHour) {
      for (int h = 1; h <= 12; h++) {
        final angle = h * (math.pi / 6) - (math.pi / 2);
        final pos = Offset(
          center.dx + numberRadius * math.cos(angle),
          center.dy + numberRadius * math.sin(angle),
        );
        final isSelected = h == selectedHour;

        final tp = TextPainter(
          text: TextSpan(
            text: h.toString(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : cs.onSurface,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
      }
    } else {
      // 12 points for minutes: 00, 05, 10... 55
      for (int i = 0; i < 12; i++) {
        final m = i * 5;
        final angle = i * (math.pi / 6) - (math.pi / 2);
        final pos = Offset(
          center.dx + numberRadius * math.cos(angle),
          center.dy + numberRadius * math.sin(angle),
        );
        final isSelected = m == selectedMinute;

        final tp = TextPainter(
          text: TextSpan(
            text: m.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : cs.onSurface,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ClockDialPainter oldDelegate) {
    return oldDelegate.isSelectingHour != isSelectingHour ||
        oldDelegate.selectedHour != selectedHour ||
        oldDelegate.selectedMinute != selectedMinute ||
        oldDelegate.isDark != isDark;
  }
}
