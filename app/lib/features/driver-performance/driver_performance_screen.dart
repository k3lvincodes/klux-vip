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

    double avgRating = 0;
    if (_reviews.isNotEmpty) {
      final total = _reviews.fold<double>(0.0, (sum, r) {
        final rating = r.rating;
        return sum + rating.toDouble();
      });
      avgRating = total / _reviews.length;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Performance & Ratings', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                  // Rating Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          // Average Rating
                          Column(
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (i) {
                                  final filled = i < avgRating.round();
                                  return Icon(
                                    filled ? Icons.star : Icons.star_border,
                                    size: 18,
                                    color: filled ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_reviews.length} review${_reviews.length == 1 ? '' : 's'}',
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(width: 32),
                          // Stats
                          Expanded(
                            child: Column(
                              children: [
                                _buildStat(context, Icons.directions_car_outlined, 'Total Rides', '$_totalRides'),
                                const SizedBox(height: 16),
                                _buildStat(context, Icons.reviews_outlined, 'Reviews', '${_reviews.length}'),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                  const SizedBox(height: 12),
                  ...List.generate(5, (i) {
                    final star = 5 - i;
                    final count = _reviews.where((r) => r.rating == star).length;
                    final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('$star', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                          Icon(Icons.star, size: 14, color: colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(colorScheme.tertiary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 24, child: Text('$count', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Recent Reviews
                  Text(
                    'Recent Reviews',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No reviews yet', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ),
                    )
                  else
                    ..._reviews.take(10).map((r) {
                      final int rating = r.rating;
                      final String? comment = r.comment;
                      final String date = r.createdAt.toLocal().toString().split(' ')[0];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, size: 16, color: colorScheme.tertiary)),
                                  const Spacer(),
                                  Text(date, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                ],
                              ),
                              if (comment != null && comment.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(comment, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                              ],
                            ],
                          ),
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
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            Text(value, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ],
        ),
      ],
    );
  }
}
