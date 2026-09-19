import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/review.dart';
import 'package:kenick_vip/repositories/review_repository.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverPerformanceScreen extends StatefulWidget {
  const DriverPerformanceScreen({super.key});

  @override
  State<DriverPerformanceScreen> createState() => _DriverPerformanceScreenState();
}

class _DriverPerformanceScreenState extends State<DriverPerformanceScreen> {
  static const Color goldColor = Color(0xFFD4AF37);
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
      if (mounted) setState(() { _isLoading = false; _error = 'Failed to load performance data'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool hasReviews = _reviews.isNotEmpty;
    final double avgRating = hasReviews
        ? _reviews.fold<double>(0.0, (sum, r) => sum + r.rating.toDouble()) / _reviews.length
        : 0.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Performance & Ratings',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_error!, style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        TextButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Rating & Telemetry Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            // Average Rating
                            Column(
                              children: [
                                Text(
                                  hasReviews ? avgRating.toStringAsFixed(1) : '--',
                                  style: textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (i) {
                                    final filled = hasReviews && (i < avgRating.round());
                                    return Icon(
                                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 20,
                                      color: filled ? goldColor : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  hasReviews
                                      ? '${_reviews.length} review${_reviews.length == 1 ? '' : 's'}'
                                      : 'No reviews yet',
                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Divider
                            Container(
                              width: 1,
                              height: 80,
                              color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                            ),
                            const SizedBox(width: 24),
                            // Stats
                            Expanded(
                              child: Column(
                                children: [
                                  _buildStat(context, Icons.directions_car_outlined, 'Completed Trips', '$_totalRides'),
                                  const SizedBox(height: 14),
                                  _buildStat(context, Icons.verified_outlined, 'Completion Rate', _totalRides > 0 ? '100%' : '--'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating Breakdown
                      Text(
                        'Rating Breakdown',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(5, (i) {
                        final star = 5 - i;
                        final count = _reviews.where((r) => r.rating == star).length;
                        final pct = hasReviews ? count / _reviews.length : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                child: Text(
                                  '$star',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Icon(Icons.star_rounded, size: 16, color: goldColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 8,
                                    backgroundColor: colorScheme.surfaceContainerHighest,
                                    valueColor: const AlwaysStoppedAnimation(goldColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.end,
                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // Recent Reviews
                      Text(
                        'Recent VIP Reviews',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_reviews.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.15)),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined, size: 36, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                const SizedBox(height: 10),
                                Text(
                                  'No reviews yet',
                                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Client ratings and testimonials will be published here upon ride completion.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
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
                                        color: goldColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(date, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                if (comment != null && comment.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    comment,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
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
