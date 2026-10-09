import 'package:flutter/material.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class RideSearchIndicator extends StatefulWidget {

  const RideSearchIndicator({
    super.key,
    required this.isSearching,
    this.searchingText = 'Finding your driver',
    this.foundText = 'Driver found',
    this.driverName,
    this.driverRating,
    this.driverAvatarUrl,
    this.carModel,
    this.eta,
    this.onCancelSearch,
    this.onContactDriver,
    this.margin,
  });
  final bool isSearching;
  final String searchingText;
  final String foundText;
  final String? driverName;
  final String? driverRating;
  final String? driverAvatarUrl;
  final String? carModel;
  final String? eta;
  final VoidCallback? onCancelSearch;
  final VoidCallback? onContactDriver;
  final EdgeInsetsGeometry? margin;

  @override
  State<RideSearchIndicator> createState() => _RideSearchIndicatorState();
}

class _RideSearchIndicatorState extends State<RideSearchIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeSlideIn(
      delay: const Duration(milliseconds: 80),
      slideOffset: -0.03,
      child: AnimatedSwitcher(
        duration: AppDurations.slow,
        switchInCurve: AppCurves.easeOutCubic,
        switchOutCurve: AppCurves.easeOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: widget.isSearching ? _buildSearching(isDark) : _buildFound(isDark),
      ),
    );
  }

  Widget _buildSearching(bool isDark) {
    return Container(
      key: const ValueKey('searching'),
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 44 * _pulseAnim.value,
                      height: 44 * _pulseAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: _opacityAnim.value),
                      ),
                    );
                  },
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.radar,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SearchingText(text: widget.searchingText),
                const SizedBox(height: 2),
                Text(
                  'Please wait a moment',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onCancelSearch != null)
            GestureDetector(
              onTap: widget.onCancelSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFound(bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : const Color(0xFFF2FBF4);
    final borderColor = isDark ? AppColors.primary.withValues(alpha: 0.25) : Colors.green.shade200;
    final accentColor = isDark ? AppColors.primary : Colors.green.shade700;

    return Container(
      key: const ValueKey('found'),
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 16, color: isDark ? Colors.black : Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.foundText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              if (widget.eta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary.withValues(alpha: 0.2) : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
                  ),
                  child: Text(
                    '${widget.eta} min',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.driverName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  backgroundImage: widget.driverAvatarUrl != null
                      ? NetworkImage(widget.driverAvatarUrl!)
                      : null,
                  child: widget.driverAvatarUrl == null
                      ? Icon(Icons.person, size: 18, color: isDark ? AppColors.primary : Colors.grey)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.driverName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.carModel != null)
                        Text(
                          widget.carModel!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (widget.driverRating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        widget.driverRating!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (widget.onContactDriver != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onContactDriver,
                icon: const Icon(Icons.message_rounded, size: 14),
                label: const Text('Contact Chauffeur', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: isDark ? AppColors.primary.withValues(alpha: 0.5) : Colors.green.shade400),
                  foregroundColor: isDark ? AppColors.primary : Colors.green.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchingText extends StatefulWidget {
  const _SearchingText({required this.text});
  final String text;

  @override
  State<_SearchingText> createState() => _SearchingTextState();
}

class _SearchingTextState extends State<_SearchingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsController;
  late final Animation<double> _dotsAnim;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _dotsAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        final dotCount = (_dotsAnim.value * 6).floor() % 4;
        final dots = '.' * dotCount;
        return Text(
          '${widget.text}$dots',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.black,
          ),
        );
      },
    );
  }
}
