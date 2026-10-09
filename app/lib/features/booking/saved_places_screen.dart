import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/features/booking/edit_addresses_screen.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  bool _isLoading = true;
  String? _homeAddress;
  String? _workAddress;
  String? _otherName;
  String? _otherAddress;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    // 1. Instant cache load
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_frequent_addresses');
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        setState(() {
          _homeAddress = (map['home'] as String?)?.trim().isNotEmpty == true ? map['home'] : null;
          _workAddress = (map['work'] as String?)?.trim().isNotEmpty == true ? map['work'] : null;
          _otherName = (map['other_name'] as String?)?.trim().isNotEmpty == true ? map['other_name'] : null;
          _otherAddress = (map['other_address'] as String?)?.trim().isNotEmpty == true ? map['other_address'] : null;
        });
      } catch (_) {}
    }

    // 2. Remote database fetch
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('saved_places')
            .select()
            .eq('user_id', user.id);

        final places = List<Map<String, dynamic>>.from(response);
        String? home;
        String? work;
        String? otherName;
        String? otherAddr;

        for (final p in places) {
          final name = (p['name'] as String? ?? '').trim();
          final addr = (p['address'] as String? ?? '').trim();

          if (name.toLowerCase() == 'home') {
            home = addr.isNotEmpty ? addr : null;
          } else if (name.toLowerCase() == 'work') {
            work = addr.isNotEmpty ? addr : null;
          } else {
            otherName = name.isNotEmpty ? name : null;
            otherAddr = addr.isNotEmpty ? addr : null;
          }
        }

        if (mounted) {
          setState(() {
            _homeAddress = home;
            _workAddress = work;
            _otherName = otherName;
            _otherAddress = otherAddr;
            _isLoading = false;
          });
        }
        return;
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditAddresses() async {
    final updated = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => const EditAddressesScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
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
    if (updated == true && mounted) {
      _loadPlaces();
    }
  }

  Widget _buildAddressItem({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String? address,
    required ColorScheme cs,
    required bool isDark,
  }) {
    final isSet = address != null && address.trim().isNotEmpty;

    return InkWell(
      onTap: _openEditAddresses,
      splashColor: Colors.transparent,
      highlightColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: icon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isSet ? address : 'Not set',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isSet
                          ? cs.onSurfaceVariant
                          : cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    'Frequent addresses',
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

            // Content List
            Expanded(
              child: _isLoading && _homeAddress == null && _workAddress == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      children: [
                        // Home
                        _buildAddressItem(
                          context: context,
                          icon: FaIcon(
                            FontAwesomeIcons.house,
                            size: 20,
                            color: cs.onSurface,
                          ),
                          title: 'Home',
                          address: _homeAddress,
                          cs: cs,
                          isDark: isDark,
                        ),

                        // Work
                        _buildAddressItem(
                          context: context,
                          icon: Icon(
                            Icons.business_center_outlined,
                            size: 23,
                            color: cs.onSurface,
                          ),
                          title: 'Work',
                          address: _workAddress,
                          cs: cs,
                          isDark: isDark,
                        ),

                        // Other
                        _buildAddressItem(
                          context: context,
                          icon: Icon(
                            Icons.star_border_rounded,
                            size: 24,
                            color: cs.onSurface,
                          ),
                          title: _otherName ?? 'Other',
                          address: _otherAddress,
                          cs: cs,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 8),

                        // Divider
                        Divider(
                          height: 32,
                          thickness: 0.8,
                          color: cs.outlineVariant.withValues(alpha: 0.7),
                        ),

                        const SizedBox(height: 8),

                        // Edit addresses
                        InkWell(
                          onTap: _openEditAddresses,
                          splashColor: Colors.transparent,
                          highlightColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 24,
                                  color: cs.onSurface,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    'Edit addresses',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 24,
                                  color: cs.onSurface,
                                ),
                              ],
                            ),
                          ),
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
