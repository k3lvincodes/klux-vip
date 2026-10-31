import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist saved guests locally so users can reuse them across bookings.
class GuestStorageService {
  static const String _key = 'kenick_saved_guests';

  static Future<List<Map<String, dynamic>>> getSavedGuests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGuest(Map<String, dynamic> guest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getSavedGuests();
      // Remove previous duplicate if matching phone or email
      list.removeWhere((g) =>
          (g['phone_number'] == guest['phone_number'] &&
              g['dial_code'] == guest['dial_code']) ||
          (guest['email'] != null &&
              guest['email'].toString().isNotEmpty &&
              g['email'] == guest['email']));
      list.insert(0, guest);
      await prefs.setString(_key, jsonEncode(list));
    } catch (_) {}
  }
}

/// "Add guest" screen matching reference designs:
///   - Top header with circular back button and "Add guest" title
///   - "Title" selector with dropdown card (Mr., Ms., Mx.)
///   - "First name" text input with underline
///   - "Last name" text input with underline
///   - "Guest email" text input with underline
///   - "Mobile number" with searchable country code dropdown card and input
///   - "Save guest for future bookings" checkbox
///   - Two informational bullet items with (i) icons
///   - Bottom CTA button: "Add guest" (greyed out when incomplete, Kenick gold when valid)
///
/// Strictly complies with rules.json:
///   - GoogleFonts.poppins typography with restrained boldness (w500 / w600)
///   - Kenick Gold (#EAB308 / AppColors.primary)
///   - "ride" nomenclature throughout
class AddGuestScreen extends StatefulWidget {
  const AddGuestScreen({
    super.key,
    this.initialTitle,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhone,
    this.initialDialCode,
  });

  final String? initialTitle;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialDialCode;

  @override
  State<AddGuestScreen> createState() => _AddGuestScreenState();
}

class _AddGuestScreenState extends State<AddGuestScreen> {
  // ── Form Controllers ────────────────────────────────────────────────────────
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _searchCountryCtrl;

  // ── Focus Nodes ─────────────────────────────────────────────────────────────
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _lastFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  // ── Dropdown / Selection State ──────────────────────────────────────────────
  String _selectedTitle = 'Mr.';
  bool _isTitleDropdownOpen = false;
  final List<String> _titles = ['Mr.', 'Ms.', 'Mx.'];

  bool _isCountryDropdownOpen = false;
  String _countrySearchQuery = '';

  late Map<String, String> _selectedCountry;

  bool _saveForFuture = true;

  // Country code registry
  static const List<Map<String, String>> _countryList = [
    {'flag': '🇺🇸', 'code': '+1', 'name': 'United States'},
    {'flag': '🇩🇪', 'code': '+49', 'name': 'Germany'},
    {'flag': '🇬🇧', 'code': '+44', 'name': 'United Kingdom'},
    {'flag': '🇨🇦', 'code': '+1', 'name': 'Canada'},
    {'flag': '🇫🇷', 'code': '+33', 'name': 'France'},
    {'flag': '🇳🇬', 'code': '+234', 'name': 'Nigeria'},
    {'flag': '🇨🇭', 'code': '+41', 'name': 'Switzerland'},
    {'flag': '🇦🇪', 'code': '+971', 'name': 'UAE'},
    {'flag': '🇸🇦', 'code': '+966', 'name': 'Saudi Arabia'},
    {'flag': '🇦🇺', 'code': '+61', 'name': 'Australia'},
    {'flag': '🇳🇱', 'code': '+31', 'name': 'Netherlands'},
    {'flag': '🇮🇹', 'code': '+39', 'name': 'Italy'},
    {'flag': '🇪🇸', 'code': '+34', 'name': 'Spain'},
    {'flag': '🇦🇹', 'code': '+43', 'name': 'Austria'},
    {'flag': '🇧🇪', 'code': '+32', 'name': 'Belgium'},
    {'flag': '🇸🇪', 'code': '+46', 'name': 'Sweden'},
    {'flag': '🇬🇭', 'code': '+233', 'name': 'Ghana'},
    {'flag': '🇰🇪', 'code': '+254', 'name': 'Kenya'},
    {'flag': '🇿🇦', 'code': '+27', 'name': 'South Africa'},
    {'flag': '🇪🇬', 'code': '+20', 'name': 'Egypt'},
    {'flag': '🇮🇳', 'code': '+91', 'name': 'India'},
    {'flag': '🇸🇬', 'code': '+65', 'name': 'Singapore'},
    {'flag': '🇶🇦', 'code': '+974', 'name': 'Qatar'},
  ];

