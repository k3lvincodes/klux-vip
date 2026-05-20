import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/repositories/review_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';

class DriverPerformanceScreen extends StatefulWidget {
  const DriverPerformanceScreen({super.key});

  @override
  State<DriverPerformanceScreen> createState() => _DriverPerformanceScreenState();
}

class _DriverPerformanceScreenState extends State<DriverPerformanceScreen> {
  final ReviewRepository _reviewRepo = ReviewRepository();
  final RideRepository _rideRepo = RideRepository();
  List<Map<String, dynamic>> _reviews = [];
  int _totalRides = 0;
  bool _isLoading = true;

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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double avgRating = 0;
    if (_reviews.isNotEmpty) {
      final total = _reviews.fold<double>(0.0, (sum, r) {
        final rating = (r['rating'] as num?) ?? 0;
        return sum + rating.toDouble();
      });
      avgRating = total / _reviews.length;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text('Performance & Ratings', style: TextStyle(color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Rating Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.darkSurface, Colors.grey.shade900]
                            : [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // Average Rating
                        Column(
                          children: [
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.white : AppColors.black,
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
                                  color: filled ? Colors.amber : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_reviews.length} review${_reviews.length == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),
                        // Stats
                        Expanded(
                          child: Column(
                            children: [
                              _buildStat(Icons.directions_car_outlined, 'Total Rides', '$_totalRides', isDark),
                              const SizedBox(height: 16),
                              _buildStat(Icons.reviews_outlined, 'Reviews', '${_reviews.length}', isDark),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(5, (i) {
                    final star = 5 - i;
                    final count = _reviews.where((r) => (r['rating'] as num?)?.toInt() == star).length;
                    final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('$star', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation(Colors.amber),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 24, child: Text('$count', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Recent Reviews
                  Text(
                    'Recent Reviews',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No reviews yet', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
                      ),
                    )
                  else
                    ..._reviews.take(10).map((r) {
                      final rating = (r['rating'] as num?)?.toInt() ?? 5;
                      final comment = r['comment'] as String?;
                      final date = r['created_at'] != null
                          ? DateTime.tryParse(r['created_at'])?.toLocal().toString().split(' ')[0] ?? ''
                          : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, size: 16, color: Colors.amber)),
                                const Spacer(),
                                Text(date, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
                              ],
                            ),
                            if (comment != null && comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(comment, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
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

  Widget _buildStat(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.black)),
          ],
        ),
      ],
    );
  }
}
