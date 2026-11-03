import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/review_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
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
                      onTap: () {
                        context.read<RideProvider>().clearRide();
                        context.go('/driver-home');
                      },
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
                    'Rate Passenger',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.star_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Rate Your Client',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'How was your luxury chauffeur experience with $_passengerName?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                        height: 1.45,
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
                                  ? AppColors.primary
                                  : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8)),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121316) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add an optional note about this trip...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Signature Gold Pill Submit Rating CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF111827),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF111827),
                                ),
                              )
                            : Text(
                                'Submit Rating',
                                style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                  letterSpacing: 0.1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {
                        context.read<RideProvider>().clearRide();
                        context.go('/driver-home');
                      },
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                          fontWeight: FontWeight.w500,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
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