  @override
  void initState() {
    super.initState();

    _selectedTitle = widget.initialTitle ?? 'Mr.';

    _firstNameCtrl = TextEditingController(text: widget.initialFirstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.initialLastName ?? '');
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _phoneCtrl = TextEditingController(text: widget.initialPhone ?? '');
    _searchCountryCtrl = TextEditingController();

    // Initialize country code
    _selectedCountry = _countryList.first;
    if (widget.initialDialCode != null) {
      final match = _countryList.firstWhere(
        (c) => c['code'] == widget.initialDialCode,
        orElse: () => _countryList.first,
      );
      _selectedCountry = match;
    }

    _firstNameCtrl.addListener(_onFieldChanged);
    _lastNameCtrl.addListener(_onFieldChanged);
    _emailCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _searchCountryCtrl.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    return first.isNotEmpty && last.isNotEmpty && phone.isNotEmpty;
  }

  List<Map<String, String>> get _filteredCountries {
    if (_countrySearchQuery.isEmpty) return _countryList;
    final q = _countrySearchQuery.toLowerCase();
    return _countryList.where((c) {
      return c['name']!.toLowerCase().contains(q) ||
          c['code']!.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _handleSaveGuest() async {
    if (!_isFormValid) return;

    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final dial = _selectedCountry['code'] ?? '+1';
    final phone = _phoneCtrl.text.trim();
    final flag = _selectedCountry['flag'] ?? '🇺🇸';

    final guestData = {
      'title': _selectedTitle,
      'first_name': first,
      'last_name': last,
      'email': email,
      'dial_code': dial,
      'phone_number': phone,
      'full_name': '$first $last'.trim(),
      'full_phone': '$dial $phone'.trim(),
      'flag': flag,
      'saved_for_future': _saveForFuture,
    };

    if (_saveForFuture) {
      await GuestStorageService.saveGuest(guestData);
    }

    if (mounted) {
      Navigator.of(context).pop(guestData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);
    const activeUnderlineColor = AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardColor,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.05,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Add guest',
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

            // ── Form Content ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Title selector
                    _buildTitleSection(
                      cs: cs,
                      isDark: isDark,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      activeColor: activeUnderlineColor,
                    ),

                    const SizedBox(height: 18),

                    // 2. First name
                    _buildUnderlineTextField(
                      label: 'First name',
                      controller: _firstNameCtrl,
                      focusNode: _firstFocus,
                      cs: cs,
                      dividerColor: dividerColor,
                      activeColor: activeUnderlineColor,
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 18),

                    // 3. Last name
                    _buildUnderlineTextField(
                      label: 'Last name',
                      controller: _lastNameCtrl,
                      focusNode: _lastFocus,
                      cs: cs,
                      dividerColor: dividerColor,
                      activeColor: activeUnderlineColor,
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 18),

                    // 4. Guest email
                    _buildUnderlineTextField(
                      label: 'Guest email',
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      cs: cs,
                      dividerColor: dividerColor,
                      activeColor: activeUnderlineColor,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 18),

                    // 5. Mobile number (with country code dropdown)
                    _buildPhoneSection(
                      cs: cs,
                      isDark: isDark,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      activeColor: activeUnderlineColor,
                    ),

                    const SizedBox(height: 24),

                    // 6. Save guest checkbox
                    _buildSaveGuestCheckbox(cs: cs),

                    const SizedBox(height: 20),

                    // 7. Informational notes (i)
                    _buildInfoNote(
                      cs: cs,
                      text:
                          'The guest details entered will be used to send ride updates and a booking confirmation.',
                    ),

                    const SizedBox(height: 12),

                    _buildInfoNote(
                      cs: cs,
                      text:
                          'Invoices are sent only to the booker, not the guest.',
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _handleSaveGuest : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFAFAFAF)),
                    foregroundColor: _isFormValid
                        ? const Color(0xFF111827)
                        : Colors.white,
                    disabledBackgroundColor:
                        isDark ? const Color(0xFF3F3F46) : const Color(0xFFAFAFAF),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add guest',
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
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

  // ── Section: Title Dropdown ─────────────────────────────────────────────────
  Widget _buildTitleSection({
    required ColorScheme cs,
    required bool isDark,
    required Color cardColor,
    required Color dividerColor,
    required Color activeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isTitleDropdownOpen = !_isTitleDropdownOpen;
              if (_isTitleDropdownOpen) {
                _isCountryDropdownOpen = false;
              }
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      _isTitleDropdownOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurface,
                      size: 22,
                    ),
                  ],
                ),
              ),
              Container(
                height: _isTitleDropdownOpen ? 2 : 1,
                color: _isTitleDropdownOpen ? activeColor : dividerColor,
              ),
            ],
          ),
        ),

        // Inline Title Dropdown Card
        if (_isTitleDropdownOpen) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _titles.map((title) {
                final isSelected = _selectedTitle == title;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTitle = title;
                      _isTitleDropdownOpen = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ── Section: Underline Text Input ───────────────────────────────────────────
  Widget _buildUnderlineTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ColorScheme cs,
    required Color dividerColor,
    required Color activeColor,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final isFocused = focusNode.hasFocus;

    return Focus(
      focusNode: focusNode,
      onFocusChange: (_) => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  cursorColor: AppColors.primary,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty && isFocused)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    setState(() {});
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          Container(
            height: isFocused ? 2 : 1,
            color: isFocused ? activeColor : dividerColor,
          ),
        ],
      ),
    );
  }

  // ── Section: Phone Input with Country Dropdown ──────────────────────────────
  Widget _buildPhoneSection({
    required ColorScheme cs,
    required bool isDark,
    required Color cardColor,
    required Color dividerColor,
    required Color activeColor,
  }) {
    final isFocused = _phoneFocus.hasFocus;

    return Focus(
      focusNode: _phoneFocus,
      onFocusChange: (_) => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile number',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Country picker trigger
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCountryDropdownOpen = !_isCountryDropdownOpen;
                    if (_isCountryDropdownOpen) {
                      _isTitleDropdownOpen = false;
                    }
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry['flag'] ?? '🇺🇸',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isCountryDropdownOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry['code'] ?? '+1',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),

              // Phone number input
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  cursorColor: AppColors.primary,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                  ],
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: 'Mobile number',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              if (_phoneCtrl.text.isNotEmpty && isFocused)
                GestureDetector(
                  onTap: () {
                    _phoneCtrl.clear();
                    setState(() {});
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          Container(
            height: isFocused || _isCountryDropdownOpen ? 2 : 1,
            color: isFocused || _isCountryDropdownOpen ? activeColor : dividerColor,
          ),

          // Inline Country Selection Dropdown Card
          if (_isCountryDropdownOpen) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar inside country card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF26262B)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCountryCtrl,
                              cursorColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() => _countrySearchQuery = val);
                              },
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Search',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                          if (_searchCountryCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCountryCtrl.clear();
                                setState(() => _countrySearchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Country list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filteredCountries.length,
                      itemBuilder: (ctx, idx) {
                        final country = _filteredCountries[idx];
                        final isSelected =
                            country['code'] == _selectedCountry['code'] &&
                                country['name'] == _selectedCountry['name'];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCountry = country;
                              _isCountryDropdownOpen = false;
                              _countrySearchQuery = '';
                              _searchCountryCtrl.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(
                                      alpha: isDark ? 0.18 : 0.12,
                                    )
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  country['flag'] ?? '',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    country['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  country['code'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: Save Guest Checkbox ────────────────────────────────────────────
  Widget _buildSaveGuestCheckbox({required ColorScheme cs}) {
    return GestureDetector(
      onTap: () => setState(() => _saveForFuture = !_saveForFuture),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _saveForFuture,
              onChanged: (val) => setState(() => _saveForFuture = val ?? false),
              activeColor: AppColors.primary,
              checkColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Save guest for future bookings',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Info Note (i) ──────────────────────────────────────────────────
  Widget _buildInfoNote({
    required ColorScheme cs,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
