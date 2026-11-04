import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

enum FaqReaction { sad, neutral, happy }

class FaqArticle {
  const FaqArticle({
    required this.question,
    required this.date,
    required this.intro,
    required this.sections,
  });

  final String question;
  final String date;
  final String intro;
  final List<FaqSection> sections;
}

class FaqSection {
  const FaqSection({
    required this.title,
    this.subtitle,
    required this.paragraphs,
    this.bullets,
  });

  final String title;
  final String? subtitle;
  final List<String> paragraphs;
  final List<String>? bullets;
}

class FaqDetailScreen extends StatefulWidget {
  const FaqDetailScreen({
    super.key,
    required this.question,
    this.article,
  });

  final String question;
  final FaqArticle? article;

  @override
  State<FaqDetailScreen> createState() => _FaqDetailScreenState();
}

class _FaqDetailScreenState extends State<FaqDetailScreen> {
  FaqReaction? _selectedReaction;

  FaqArticle get _resolvedArticle {
    if (widget.article != null) return widget.article!;
    return _getFaqArticleForQuestion(widget.question);
  }

  static FaqArticle _getFaqArticleForQuestion(String question) {
    final lower = question.toLowerCase();

    if (lower.contains('change') || lower.contains('modify') || lower.contains('booking')) {
      return const FaqArticle(
        question: 'How can I make changes to my booking?',
        date: 'September 22, 2026',
        intro:
            'The quickest and easiest way to edit or cancel your booking is through our website or app. You can instantly confirm changes at the best available price, whether you’re updating the pick-up time or address, or adjusting the guest’s phone number.',
        sections: [
          FaqSection(
            title: 'Before editing your ride',
            subtitle: 'Please keep in mind:',
            bullets: [
              'Our booking change policy allows modifications free of charge up to 1 hour before scheduled pickup for one-way transfers, and up to 24 hours for hourly chauffeur bookings.',
              'If you’ve arranged an airport transfer, we’ll track your flight arrival time and adjust your pickup time so that your chauffeur is waiting for you on arrival. This means you can relax and take your time knowing that we’re informed and waiting for you. You won’t necessarily see a change of pickup time on your end, but don’t worry, your chauffeur will be automatically notified of any flight updates.',
              'All changes are subject to chauffeur availability and local vehicle dispatch limits. When you submit a change, we instantly confirm with your assigned chauffeur.',
              'Any price difference will be displayed transparently before you confirm. If a change leads to an updated fare, your card will only be adjusted for the exact difference with no penalty fees.',
            ],
            paragraphs: [
              'If two transactions for the same booking have both been completed as charges, contact Kenick Care immediately for instantaneous resolution.',
            ],
          ),
          FaqSection(
            title: 'Changing a booking with a promotion applied',
            paragraphs: [
              'Bookings with a promo code or voucher can generally be edited through the normal booking-management flow. However, you may not be able to change or remove an applied promotion while editing.',
              'If the edit cannot be completed, or you need to remove the promotion, you may need to cancel and rebook. Before cancelling, check the cancellation terms and the promotion’s validity and usage conditions. If you are unsure whether it can be reused, contact Kenick Care before cancelling.',
            ],
          ),
        ],
      );
    }

    if (lower.contains('cancel') || lower.contains('cancellation')) {
      return const FaqArticle(
        question: 'Cancellation policy & how can I cancel?',
        date: 'October 14, 2026',
        intro:
            'Kenick VIP offers generous, flexible cancellation policies so you can reserve your luxury journeys with total peace of mind.',
        sections: [
          FaqSection(
            title: 'Complimentary Cancellation Windows',
            subtitle: 'Standard Cancellation Rules:',
            bullets: [
              'One-Way Transfers: Free cancellation up to 1 hour before your scheduled pickup time.',
              'By-The-Hour Chauffeur Hire: Free cancellation up to 24 hours prior to the reservation start time.',
              'Special Events & Multi-Vehicle Delegations: Free cancellation up to 48 hours in advance.',
            ],
            paragraphs: [
              'Cancellations made within the free cancellation window result in a 100% full refund back to your original payment method within 2–5 business days.',
            ],
          ),
          FaqSection(
            title: 'How to cancel from the Kenick app',
            paragraphs: [
              'Navigate to the "Rides" tab at the bottom of the screen, select your upcoming journey under "Upcoming", tap "Ride Details", and choose "Cancel reservation". Confirm your selection and your ride will be cancelled immediately.',
              'If you need emergency assistance or wish to reroute rather than cancel, our 24/7 Kenick Concierge is accessible with one tap from the Help screen.',
            ],
          ),
        ],
      );
    }

    if (lower.contains('booked for me') || lower.contains('guest')) {
      return const FaqArticle(
        question: 'Where do I see a ride that was booked for me?',
        date: 'October 8, 2026',
        intro:
            'When an executive assistant, travel manager, or friend books a Kenick VIP ride on your behalf, your reservation syncs seamlessly across devices.',
        sections: [
          FaqSection(
            title: 'Automatic Account Sync',
            paragraphs: [
              'As long as the person reserving the ride entered your verified mobile phone number or email address as the primary passenger, the ride will automatically appear in your "Rides" tab under "Upcoming".',
              'You will also receive an SMS and email notification with your booking reference, chauffeur status link, and real-time flight tracking updates.',
            ],
          ),
          FaqSection(
            title: 'If the ride is not appearing',
            paragraphs: [
              'Ensure you are logged into the app with the exact phone number or email provided during booking. If the booking was placed under a guest profile, you can ask the booker to share the reservation link with you.',
              'You can also contact Kenick Care with your 6-character booking code, and our concierge will link it to your profile right away.',
            ],
          ),
        ],
      );
    }

    if (lower.contains('chauffeur') || lower.contains('driver')) {
      return const FaqArticle(
        question: 'Where is my chauffeur?',
        date: 'September 28, 2026',
        intro:
            'Track your assigned chauffeur in real time with live GPS telemetry, vehicle specifications, and direct communication.',
        sections: [
          FaqSection(
            title: 'Chauffeur Assignment & Live Tracking',
            paragraphs: [
              'Your chauffeur details and vehicle registration are assigned and dispatched in advance. Approximately 30 minutes before your pickup, you will receive notification that your chauffeur is en route.',
              'You can open the Kenick VIP app to see the vehicle’s exact live GPS position moving on the map, along with the estimated arrival time, vehicle make, model, license plate, and driver contact number.',
            ],
          ),
          FaqSection(
            title: 'Airport Meet & Greet',
            paragraphs: [
              'For all airport pickups, your chauffeur will be waiting inside the arrivals terminal holding a personalized digital iPad name board. They will also assist with your luggage and escort you directly to your executive vehicle.',
              'If you experience any customs or baggage claim delays, rest assured you enjoy 60 minutes of complimentary wait time after your flight touches down.',
            ],
          ),
        ],
      );
    }

    if (lower.contains('vehicle') || lower.contains('fleet')) {
      return const FaqArticle(
        question: 'What vehicles does Kenick use?',
        date: 'September 15, 2026',
        intro:
            'Kenick VIP operates a handpicked fleet of late-model, pristine luxury vehicles maintained to rigorous safety and comfort standards.',
        sections: [
          FaqSection(
            title: 'Executive VIP Categories',
            bullets: [
              'Sedans (Lowest Pricing): Mercedes-Benz S-Class, E-Class, or BMW 7 Series sedan (seats 3 passengers, fits 2 medium luggage pieces). Equipped with leather seating, climate control, and bottled water.',
              'SUVs: Full-size luxury SUVs like Cadillac Escalade or GMC Yukon Denali (seats up to 5 passengers, fits 4 luggage pieces).',
              'Vans: Mercedes-Benz V-Class MPV or VIP Sprinters (seats up to 7 passengers, fits 6 luggage pieces). Ideal for executive teams and traveling delegations.',
              'Buses (Highest Pricing): Executive minibuses & luxury VIP coaches (seats 16+ passengers with extensive luggage capacity) for large delegation movements.',
            ],
            paragraphs: [
              'Every vehicle in our fleet is smoke-free, sanitized before every assignment, equipped with high-speed smartphone charging, and piloted by a certified professional chauffeur in formal attire.',
            ],
          ),
        ],
      );
    }

    // Default / General Help
    return FaqArticle(
      question: question,
      date: 'September 22, 2026',
      intro:
          'Kenick VIP delivers unparalleled chauffeur-driven luxury travel across private transfers, airport pickups, and hourly concierge hire.',
      sections: const [
        FaqSection(
          title: 'Immediate 24/7 Assistance',
          paragraphs: [
            'Our dedicated Kenick VIP Concierge and Care Team is available 24 hours a day, 7 days a week to handle special requests, child seats, multi-vehicle itineraries, and corporate invoicing.',
            'You can message our Kenick AI agent directly in the app or tap "Call us" to speak with a concierge specialist immediately.',
          ],
        ),
      ],
    );
  }

