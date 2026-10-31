import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Personal information / contact-details sub-page.
/// Opened from PassengerProfileScreen → "Contact details" row.
///
/// Fields:
///   • Title salutation (Mr. / Mrs. / Ms. / Dr.)
///   • First name
///   • Last name
///   • Mobile number (with country-code selector)
///   • Billing address: Company, Street address, Postal code
///
/// Complies with rules.json:
///   – GoogleFonts.poppins throughout
///   – FontWeight.w500 / w600 (restrained boldness)
///   – AppColors.primary (#EAB308) for interactive elements
///   – No manual drag-handle containers (this is a full Scaffold, not a bottom sheet)
class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialPhone,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final String? initialPhone;

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  String _selectedTitle = 'Mr.';
  final List<String> _titles = ['Mr.', 'Mrs.', 'Ms.', 'Dr.'];

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _postalCtrl;

  String _dialCode = '+1';
  String _flagEmoji = '🇺🇸';

  final List<Map<String, String>> _countryCodes = [
    {'flag': '🇺🇸', 'code': '+1',   'name': 'United States'},
    {'flag': '🇬🇧', 'code': '+44',  'name': 'United Kingdom'},
    {'flag': '🇨🇦', 'code': '+1',   'name': 'Canada'},
    {'flag': '🇦🇺', 'code': '+61',  'name': 'Australia'},
    {'flag': '🇩🇪', 'code': '+49',  'name': 'Germany'},
    {'flag': '🇫🇷', 'code': '+33',  'name': 'France'},
    {'flag': '🇳🇬', 'code': '+234', 'name': 'Nigeria'},
    {'flag': '🇬🇭', 'code': '+233', 'name': 'Ghana'},
    {'flag': '🇰🇪', 'code': '+254', 'name': 'Kenya'},
    {'flag': '🇿🇦', 'code': '+27',  'name': 'South Africa'},
    {'flag': '🇪🇬', 'code': '+20',  'name': 'Egypt'},
    {'flag': '🇮🇳', 'code': '+91',  'name': 'India'},
    {'flag': '🇦🇪', 'code': '+971', 'name': 'UAE'},
    {'flag': '🇸🇦', 'code': '+966', 'name': 'Saudi Arabia'},
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill from phone string if it starts with a known dial code
    final rawPhone = widget.initialPhone ?? '';
    _parsePhoneIntoDialAndNumber(rawPhone);

    _firstNameCtrl = TextEditingController(text: widget.initialFirstName ?? '');
    _lastNameCtrl  = TextEditingController(text: widget.initialLastName ?? '');
    _companyCtrl   = TextEditingController();
    _streetCtrl    = TextEditingController();
    _postalCtrl    = TextEditingController();
  }

  void _parsePhoneIntoDialAndNumber(String raw) {
    // Try to detect a known dial code at the beginning
    for (final c in _countryCodes) {
      if (raw.startsWith(c['code']!)) {
        _dialCode   = c['code']!;
        _flagEmoji  = c['flag']!;
        _phoneCtrl  = TextEditingController(
          text: raw.substring(c['code']!.length).trim(),
        );
        return;
      }
    }
    _phoneCtrl = TextEditingController(text: raw);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _streetCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;
    HapticFeedback.lightImpact();

    final firstName = _firstNameCtrl.text.trim();
    final lastName  = _lastNameCtrl.text.trim();
    final phone     = '$_dialCode ${_phoneCtrl.text.trim()}';

    if (firstName.isEmpty) {
      _showError('Please enter your first name.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await ProfileRepository().createOrUpdatePassengerProfile(user.id, {
          'first_name':  firstName,
          'last_name':   lastName,
          'phone_number': phone,
        });
      }

      if (mounted) {
        // Return updated data to parent so it can refresh its display
        Navigator.of(context).pop({
          'first_name':  firstName,
          'last_name':   lastName,
          'phone_number': phone,
        });
      }
    } catch (_) {
      if (mounted) _showError('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCountryPicker(ColorScheme cs, bool isDark) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return ListView.builder(
          itemCount: _countryCodes.length,
          itemBuilder: (_, i) {
            final item = _countryCodes[i];
            final selected = item['code'] == _dialCode && item['flag'] == _flagEmoji;
            return ListTile(
              leading: Text(item['flag']!, style: const TextStyle(fontSize: 22)),
              title: Text(
                item['name']!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : cs.onSurface,
                ),
              ),
              trailing: Text(
                item['code']!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _dialCode  = item['code']!;
                  _flagEmoji = item['flag']!;
                });
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration({
    required String label,
    required ColorScheme cs,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13.5,
        color: cs.onSurfaceVariant,
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  TextStyle _inputTextStyle(ColorScheme cs) => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: cs.onSurface,
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                    'Personal information',
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

            // ── Form ────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title / Salutation dropdown
                    _SectionLabel(label: 'Title', cs: cs),
                    const SizedBox(height: 6),
                    _TitleDropdown(
                      selected: _selectedTitle,
                      options: _titles,
                      cs: cs,
                      isDark: isDark,
                      onChanged: (val) => setState(() => _selectedTitle = val),
                    ),

                    const SizedBox(height: 22),

                    // First name
                    TextField(
                      controller: _firstNameCtrl,
                      cursorColor: AppColors.primary,
                      style: _inputTextStyle(cs),
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(
                        label: 'First name',
                        cs: cs,
                        suffix: _ClearButton(controller: _firstNameCtrl),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Last name
                    TextField(
                      controller: _lastNameCtrl,
                      cursorColor: AppColors.primary,
                      style: _inputTextStyle(cs),
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(
                        label: 'Last name',
                        cs: cs,
                        suffix: _ClearButton(controller: _lastNameCtrl),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mobile number with country code picker
                    _SectionLabel(label: 'Mobile number', cs: cs),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Flag + dial code button
                        GestureDetector(
                          onTap: () => _showCountryPicker(cs, isDark),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _flagEmoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 18, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  _dialCode,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Phone number input
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            cursorColor: AppColors.primary,
                            style: _inputTextStyle(cs),
                            keyboardType: TextInputType.phone,
                            decoration: _fieldDecoration(
                              label: '',
                              cs: cs,
                              suffix: _ClearButton(controller: _phoneCtrl),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Helper text below phone
                    const SizedBox(height: 6),
                    Text(
                      'Add your mobile number to receive ride notifications.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Billing address section heading
                    Text(
                      'Billing address',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        letterSpacing: -0.1,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Company
                    TextField(
                      controller: _companyCtrl,
                      cursorColor: AppColors.primary,
                      style: _inputTextStyle(cs),
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(label: 'Company', cs: cs),
                    ),

                    const SizedBox(height: 20),

                    // Street address
                    TextField(
                      controller: _streetCtrl,
                      cursorColor: AppColors.primary,
                      style: _inputTextStyle(cs),
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          _fieldDecoration(label: 'Street address', cs: cs),
                    ),

                    const SizedBox(height: 20),

                    // Postal code
                    TextField(
                      controller: _postalCtrl,
                      cursorColor: AppColors.primary,
                      style: _inputTextStyle(cs),
                      keyboardType: TextInputType.text,
                      decoration:
                          _fieldDecoration(label: 'Postal code', cs: cs),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Save & continue CTA ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF111827),
                          ),
                        )
                      : Text(
                          'Save and continue',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
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

// ── Small helper widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.cs});
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _ClearButton extends StatefulWidget {
  const _ClearButton({required this.controller});
  final TextEditingController controller;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.text.isEmpty) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.clear_rounded, size: 18),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () {
        widget.controller.clear();
        HapticFeedback.selectionClick();
      },
    );
  }
}

class _TitleDropdown extends StatelessWidget {
  const _TitleDropdown({
    required this.selected,
    required this.options,
    required this.cs,
    required this.isDark,
    required this.onChanged,
  });

  final String selected;
  final List<String> options;
  final ColorScheme cs;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: cs.onSurfaceVariant),
          dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: cs.onSurface,
          ),
          items: options
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              HapticFeedback.selectionClick();
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}

