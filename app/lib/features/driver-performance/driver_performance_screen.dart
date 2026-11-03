import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/models/review.dart';
import 'package:kenick_vip/repositories/review_repository.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverPerformanceScreen extends StatefulWidget {
  const DriverPerformanceScreen({super.key});

  @override
  State<DriverPerformanceScreen> createState() => _DriverPerformanceScreenState();
}

class _DriverPerformanceScreenState extends State<DriverPerformanceScreen> {
  final ReviewRepository _reviewRepo = ReviewRepository();
  final RideRepository _rideRepo = RideRepository();
  List<Review> _reviews = [];
  int _totalRides = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final reviews = await _reviewRepo.getReviewsForUser(user.id);
      final completedRides = await _rideRepo.getDriverCompletedRides(user.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _totalRides = completedRides.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load performance data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool hasReviews = _reviews.isNotEmpty;
    final double avgRating = hasReviews
        ? _reviews.fold<double>(0.0, (sum, r) => sum + r.rating.toDouble()) / _reviews.length
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Circular Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
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
                          color: isDark ? const Color(0xFF1E2026) : Colors.white,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFE4E4E7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Performance & Ratings',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _loadData,
                                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                                  label: Text(
                                    'Try Again',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppColors.primary,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            children: [
                              // Rating & Performance Metrics Card (Two-Tier Stage Blueprint)
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2026) : const Color(0xFFE4E4E7),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF27272A)
                                        : const Color(0xFFD4D4D8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF121316) : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        // Average Rating Column
                                        Column(
                                          children: [
                                            Text(
                                              hasReviews ? avgRating.toStringAsFixed(1) : '--',
                                              style: GoogleFonts.poppins(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF18181B),
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(5, (i) {
                                                final filled = hasReviews && (i < avgRating.round());
                                                return Icon(
                                                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                                  size: 18,
                                                  color: filled
                                                      ? AppColors.primary
                                                      : (isDark
                                                          ? const Color(0xFF3F3F46)
                                                          : const Color(0xFFD4D4D8)),
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              hasReviews
                                                  ? '${_reviews.length} review${_reviews.length == 1 ? '' : 's'}'
                                                  : 'No reviews yet',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w400,
                                                color: isDark
                                                    ? const Color(0xFFA1A1AA)
                                                    : const Color(0xFF71717A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 22),
                                        // Vertical Divider
                                        Container(
                                          width: 1,
                                          height: 80,
                                          color: isDark
                                              ? const Color(0xFF27272A)
                                              : const Color(0xFFE4E4E7),
                                        ),
                                        const SizedBox(width: 22),
                                        // Stats Column
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _buildStat(
                                                Icons.directions_car_filled_outlined,
                                                'Completed Trips',
                                                '$_totalRides',
                                                isDark,
                                              ),
                                              const SizedBox(height: 14),
                                              _buildStat(
                                                Icons.verified_outlined,
                                                'Completion Rate',
                                                _totalRides > 0 ? '100%' : '--',
                                                isDark,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),

                              // Rating Breakdown Section Header
                              Text(
                                'Rating Breakdown',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF121316) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                  ),
                                ),
                                child: Column(
                                  children: List.generate(5, (i) {
                                    final star = 5 - i;
                                    final count = _reviews.where((r) => r.rating == star).length;
                                    final pct = hasReviews ? count / _reviews.length : 0.0;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: i < 4 ? 12 : 0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            child: Text(
                                              '$star',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : const Color(0xFF18181B),
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                minHeight: 7,
                                                backgroundColor: isDark
                                                    ? const Color(0xFF1E2026)
                                                    : const Color(0xFFE5E7EB),
                                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 28,
                                            child: Text(
                                              '$count',
                                              textAlign: TextAlign.end,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 26),

                              // Recent VIP Reviews
                              Text(
                                'Recent VIP Reviews',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_reviews.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF121316) : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 38,
                                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No reviews yet',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : const Color(0xFF18181B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Client ratings and testimonials will be published here upon ride completion.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w400,
                                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ..._reviews.take(10).map((r) {
                                  final int rating = r.rating;
                                  final String? comment = r.comment;
                                  final String date = r.createdAt.toLocal().toString().split(' ')[0];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF121316) : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            ...List.generate(
                                              5,
                                              (i) => Icon(
                                                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                                size: 16,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              date,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11.5,
                                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (comment != null && comment.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            comment,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: isDark ? Colors.white : const Color(0xFF18181B),
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