  void _handleReaction(FaqReaction reaction) {
    if (_selectedReaction == reaction) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedReaction = reaction);

    final String message;
    switch (reaction) {
      case FaqReaction.happy:
        message = 'Thank you for your feedback!';
        break;
      case FaqReaction.neutral:
        message = 'Thanks for your input. We\'ll keep improving!';
        break;
      case FaqReaction.sad:
        message = 'Thanks for letting us know. Contact our concierge anytime for direct help!';
        break;
    }
    CustomToast.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final article = _resolvedArticle;

    final subtleDivider = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Close "X" Button (Left-aligned)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 28,
                      color: cs.onSurface,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Article Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Article Question / Headline
                    Text(
                      article.question,
                      style: GoogleFonts.poppins(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Date
                    Text(
                      article.date,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Intro Paragraph
                    Text(
                      article.intro,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Article Sections
                    for (final section in article.sections) ...[
                      // Section Title
                      Text(
                        section.title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),

                      if (section.subtitle != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          section.subtitle!,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],

                      if (section.bullets != null) ...[
                        const SizedBox(height: 12),
                        for (final bullet in section.bullets!) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, right: 10),
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w400,
                                      color: cs.onSurface,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      for (final p in section.paragraphs) ...[
                        const SizedBox(height: 14),
                        Text(
                          p,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurface,
                            height: 1.55,
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),
                    ],

                    Divider(height: 1, thickness: 1, color: subtleDivider),

                    const SizedBox(height: 32),

                    // Feedback Section: "Did this answer your question?"
                    Center(
                      child: Text(
                        'Did this answer your question?',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3 Emoji Feedback Buttons: Sad, Neutral, Happy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEmojiButton(
                          reaction: FaqReaction.sad,
                          painter: const _SadEmojiPainter(),
                        ),
                        const SizedBox(width: 24),
                        _buildEmojiButton(
                          reaction: FaqReaction.neutral,
                          painter: const _NeutralEmojiPainter(),
                        ),
                        const SizedBox(width: 24),
                        _buildEmojiButton(
                          reaction: FaqReaction.happy,
                          painter: const _HappyEmojiPainter(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton({
    required FaqReaction reaction,
    required CustomPainter painter,
  }) {
    final isSelected = _selectedReaction == reaction;

    return GestureDetector(
      onTap: () => _handleReaction(reaction),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
        ),
        child: CustomPaint(
          size: const Size(48, 48),
          painter: painter,
        ),
      ),
    );
  }
}

/// Custom painter for Sad Emoji face matching reference design
class _SadEmojiPainter extends CustomPainter {
  const _SadEmojiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Face background (warm yellow)
    final facePaint = Paint()..color = const Color(0xFFF6C944);
    canvas.drawCircle(center, radius, facePaint);

    final darkPaint = Paint()
      ..color = const Color(0xFF332005)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF332005)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Left eyebrow (worried angled)
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.30),
      Offset(size.width * 0.42, size.height * 0.35),
      strokePaint,
    );

    // Right eyebrow (worried angled)
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.30),
      Offset(size.width * 0.58, size.height * 0.35),
      strokePaint,
    );

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.44),
        width: 4.5,
        height: 6,
      ),
      darkPaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.44),
        width: 4.5,
        height: 6,
      ),
      darkPaint,
    );

    // Sad downturned mouth arc
    final mouthPath = Path();
    mouthPath.arcTo(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.78),
        width: size.width * 0.42,
        height: size.height * 0.30,
      ),
      3.5,
      2.4,
      false,
    );
    canvas.drawPath(mouthPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for Neutral Emoji face matching reference design
class _NeutralEmojiPainter extends CustomPainter {
  const _NeutralEmojiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Face background
    final facePaint = Paint()..color = const Color(0xFFF6C944);
    canvas.drawCircle(center, radius, facePaint);

    final darkPaint = Paint()
      ..color = const Color(0xFF332005)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF332005)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.42),
        width: 4.8,
        height: 6.2,
      ),
      darkPaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.42),
        width: 4.8,
        height: 6.2,
      ),
      darkPaint,
    );

    // Neutral straight line mouth
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.66),
      Offset(size.width * 0.66, size.height * 0.66),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for Happy Emoji face matching reference design
class _HappyEmojiPainter extends CustomPainter {
  const _HappyEmojiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Face background
    final facePaint = Paint()..color = const Color(0xFFF6C944);
    canvas.drawCircle(center, radius, facePaint);

    final darkPaint = Paint()
      ..color = const Color(0xFF332005)
      ..style = PaintingStyle.fill;

    // Left eye (curved smiling eye or open circle)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.40),
        width: 5.2,
        height: 6.8,
      ),
      darkPaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.40),
        width: 5.2,
        height: 6.8,
      ),
      darkPaint,
    );

    // Big happy open smile
    final smilePath = Path();
    smilePath.moveTo(size.width * 0.28, size.height * 0.58);
    smilePath.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.90,
      size.width * 0.72,
      size.height * 0.58,
    );
    smilePath.close();
    canvas.drawPath(smilePath, darkPaint);

    // White teeth line inside top of smile
    final teethPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final teethPath = Path();
    teethPath.moveTo(size.width * 0.32, size.height * 0.59);
    teethPath.lineTo(size.width * 0.68, size.height * 0.59);
    teethPath.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.72,
      size.width * 0.32,
      size.height * 0.59,
    );
    teethPath.close();
    canvas.drawPath(teethPath, teethPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
