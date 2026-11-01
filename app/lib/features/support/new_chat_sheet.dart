import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/repositories/support_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a luxury bottom sheet to initiate a chat / inquiry with the Kenick VIP Care Team.
/// Note: Complies strictly with rules.json: no manual container drag handles are added
/// because showDragHandle: true is already enabled by the app-level theme.
Future<void> showNewChatSheet(
  BuildContext context, {
  String? initialSubject,
  VoidCallback? onTicketCreated,
}) async {
  HapticFeedback.lightImpact();
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    CustomToast.showError(context, 'Please sign in to contact support');
    return;
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cs = Theme.of(context).colorScheme;
  final subjectCtrl = TextEditingController(text: initialSubject ?? '');
  final messageCtrl = TextEditingController();
  final supportRepo = SupportRepository();
  bool isSubmitting = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Care Team',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our 24/7 concierge will reply within minutes.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: subjectCtrl,
                  style: GoogleFonts.poppins(fontSize: 14.5),
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: messageCtrl,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 14.5),
                  decoration: InputDecoration(
                    labelText: 'How can we help you?',
                    alignLabelWithHint: true,
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final subject = subjectCtrl.text.trim();
                            final message = messageCtrl.text.trim();
                            if (subject.isEmpty || message.isEmpty) {
                              CustomToast.showError(
                                ctx,
                                'Please enter both subject and message',
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              final ticketId = await supportRepo.createTicket(
                                userId: user.id,
                                category: 'ride_issue',
                                subject: subject,
                                description: message,
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              onTicketCreated?.call();
                              if (context.mounted) {
                                context.push(
                                  '/support/ticket/$ticketId',
                                  extra: {
                                    'subject': subject,
                                    'status': 'open',
                                  },
                                );
                              }
                            } catch (_) {
                              setModalState(() => isSubmitting = false);
                              if (ctx.mounted) {
                                CustomToast.showError(
                                  ctx,
                                  'Could not send message. Please try again.',
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isSubmitting ? 'Connecting...' : 'Start Conversation',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
