import 'package:kenick_vip/models/driver_document.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<DriverDocument>> getDriverDocuments(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_documents')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => DriverDocument.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }

  Future<DriverDocument?> getDocumentByType(String driverId, String type) async {
    try {
      final response = await _supabase
          .from('driver_documents')
          .select()
          .eq('driver_id', driverId)
          .eq('type', type)
          .maybeSingle();
      if (response == null) return null;
      return DriverDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get document by type: $e');
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

      final Map<String, dynamic> payload = {
        'driver_id': driverId,
        'type': type,
        'file_url': fileUrl,
        'status': 'pending',
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      };

      if (existingDoc != null) {
        await _supabase.from('driver_documents').update(payload).eq('id', existingDoc.id);
        return existingDoc.id;
      } else {
        final response = await _supabase.from('driver_documents').insert(payload).select().single();
        return response['id'] as String;
      }
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<bool> checkDocumentsApproved(String driverId) async {
    try {
      final result = await _supabase.rpc('driver_documents_approved', params: {'p_driver_id': driverId});
      return result == true;
    } catch (e) {
      throw Exception('Failed to check document status: $e');
    }
  }

  Future<List<String>> getMissingDocuments(String driverId) async {
    try {
      final docs = await getDriverDocuments(driverId);
      final approvedTypes = docs
          .where((d) => d.status == 'approved')
          .map((d) => d.type)
          .toSet();
      const required = ['driver_license', 'insurance', 'registration'];
      return required.where((t) => !approvedTypes.contains(t)).toList();
    } catch (e) {
      throw Exception('Failed to get missing documents: $e');
    }
  }
}
