import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/models/user_profile.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  bool _isLoading = true;
  UserProfile? _profile;
  String _displayName = 'Kelvin Feh';
  String _displayPhone = '+2349132110654';
  String _displayEmail = 'fehkelvink@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await ProfileRepository().getPassengerProfile(user.id);
        if (mounted) {
          setState(() {
            _profile = profile;

            // Compute Name
            final first = profile?.firstName?.trim() ??
                (user.userMetadata?['first_name'] as String?)?.trim() ??
                (user.userMetadata?['name'] as String?)?.trim();
            final last = profile?.lastName?.trim() ??
                (user.userMetadata?['last_name'] as String?)?.trim();

            if (first != null && first.isNotEmpty) {
              final fullName = last != null && last.isNotEmpty ? '$first $last' : first;
              _displayName = fullName.replaceAll(RegExp(r'^(mr\.|mrs\.|ms\.)\s*', caseSensitive: false), '').trim();
            }

            // Compute Phone
            final phone = profile?.phoneNumber?.trim() ??
                user.phone?.trim() ??
                (user.userMetadata?['phone_number'] as String?)?.trim() ??
                (user.userMetadata?['phone'] as String?)?.trim();
            if (phone != null && phone.isNotEmpty) {
              _displayPhone = phone;
            }

            // Compute Email
            final email = profile?.email.trim() ?? user.email?.trim();
            if (email != null && email.isNotEmpty) {
              _displayEmail = email;
            }

            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showEditContactModal() {
    final firstController = TextEditingController(
      text: _profile?.firstName ?? 'Kelvin',
    );
    final lastController = TextEditingController(
      text: _profile?.lastName ?? 'Feh',
    );
    final phoneController = TextEditingController(
      text: _displayPhone,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Contact Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: firstController,
                cursorColor: AppColors.primary,
                style: GoogleFonts.poppins(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: GoogleFonts.poppins(color: cs.onSurfaceVariant),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: lastController,
                cursorColor: AppColors.primary,
                style: GoogleFonts.poppins(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: GoogleFonts.poppins(color: cs.onSurfaceVariant),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                cursorColor: AppColors.primary,
                style: GoogleFonts.poppins(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: GoogleFonts.poppins(color: cs.onSurfaceVariant),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    final newFirst = firstController.text.trim();
                    final newLast = lastController.text.trim();
                    final newPhone = phoneController.text.trim();

                    if (user != null) {
                      try {
                        await ProfileRepository().createOrUpdatePassengerProfile(user.id, {
                          'first_name': newFirst,
                          'last_name': newLast,
                          'phone_number': newPhone,
                        });
                      } catch (_) {}
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (mounted) {
                      setState(() {
                        _displayName = '$newFirst $newLast'.trim();
                        _displayPhone = newPhone;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Save Details',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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
  }

  void _showEditEmailModal() {
    final emailController = TextEditingController(text: _displayEmail);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Email Address',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: AppColors.primary,
                style: GoogleFonts.poppins(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(color: cs.onSurfaceVariant),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final newEmail = emailController.text.trim();
                    if (newEmail.isNotEmpty) {
                      try {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(email: newEmail),
                        );
                      } catch (_) {}
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        setState(() => _displayEmail = newEmail);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Email updated. Please check your inbox for confirmation.',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: AppColors.darkSurface,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Update Email',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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
  }

  void _showDeleteAccountConfirmation() {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your Kenick VIP account? All your ride histories, saved addresses, and profile data will be permanently removed.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  context.go('/sign-in');
                }
              } catch (_) {}
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
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
            // Top Header matching design
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

            // Content List
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
                        // 1. Contact details
                        InkWell(
                          onTap: _showEditContactModal,
                          splashColor: Colors.transparent,
                          highlightColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.user,
                                    size: 19,
                                    color: cs.onSurface,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Contact details',
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
                              Padding(
                                padding: const EdgeInsets.only(left: 40.0, top: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _displayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Mobile',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _displayPhone,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Divider
                        Divider(
                          height: 32,
                          thickness: 0.8,
                          color: cs.outlineVariant.withValues(alpha: 0.7),
                        ),

                        const SizedBox(height: 10),

                        // 2. Email
                        InkWell(
                          onTap: _showEditEmailModal,
                          splashColor: Colors.transparent,
                          highlightColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.mail_outline_rounded,
                                    size: 23,
                                    color: cs.onSurface,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Email',
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
                              Padding(
                                padding: const EdgeInsets.only(left: 40.0, top: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _displayEmail,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // Bottom Delete account button
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
              child: Center(
                child: TextButton(
                  onPressed: _showDeleteAccountConfirmation,
                  style: TextButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                    foregroundColor: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  child: Text(
                    'Delete my account',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.75),
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
