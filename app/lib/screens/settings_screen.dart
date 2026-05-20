import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/theme_provider.dart';
import 'package:kenick_vip/services/device_biometrics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kenick_vip/utils/custom_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = false;
  bool _faceIdEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check actual notification permission status
    final status = await Permission.notification.status;
    
    setState(() {
      _pushEnabled = status.isGranted;
      _faceIdEnabled = prefs.getBool('face_id_enabled') ?? false;
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _pushEnabled = true);
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          CustomToast.showError(context, 'Please enable notifications in system settings');
          openAppSettings();
        }
      } else {
        setState(() => _pushEnabled = false);
      }
    } else {
      // We can't revoke permissions programmatically, so we just show a message or save preference
      if (mounted) {
        CustomToast.showSuccess(context, 'Please disable notifications in system settings');
        openAppSettings();
      }
    }
  }

  Future<void> _toggleFaceId(bool value) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (value) {
      try {
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        
        if (!canCheckBiometrics || !isDeviceSupported) {
          if (mounted) CustomToast.showError(context, 'Biometrics not supported on this device');
          return;
        }

        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable Face ID / Biometrics',
          biometricOnly: true,
        );

        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('face_id_enabled', true);
          if (user != null) {
            await DeviceBiometricsService.registerDevice(user.id);
          }
          setState(() => _faceIdEnabled = true);
          if (mounted) {
            CustomToast.showSuccess(context, 'Biometrics enabled. Use fingerprint or face to log in.');
          }
        }
      } catch (e) {
        debugPrint('Biometric Error: $e');
        if (mounted) CustomToast.showError(context, 'Failed: $e');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('face_id_enabled', false);
      if (user != null) {
        await DeviceBiometricsService.unregisterDevice(user.id);
      }
      setState(() => _faceIdEnabled = false);
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) context.go('/sign-in');
    }
  }

  void _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Text('This action is irreversible. All your data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Call the RPC function to delete account and log to deleted_accounts table
        await Supabase.instance.client.rpc('delete_my_account');
        if (mounted) {
          await context.read<AuthProvider>().signOut();
        }
        if (mounted) {
          context.go('/onboarding');
        }
      } catch (e) {
        if (mounted) CustomToast.showError(context, 'Failed to delete account. Please contact support.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: TextStyle(color: isDark ? AppColors.white : AppColors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            _buildSectionHeader('Preferences', isDark),
            _buildThemeSelector(isDark),
            _buildSwitchTile(
              title: 'Push Notifications',
              icon: Icons.notifications_outlined,
              value: _pushEnabled,
              onChanged: _togglePushNotifications,
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Security', isDark),
            _buildSwitchTile(
              title: 'Face ID / Touch ID',
              icon: Icons.fingerprint,
              value: _faceIdEnabled,
              onChanged: _toggleFaceId,
              isDark: isDark,
            ),
            _buildListTile(
              title: 'Change Password',
              icon: Icons.lock_outline,
              isDark: isDark,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
                    title: Text('Change Password', style: TextStyle(color: isDark ? AppColors.white : AppColors.black)),
                    content: Text('Are you sure you want to change your password? An OTP will be sent to your email.', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Continue', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final email = context.read<AuthProvider>().currentUser?.email;
                  if (email != null) {
                    context.push('/otp?email=$email&isPasswordReset=true');
                    context.read<AuthProvider>().sendPasswordResetOtp(email);
                    CustomToast.showSuccess(context, 'Password reset OTP sent');
                  }
                }
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Support & Legal', isDark),
            _buildListTile(
              title: 'Help Center',
              icon: Icons.help_outline,
              isDark: isDark,
              onTap: () => context.push('/support'),
            ),
            _buildListTile(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              isDark: isDark,
              onTap: () {},
            ),
            _buildListTile(
              title: 'Terms of Service',
              icon: Icons.description_outlined,
              isDark: isDark,
              onTap: () {},
            ),

            const SizedBox(height: 32),
            _buildActionTile(
              title: 'Log Out',
              icon: Icons.logout,
              color: isDark ? Colors.grey.shade400 : Colors.black87,
              isDark: isDark,
              onTap: _handleLogout,
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              title: 'Delete Account',
              icon: Icons.delete_outline,
              color: Colors.red,
              isDark: isDark,
              onTap: _handleDeleteAccount,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Kenick v1.0.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: isDark ? AppColors.white : AppColors.black),
            title: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.white,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  themeProvider.setThemeMode(newValue);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile({required String title, required IconData icon, required bool isDark, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDark ? AppColors.white : AppColors.black),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required IconData icon, required bool value, required ValueChanged<bool> onChanged, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        secondary: Icon(icon, color: isDark ? AppColors.white : AppColors.black),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({required String title, required IconData icon, required Color color, required bool isDark, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
