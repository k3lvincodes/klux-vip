import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/repositories/review_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideReviewScreen extends StatefulWidget {

  const RideReviewScreen({
    super.key,
    required this.rideId,
    required this.revieweeId,
    required this.revieweeName,
  });
  final String rideId;
  final String revieweeId;
  final String revieweeName;

  @override
  State<RideReviewScreen> createState() => _RideReviewScreenState();
}

class _RideReviewScreenState extends State<RideReviewScreen> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  final ReviewRepository _reviewRepo = ReviewRepository();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedRating == 0) {
      CustomToast.showError(context, 'Please select a rating');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _reviewRepo.submitReview(
          rideId: widget.rideId,
          reviewerId: user.id,
          revieweeId: widget.revieweeId,
          rating: _selectedRating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
      }

      if (mounted) {
        CustomToast.showSuccess(context, 'Thank you for your feedback!');
        _goHome();
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to submit review');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'Rate your ride',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How was your trip with ${widget.revieweeName}?',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        star <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        size: 48,
                        color: star <= _selectedRating
                            ? Colors.amber
                            : Colors.grey.shade400,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
                  controller: _commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment (optional)',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
              const Spacer(),
              CustomButton(
                title: _isLoading ? 'Submitting...' : 'Submit Review',
                onPress: _isLoading ? () {} : _handleSubmit,
                variant: ButtonVariant.primary,
                height: 48,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _goHome,
                child: const Text('Skip', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome() {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'];
    if (role == 'Chauffeur' || role == 'Affiliate') {
      context.go('/driver-home');
    } else {
      context.go('/passenger-home');
    }
  }
}
