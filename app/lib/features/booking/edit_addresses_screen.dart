import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAddressesScreen extends StatefulWidget {
  const EditAddressesScreen({super.key});

  @override
  State<EditAddressesScreen> createState() => _EditAddressesScreenState();
}

class _EditAddressesScreenState extends State<EditAddressesScreen> {
  final TextEditingController _homeController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _otherNameController = TextEditingController();
  final TextEditingController _otherAddressController = TextEditingController();

  String? _homePlaceId;
  String? _workPlaceId;
  String? _otherPlaceId;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _homeController.dispose();
    _workController.dispose();
    _otherNameController.dispose();
    _otherAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_frequent_addresses');
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        _homeController.text = map['home'] ?? '';
        _workController.text = map['work'] ?? '';
        _otherNameController.text = map['other_name'] ?? '';
        _otherAddressController.text = map['other_address'] ?? '';
      } catch (_) {}
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('saved_places')
            .select()
            .eq('user_id', user.id);

        final places = List<Map<String, dynamic>>.from(response);
        for (final p in places) {
          final name = (p['name'] as String? ?? '').trim();
          final addr = (p['address'] as String? ?? '').trim();
          final id = p['id'] as String?;

          if (name.toLowerCase() == 'home') {
            _homeController.text = addr;
            _homePlaceId = id;
          } else if (name.toLowerCase() == 'work') {
            _workController.text = addr;
            _workPlaceId = id;
          } else {
            _otherNameController.text = name;
            _otherAddressController.text = addr;
            _otherPlaceId = id;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddresses() async {
    setState(() => _isSaving = true);

    final homeText = _homeController.text.trim();
    final workText = _workController.text.trim();
    final otherNameText = _otherNameController.text.trim();
    final otherAddressText = _otherAddressController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cached_frequent_addresses',
      jsonEncode({
        'home': homeText,
        'work': workText,
        'other_name': otherNameText,
        'other_address': otherAddressText,
      }),
    );

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final client = Supabase.instance.client;

      try {
        // 1. Home
        if (homeText.isNotEmpty) {
          if (_homePlaceId != null) {
            await client.from('saved_places').update({'address': homeText}).eq('id', _homePlaceId!);
          } else {
            final res = await client.from('saved_places').insert({
              'user_id': user.id,
              'name': 'Home',
              'address': homeText,
            }).select('id').single();
            _homePlaceId = res['id'] as String?;
          }
        } else if (_homePlaceId != null) {
          await client.from('saved_places').delete().eq('id', _homePlaceId!);
          _homePlaceId = null;
        }

        // 2. Work
        if (workText.isNotEmpty) {
          if (_workPlaceId != null) {
            await client.from('saved_places').update({'address': workText}).eq('id', _workPlaceId!);
          } else {
            final res = await client.from('saved_places').insert({
              'user_id': user.id,
              'name': 'Work',
              'address': workText,
            }).select('id').single();
            _workPlaceId = res['id'] as String?;
          }
        } else if (_workPlaceId != null) {
          await client.from('saved_places').delete().eq('id', _workPlaceId!);
          _workPlaceId = null;
        }

        // 3. Other
        if (otherAddressText.isNotEmpty) {
          final placeName = otherNameText.isNotEmpty ? otherNameText : 'Other';
          if (_otherPlaceId != null) {
            await client.from('saved_places').update({
              'name': placeName,
              'address': otherAddressText,
            }).eq('id', _otherPlaceId!);
          } else {
            final res = await client.from('saved_places').insert({
              'user_id': user.id,
              'name': placeName,
              'address': otherAddressText,
            }).select('id').single();
            _otherPlaceId = res['id'] as String?;
          }
        } else if (_otherPlaceId != null) {
          await client.from('saved_places').delete().eq('id', _otherPlaceId!);
          _otherPlaceId = null;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Addresses updated successfully',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.darkSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : Column(
                children: [
                  // Top Header matching design
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                          'Edit addresses',
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

                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Home
                          Text(
                            'Home',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _homeController,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w400,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Add your home address',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                              isDense: true,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Work
                          Text(
                            'Work',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _workController,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w400,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Add your work address',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                              isDense: true,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Other Section
                          Text(
                            'Other',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Location name
                          Text(
                            'Location name',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _otherNameController,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w400,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'e.g. Airport, hotel, station...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                              isDense: true,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Location address
                          Text(
                            'Location address',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _otherAddressController,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w400,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Search for the address',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.only(bottom: 12, top: 4),
                              isDense: true,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.8),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Save addresses button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAddresses,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          disabledBackgroundColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFBDBDBD),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'Save addresses',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
