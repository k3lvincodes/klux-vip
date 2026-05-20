import 'package:supabase_flutter/supabase_flutter.dart';

class SupportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> createTicket({
    required String userId,
    String? rideId,
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'ride_id': rideId,
            'category': category,
            'subject': subject,
            'description': description,
            'status': 'open',
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create support ticket: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserTickets(String userId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  Future<Map<String, dynamic>?> getTicket(String ticketId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('id', ticketId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch ticket: $e');
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({'status': status})
          .eq('id', ticketId);
    } catch (e) {
      throw Exception('Failed to update ticket: $e');
    }
  }
}
