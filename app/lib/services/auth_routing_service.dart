import 'package:kenick_vip/repositories/document_repository.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRoutingService {
  final ProfileRepository _profileRepo = ProfileRepository();
  final DocumentRepository _documentRepo = DocumentRepository();

  Future<String> determineRouteForUser(User user) async {
    final role = user.userMetadata?['role'] as String?;

    if (role == null) {
      return '/role-selection';
    }

    if (role == 'Chauffeur' || role == 'Affiliate') {
      final results = await Future.wait([
        _profileRepo.getDriverProfile(user.id),
        _documentRepo.getDocumentByType(user.id, 'driver_license'),
      ]);

      final profile = results[0];
      final idDoc = results[1];

      if (profile == null || (profile as Map)['first_name'] == null) {
        return '/driver-profile-setup';
      }

      if (idDoc == null) {
        return '/driver-id-verification';
      }

      return '/driver-home';
    }

    final profile = await _profileRepo.getPassengerProfile(user.id);
    if (profile == null || profile.firstName == null) {
      return '/passenger-profile-setup';
    }

    return '/passenger-home';
  }
}
