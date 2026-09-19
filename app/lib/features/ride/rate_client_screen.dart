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
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String _passengerName = 'VIP Client';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPassengerName());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchPassengerName() async {
    final rideProv = context.read<RideProvider>();
    final ride = rideProv.currentRideDetails;
    final passengerId = ride?['passenger_id'] as String?;
    if (passengerId == null || passengerId.isEmpty) return;

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', passengerId)
          .maybeSingle();

      if (res != null && mounted) {
        final name = '${res['first_name'] ?? ''} ${res['last_name'] ?? ''}'.trim();
        if (name.isNotEmpty) {
          setState(() => _passengerName = name);
        }
      }
    } catch (_) {}
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      CustomToast.showError(context, 'Please select a star rating');
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
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        rideProv.clearRide();
        CustomToast.showSuccess(context, 'Feedback submitted successfully!');
        context.go('/driver-home');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to submit rating. Please try again.');
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () {
            context.read<RideProvider>().clearRide();
            context.go('/driver-home');
          },
        ),
        title: Text(
          'Rate Passenger',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rate Your Client',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How was your luxury chauffeur experience with $_passengerName?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starNum),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        starNum <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 44,
                        color: starNum <= _rating
                            ? const Color(0xFFD4AF37)
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add an optional note about this trip...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                title: _isSubmitting ? 'Submitting...' : 'Submit Rating',
                onPress: _isSubmitting ? () {} : _submitRating,
                variant: ButtonVariant.primary,
                height: 50,
                borderRadius: 16,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  context.read<RideProvider>().clearRide();
                  context.go('/driver-home');
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
