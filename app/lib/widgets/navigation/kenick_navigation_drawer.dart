import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/features/booking/saved_places_screen.dart';
import 'package:kenick_vip/features/legal/legal_information_screen.dart';
import 'package:kenick_vip/features/newsfeed/newsfeed_screen.dart';
import 'package:kenick_vip/features/notifications/notifications_screen.dart';
import 'package:kenick_vip/features/payment/payment_method_screen.dart';
import 'package:kenick_vip/features/profile/passenger_profile_screen.dart';
import 'package:kenick_vip/features/rewards/offers_rewards_screen.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KenickNavigationDrawer extends StatefulWidget {
  const KenickNavigationDrawer({
    super.key,
    required this.userName,
    required this.isDark,
    this.avatarUrl,
    this.isDriver = false,
    this.isAffiliate = false,
  });

  final String userName;
  final bool isDark;
  final String? avatarUrl;
  final bool isDriver;
  final bool isAffiliate;

  @override
  State<KenickNavigationDrawer> createState() => _KenickNavigationDrawerState();
}

class _KenickNavigationDrawerState extends State<KenickNavigationDrawer> {
  bool _isAccountExpanded = true;

  void _navigateToRoute(String route) {
    Navigator.of(context).pop();
    context.push(route);
  }

  Future<void> _switchToClientMode() async {
    Navigator.of(context).pop();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await ProfileRepository().getPassengerProfile(user.id);
      if (profile == null) {
        if (mounted) context.push('/passenger-profile-setup');
      } else {
        if (mounted) context.go('/passenger-home');
      }
    } catch (_) {
      if (mounted) context.push('/passenger-profile-setup');
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final secondaryCurved = CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.25, 0.0),
              ).animate(secondaryCurved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF141416) : const Color(0xFFF9F8F6);
    final textPrimary = isDark ? Colors.white : const Color(0xFF18181B);
    final textMuted = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final dividerColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Material(
      color: bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Welcome, Kelvin + Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Welcome, ${widget.userName}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        color: textPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Scrollable Menu Content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (!widget.isDriver) ...[
                      // Primary Link: Newsfeed
                      _buildPrimaryItem(
                        title: 'Newsfeed',
                        textColor: textPrimary,
                        onTap: () => _navigateTo(const NewsfeedScreen()),
                      ),

                      const SizedBox(height: 20),

                      // Primary Link: Offers
                      _buildPrimaryItem(
                        title: 'Offers',
                        textColor: textPrimary,
                        onTap: () => _navigateTo(const OffersRewardsScreen()),
                      ),

                      const SizedBox(height: 20),

                      // Accordion Header: Account
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAccountExpanded = !_isAccountExpanded;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Icon(
                                _isAccountExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 26,
                                color: textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Account Sub-Items (Expanded)
                      if (_isAccountExpanded) ...[
                        const SizedBox(height: 12),
                        _buildDivider(dividerColor),
                        _buildSubItem(
                          title: 'Personal information',
                          icon: CupertinoIcons.person_crop_circle,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateTo(const PassengerProfileScreen()),
                        ),
                        _buildSubItem(
                          title: 'Frequent addresses',
                          icon: Icons.add_location_alt_outlined,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateTo(const SavedPlacesScreen()),
                        ),
                        _buildSubItem(
                          title: 'Payment and billing',
                          icon: Icons.credit_card_outlined,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateTo(const PaymentMethodScreen()),
                        ),
                        _buildSubItem(
                          title: 'Notifications',
                          icon: CupertinoIcons.bell,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateTo(const NotificationsScreen()),
                        ),
                        _buildSubItem(
                          title: 'Legal information',
                          icon: Icons.account_balance_outlined,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateTo(const LegalInformationScreen()),
                        ),
                      ],
                    ] else ...[
                      // Driver / Chauffeur Mode
                      _buildPrimaryItem(
                        title: widget.isAffiliate ? 'Fleet Dispatch' : 'Assignments Radar',
                        textColor: textPrimary,
                        onTap: () => Navigator.of(context).pop(),
                      ),

                      const SizedBox(height: 20),

                      _buildPrimaryItem(
                        title: 'Ride History',
                        textColor: textPrimary,
                        onTap: () => _navigateToRoute('/driver-ride-history'),
                      ),

                      const SizedBox(height: 20),

                      _buildPrimaryItem(
                        title: 'Performance & Ratings',
                        textColor: textPrimary,
                        onTap: () => _navigateToRoute('/driver-performance'),
                      ),

                      const SizedBox(height: 20),

                      // Accordion Header: Chauffeur / Fleet Account
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAccountExpanded = !_isAccountExpanded;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.isAffiliate ? 'Fleet Account' : 'Chauffeur Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Icon(
                                _isAccountExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 26,
                                color: textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Driver Sub-Items
                      if (_isAccountExpanded) ...[
                        const SizedBox(height: 12),
                        _buildDivider(dividerColor),
                        _buildSubItem(
                          title: 'Personal profile',
                          icon: CupertinoIcons.person_crop_circle,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateToRoute('/driver-profile'),
                        ),
                        _buildSubItem(
                          title: widget.isAffiliate ? 'Fleet vehicles' : 'Vehicle management',
                          icon: Icons.directions_car_outlined,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateToRoute('/vehicle-management'),
                        ),
                        _buildSubItem(
                          title: widget.isAffiliate ? 'Company documents' : 'Verification documents',
                          icon: Icons.verified_user_outlined,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateToRoute('/driver-id-documents'),
                        ),
                        _buildSubItem(
                          title: widget.isAffiliate ? 'Company payouts' : 'Earnings & wallet',
                          icon: Icons.account_balance_wallet_outlined,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateToRoute('/account'),
                        ),
                        _buildSubItem(
                          title: 'Support / Concierge',
                          icon: Icons.help_outline_rounded,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateToRoute('/support'),
                        ),
                        _buildSubItem(
                          title: 'Settings',
                          icon: Icons.settings_outlined,
                          textColor: textPrimary,
                          dividerColor: dividerColor,
                          onTap: () => _navigateToRoute('/settings'),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Signature Gold Pill CTA: Switch to Client mode
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _switchToClientMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: const Color(0xFF111827),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: 18,
                                color: Color(0xFF111827),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Switch to Client mode',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),

              // Bottom Section: Version, Divider & Log out
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kenick VIP 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDivider(dividerColor),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().signOut();
                      if (context.mounted) {
                        context.go('/sign-in');
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: textPrimary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Log out',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryItem({
    required String title,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSubItem({
    required String title,
    required IconData icon,
    required Color textColor,
    required Color dividerColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
                Icon(
                  icon,
                  size: 22,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
        _buildDivider(dividerColor),
      ],
    );
  }

  Widget _buildDivider(Color dividerColor) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: dividerColor,
    );
  }
}
