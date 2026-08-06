import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/theme_provider.dart';
import 'package:kenick_vip/services/device_biometrics_service.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = false;
  bool _faceIdEnabled = false;
  String _biometricLabel = 'Face ID / Touch ID';
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final status = await Permission.notification.status;
    final label = await DeviceBiometricsService.getBiometricLabel();
    setState(() {
      _pushEnabled = status.isGranted;
      _faceIdEnabled = prefs.getBool('face_id_enabled') ?? false;
      _biometricLabel = label;
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
          localizedReason: 'Authenticate to enable $_biometricLabel',
          biometricOnly: true,
        );
        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('face_id_enabled', true);
          if (user != null) await DeviceBiometricsService.registerDevice(user.id);
          setState(() => _faceIdEnabled = true);
          if (mounted) CustomToast.showSuccess(context, '$_biometricLabel enabled');
        }
      } catch (e) {
        if (mounted) CustomToast.showError(context, 'Failed: $e');
      }
    } else {
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to disable $_biometricLabel',
          biometricOnly: true,
        );
        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('face_id_enabled', false);
          if (user != null) await DeviceBiometricsService.unregisterDevice(user.id);
          setState(() => _faceIdEnabled = false);
          if (mounted) CustomToast.showSuccess(context, '$_biometricLabel disabled');
        }
      } catch (e) {
        if (mounted) CustomToast.showError(context, 'Failed to disable biometrics');
      }
    }
  }

  void _handleLogout() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout,
                    size: 28, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text('Log Out',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await context.read<AuthProvider>().signOut();
                    if (mounted) context.go('/sign-in');
                  },
                  child: const Text('Sign Out'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDeleteAccount() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, size: 28, color: cs.error),
              ),
              const SizedBox(height: 20),
              Text('Delete Account',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'This action is irreversible. All your data will be permanently deleted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _performDeleteAccount();
                  },
                  child: const Text('Delete My Account'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    try {
      await Supabase.instance.client.rpc('delete_my_account');
      if (mounted) await context.read<AuthProvider>().signOut();
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to delete account. Please contact support.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('Preferences'),
          Card(
            child: Column(
              children: [
                _buildThemeSelector(),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  title: 'Push Notifications',
                  icon: Icons.notifications_outlined,
                  value: _pushEnabled,
                  onChanged: _togglePushNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Security'),
          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: _biometricLabel,
                  icon: Icons.fingerprint,
                  value: _faceIdEnabled,
                  onChanged: _toggleFaceId,
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  title: 'Change Password',
                  icon: Icons.lock_outline,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Password'),
                        content: const Text(
                            'Are you sure you want to change your password? An OTP will be sent to your email.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Continue'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      final email =
                          context.read<AuthProvider>().currentUser?.email;
                      if (email != null) {
                        context.push('/otp?email=$email&isPasswordReset=true');
                        context
                            .read<AuthProvider>()
                            .sendPasswordResetOtp(email);
                        CustomToast.showSuccess(context, 'Password reset OTP sent');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Support & Legal'),
          Card(
            child: Column(
              children: [
                _buildListTile(
                  title: 'Help Center',
                  icon: Icons.help_outline,
                  onTap: () => context.push('/support'),
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => context.push('/privacy-policy'),
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  title: 'Terms of Service',
                  icon: Icons.description_outlined,
                  onTap: () => context.push('/terms-of-service'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: cs.errorContainer,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: cs.onSurface),
                  title: Text('Log Out',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      )),
                  onTap: _handleLogout,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: cs.error),
                  title: Text('Delete Account',
                      style: TextStyle(
                        color: cs.error,
                        fontWeight: FontWeight.w500,
                      )),
                  onTap: _handleDeleteAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Kenick v1.0.0',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text('Appearance'),
          trailing: DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (ThemeMode? newValue) {
              if (newValue != null) themeProvider.setThemeMode(newValue);
            },
          ),
        );
      },
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
