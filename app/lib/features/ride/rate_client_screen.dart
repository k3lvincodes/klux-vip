import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/review_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RateClientScreen extends StatefulWidget {
  const RateClientScreen({super.key});

  @override
  State<RateClientScreen> createState() => _RateClientScreenState();
}

class _RateClientScreenState extends State<RateClientScreen> {
  int _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      CustomToast.showError(context, 'Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final rideProv = context.read<RideProvider>();
      final ride = rideProv.currentRideDetails;
      final user = Supabase.instance.client.auth.currentUser;

      if (ride == null || user == null) {
        if (mounted) context.go('/driver-home');
        return;
      }

      await ReviewRepository().submitReview(
        rideId: ride['id'],
        reviewerId: user.id,
        revieweeId: ride['passenger_id'],
        rating: _rating,
      );

      if (mounted) {
        rideProv.clearRide();
        CustomToast.showSuccess(context, 'Rating submitted!');
        context.go('/driver-home');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to submit rating');
        context.go('/driver-home');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.go('/driver-home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(
                Icons.star_outline,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Rate your client',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How was your experience with this passenger?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starNum),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        starNum <= _rating ? Icons.star : Icons.star_outline,
                        size: 44,
                        color: starNum <= _rating
                            ? Colors.amber
                            : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              CustomButton(
                title: _isSubmitting ? 'Submitting...' : 'Submit Rating',
                onPress: _isSubmitting ? () {} : _submitRating,
                variant: ButtonVariant.primary,
                height: 48,
                borderRadius: 16,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.read<RideProvider>().clearRide();
                  context.go('/driver-home');
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
