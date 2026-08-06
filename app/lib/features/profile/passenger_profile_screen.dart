import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/user_profile.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  bool _isLoading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await ProfileRepository().getPassengerProfile(user.id);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String firstName = _profile?.firstName ?? 'Client';
    final String lastName = _profile?.lastName ?? '';
    final String? imageUrl = _profile?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? Icon(Icons.person, size: 50, color: cs.onSurfaceVariant)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '$firstName $lastName'.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit Profile Details'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final didUpdate = await context.push<bool>('/edit-profile');
                      if (didUpdate == true) {
                        setState(() => _isLoading = true);
                        _loadProfile();
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Saved Places'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/saved-places'),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Privacy Center'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/privacy-policy'),
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
