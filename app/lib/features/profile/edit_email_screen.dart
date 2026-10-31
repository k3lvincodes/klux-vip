import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email address update sub-page.
/// Opened from PassengerProfileScreen → "Email" row.
///
/// Follows the reference design adapted to Kenick VIP styling:
///   – GoogleFonts.poppins throughout
///   – Restrained boldness: FontWeight.w500 / w600 (rules.json)
///   – Primary color: AppColors.primary (#EAB308)
///   – Responsive dark/light theme support
class EditEmailScreen extends StatefulWidget {
  const EditEmailScreen({
    super.key,
    this.initialEmail,
  });

  final String? initialEmail;

  @override
  State<EditEmailScreen> createState() => _EditEmailScreenState();
}

class _EditEmailScreenState extends State<EditEmailScreen> {
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleContinue() async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();

    final newEmail = _emailController.text.trim();

    if (newEmail.isEmpty) {
      _showMessage('Please enter an email address.');
      return;
    }

    if (!_isValidEmail(newEmail)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (newEmail.toLowerCase() == (widget.initialEmail ?? '').toLowerCase()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (mounted) {
        _showMessage(
          'Confirmation sent! Please check your inbox to verify your new email address.',
          isSuccess: true,
        );

        Navigator.of(context).pop({'email': newEmail});
      }
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage('Failed to update email. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : AppColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          children: [
            // ── Top Header Bar ──────────────────────────────────────────────
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
                        size: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Email address',
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

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Text(
                      'Email address',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Informational note
                    Text(
                      "Changing your email address will log you out, and you'll need to log in again.",
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Email input field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: AppColors.primary,
                      autocorrect: false,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // "Continue" action button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
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
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF111827),
                                ),
                              )
                            : Text(
                                'Continue',
                                style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Bottom instruction notice
                    Text(
                      'Please verify your new email address by checking your inbox for a confirmation message.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                        height: 1.45,
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

