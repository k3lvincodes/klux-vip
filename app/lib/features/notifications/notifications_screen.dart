import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushRideStatus = false;
  bool _pushPersonalizedUpdates = true;
  bool _smsRideStatus = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushRideStatus = prefs.getBool('pref_push_ride_status') ?? false;
      _pushPersonalizedUpdates = prefs.getBool('pref_push_personalized') ?? true;
      _smsRideStatus = prefs.getBool('pref_sms_ride_status') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updatePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: cs.outlineVariant.withValues(alpha: 0.6),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      children: [
                        // Subtitle
                        Text(
                          'Choose which updates you want to receive and how.',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Section 1: Push notifications
                        Text(
                          'Push notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),

                        _buildToggleRow(
                          title: 'Ride status, rate the ride',
                          value: _pushRideStatus,
                          onChanged: (val) {
                            setState(() => _pushRideStatus = val);
                            _updatePref('pref_push_ride_status', val);
                          },
                          cs: cs,
                        ),

                        _buildToggleRow(
                          title:
                              'Personalized updates and offers, curated travel tips, feedback requests',
                          value: _pushPersonalizedUpdates,
                          onChanged: (val) {
                            setState(() => _pushPersonalizedUpdates = val);
                            _updatePref('pref_push_personalized', val);
                          },
                          cs: cs,
                        ),

                        const SizedBox(height: 28),

                        // Section 2: SMS messages
                        Text(
                          'SMS messages',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),

                        _buildToggleRow(
                          title: 'Ride status',
                          value: _smsRideStatus,
                          onChanged: (val) {
                            setState(() => _smsRideStatus = val);
                            _updatePref('pref_sms_ride_status', val);
                          },
                          cs: cs,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
