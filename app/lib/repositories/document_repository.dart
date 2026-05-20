import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getDriverDocuments(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_documents')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<Map<String, dynamic>?> getDocumentByType(
    String driverId,
    String type,
  ) async {
    try {
      final response = await _supabase
          .from('driver_documents')
          .select()
          .eq('driver_id', driverId)
          .eq('type', type)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch document: $e');
    }
  }

  Future<String> uploadDocument({
    required String driverId,
    required String type,
    required String fileUrl,
    DateTime? expiresAt,
  }) async {
    try {
      final existingDoc = await getDocumentByType(driverId, type);

      if (existingDoc != null) {
        await _supabase
            .from('driver_documents')
            .update({
              'file_url': fileUrl,
              'status': 'pending',
              'expires_at': expiresAt?.toIso8601String(),
            })
            .eq('id', existingDoc['id']);

        return existingDoc['id'] as String;
      }

      final response = await _supabase
          .from('driver_documents')
          .insert({
            'driver_id': driverId,
            'type': type,
            'file_url': fileUrl,
            'status': 'pending',
            'expires_at': expiresAt?.toIso8601String(),
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<bool> checkDocumentsApproved(String driverId) async {
    try {
      final response = await _supabase.rpc(
        'driver_documents_approved',
        params: {'driver_uuid': driverId},
      );
      return response as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getMissingDocuments(String driverId) async {
    final requiredDocs = ['driver_license', 'insurance', 'registration'];
    final uploaded = await getDriverDocuments(driverId);
    final uploadedTypes = uploaded
        .where((doc) => doc['status'] == 'approved')
        .map((doc) => doc['type'] as String)
        .toSet();

    return requiredDocs.where((doc) => !uploadedTypes.contains(doc)).toList();
  }
}
