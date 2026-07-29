import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';

class BookingInvoiceScreen extends StatelessWidget {
  const BookingInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>? ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fareAmount = (args['fareAmount'] as num?)?.toDouble() ?? 0.0;
    final tipAmount = (args['tipAmount'] as num?)?.toDouble() ?? 0.0;
    final taxAmount = (args['taxAmount'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (args['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final pickupAddress = args['pickupAddress'] as String? ?? '';
    final dropoffAddress = args['dropoffAddress'] as String? ?? '';
    final vehicleType = args['vehicleType'] as String? ?? '';
    final tripDate = args['tripDate'] as String? ?? '';
    final paymentMethodLast4 = args['paymentMethodLast4'] as String? ?? 'XXXX';
    final bookingConfirmation =
        args['bookingConfirmation'] as String? ?? 'BK-000000';
    final invoiceNumber =
        args['invoiceNumber'] as String? ?? 'KLX-00000000-0000';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  PressScale(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark ? AppColors.white : AppColors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Invoice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Success header
                    FadeSlideIn(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.3),
                                  AppColors.primary.withValues(alpha: 0.06),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.black,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Payment Successful!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? AppColors.darkText : AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your booking is confirmed',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Invoice card
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: _InvoiceCard(
                        isDark: isDark,
                        fareAmount: fareAmount,
                        tipAmount: tipAmount,
                        taxAmount: taxAmount,
                        totalAmount: totalAmount,
                        pickupAddress: pickupAddress,
                        dropoffAddress: dropoffAddress,
                        vehicleType: vehicleType,
                        tripDate: tripDate,
                        paymentMethodLast4: paymentMethodLast4,
                        bookingConfirmation: bookingConfirmation,
                        invoiceNumber: invoiceNumber,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 250),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            CustomButton(
                              title: 'Track Chauffeur',
                              onPress: () => context.go('/passenger-home'),
                              variant: ButtonVariant.primary,
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              title: 'Download Receipt',
                              onPress: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Receipt saved to downloads'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              variant: ButtonVariant.outline,
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              title: 'Book Another Ride',
                              onPress: () =>
                                  context.go('/booking-selection'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.isDark,
    required this.fareAmount,
    required this.tipAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.vehicleType,
    required this.tripDate,
    required this.paymentMethodLast4,
    required this.bookingConfirmation,
    required this.invoiceNumber,
  });

  final bool isDark;
  final double fareAmount;
  final double tipAmount;
  final double taxAmount;
  final double totalAmount;
  final String pickupAddress;
  final String dropoffAddress;
  final String vehicleType;
  final String tripDate;
  final String paymentMethodLast4;
  final String bookingConfirmation;
  final String invoiceNumber;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Company header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Column(
              children: [
                Text(
                  'KLUX VIP',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Premium Transportation',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              children: [
                // Invoice / Booking info row
                _InfoRow(
                  label: 'Invoice',
                  value: invoiceNumber,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Booking',
                  value: bookingConfirmation,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),

                // Trip date
                _InfoRow(
                  label: 'Trip Date',
                  value: tripDate,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Vehicle',
                  value: vehicleType,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Passenger',
                  value: 'Customer',
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),

                // Pickup / Dropoff
                _LocationRow(
                  icon: Icons.circle,
                  iconColor: Colors.green,
                  address: pickupAddress,
                  subtitle: 'Pickup',
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: CustomPaint(
                    size: const Size(2, 24),
                    painter: _DashedLinePainter(
                      color: mutedColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                _LocationRow(
                  icon: Icons.place,
                  iconColor: Colors.red,
                  address: dropoffAddress,
                  subtitle: 'Dropoff',
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),

                // Fare breakdown
                _FareRow(
                    label: 'Base Fare',
                    value: fareAmount,
                    textColor: textColor,
                    mutedColor: mutedColor),
                const SizedBox(height: 8),
                _FareRow(
                    label: 'Trip Fare',
                    value: fareAmount,
                    textColor: textColor,
                    mutedColor: mutedColor),
                const SizedBox(height: 8),
                _FareRow(
                    label: 'Tip',
                    value: tipAmount,
                    textColor: textColor,
                    mutedColor: mutedColor),
                const SizedBox(height: 8),
                _FareRow(
                    label: 'Tax',
                    value: taxAmount,
                    textColor: textColor,
                    mutedColor: mutedColor),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 14),

                // Payment method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment',
                      style: TextStyle(fontSize: 13, color: mutedColor),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PAID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '•••• $paymentMethodLast4',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Dashed border at bottom
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width - 44,
              1,
            ),
            painter: _DashedBorderPainter(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: mutedColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.address,
    required this.subtitle,
    required this.textColor,
    required this.mutedColor,
  });

  final IconData icon;
  final Color iconColor;
  final String address;
  final String subtitle;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: mutedColor),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
  });

  final String label;
  final double value;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: mutedColor),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashHeight = 4.0;
    const gap = 3.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, y + dashHeight),
        paint,
      );
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const gap = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dashWidth, 0),
        paint,
      );
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
