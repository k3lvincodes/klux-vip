import 'package:kenick_vip/models/support_ticket.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketMessage {
  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final DateTime createdAt;
}

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
            'ride_id': ?rideId,
            'category': category,
            'subject': subject,
            'description': description,
            'status': 'open',
          })
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  Future<List<SupportTicket>> getUserTickets(String userId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => SupportTicket.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('id', ticketId)
          .maybeSingle();
      if (response == null) return null;
      return SupportTicket.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch ticket: $e');
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _supabase.from('support_tickets').update({'status': status}).eq('id', ticketId);
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  Future<List<TicketMessage>> getMessages(String ticketId) async {
    try {
      final response = await _supabase
          .from('ticket_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
      return (response as List).map((e) => TicketMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String message,
  }) async {
    try {
      await _supabase.from('ticket_messages').insert({
        'ticket_id': ticketId,
        'sender_id': senderId,
        'message': message,
      });
      await _supabase
          .from('support_tickets')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', ticketId);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<TicketMessage>> watchMessages(String ticketId) {
    return _supabase
        .from('ticket_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true)
        .map((events) => events.map((e) => TicketMessage.fromJson(e)).toList());
  }
}
