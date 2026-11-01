import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';

/// "Pickup notes" bottom sheet modal matching reference design (Image 2):
///   - Title "Pickup notes" with close 'X' button
///   - Description text
///   - "Notes" input: "Additional details (optional)" + helper text
///   - "Reference code/cost center (optional)" input: "e.g. AB123456" + helper text
///   - Bottom CTA button: "Save notes"
///
/// Strictly complies with rules.json:
///   - GoogleFonts.poppins typography
///   - Restrained boldness (w500 / w600)
///   - Kenick primary gold (#EAB308 / AppColors.primary)
///   - Exactly 1 drag handle (handled by app theme, no manual container drag handle)
class PickupNotesSheet extends StatefulWidget {
  const PickupNotesSheet({
    super.key,
    this.initialNotes,
    this.initialReferenceCode,
  });

  final String? initialNotes;
  final String? initialReferenceCode;

  static Future<Map<String, String>?> show(
    BuildContext context, {
    String? initialNotes,
    String? initialReferenceCode,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: PickupNotesSheet(
          initialNotes: initialNotes,
          initialReferenceCode: initialReferenceCode,
        ),
      ),
    );
  }

  @override
  State<PickupNotesSheet> createState() => _PickupNotesSheetState();
}

class _PickupNotesSheetState extends State<PickupNotesSheet> {
  late final TextEditingController _notesCtrl;
  late final TextEditingController _refCtrl;

  final FocusNode _notesFocus = FocusNode();
  final FocusNode _refFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.initialNotes ?? '');
    _refCtrl = TextEditingController(text: widget.initialReferenceCode ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _refCtrl.dispose();
    _notesFocus.dispose();
    _refFocus.dispose();
    super.dispose();
  }

  void _onSave() {
    Navigator.of(context).pop({
      'notes': _notesCtrl.text.trim(),
      'reference_code': _refCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title + 'X' close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pickup notes',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Provide additional information to customize your pickup and ensure a smooth experience.',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            // Field 1: Notes
            Text(
              'Notes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _notesCtrl,
              focusNode: _notesFocus,
              cursorColor: AppColors.primary,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Additional details (optional)',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: dividerColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 1.8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Additional wait time or distance requests may incur additional charges. Please do not include confidential information.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 24),

            // Field 2: Reference code / cost center
            Text(
              'Reference code/cost center (optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _refCtrl,
              focusNode: _refFocus,
              cursorColor: AppColors.primary,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. AB123456',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: dividerColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 1.8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This reference will appear on your invoice',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 28),

            // Bottom CTA: Save notes
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save notes',
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
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

