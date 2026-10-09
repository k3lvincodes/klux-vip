import 'dart:convert';

import 'package:didit_sdk/sdk_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kenick_vip/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiditVerificationService {
  String get _apiKey => EnvConfig.diditApiKey;
  String get _workflowId => EnvConfig.diditVerificationWorkflowId;

  Future<String?> _createSession({
    required String workflowId,
    String? vendorData,
  }) async {
    final apiKey = _apiKey;

    if (apiKey.isEmpty) {

      return null;
    }

    try {
      final sessionResponse = await http.post(
        Uri.parse('https://verification.didit.me/v3/session/'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'workflow_id': workflowId,
          // ignore: use_null_aware_elements
          if (vendorData != null) 'vendor_data': vendorData,
        }),
      );

      if (sessionResponse.statusCode == 200 || sessionResponse.statusCode == 201) {
        final sessionData = jsonDecode(sessionResponse.body);
        final sessionToken = sessionData['session_token'] as String?;

        return sessionToken;
      } else {

        return null;
      }
    } catch (e) {

      return null;
    }
  }

  Future<VerificationResult> verifyIdentity({
    String? vendorData,
  }) async {
    final workflowId = _workflowId;
    if (workflowId.isEmpty) {
      return const VerificationFailed(
        error: VerificationError(
          type: VerificationErrorType.unknown,
          message: 'DIDIT_VERIFICATION_WORKFLOW_ID is not configured',
        ),
      );
    }

    final sessionToken = await _createSession(
      workflowId: workflowId,
      vendorData: vendorData,
    );

    if (sessionToken == null) {
      return const VerificationFailed(
        error: VerificationError(
          type: VerificationErrorType.unknown,
          message: 'Failed to create verification session. Check your Didit credentials.',
        ),
      );
    }

    return DiditSdk.startVerification(
      sessionToken,
      config: const DiditConfig(loggingEnabled: true),
    );
  }

  Future<Map<String, dynamic>?> getSessionDecision(String sessionId) async {
    final apiKey = _apiKey;
    if (apiKey.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('https://verification.didit.me/v3/session/$sessionId/decision/'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
      } catch (_) {}
    }

    // Fallback to Supabase edge function 'didit-lookup'
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'didit-lookup',
        body: {'session_id': sessionId},
      );
      if (res.status == 200 && res.data != null) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          return (data['session'] as Map<String, dynamic>?) ?? data;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Validates that the verified document is strictly a USA Driver's License.
  Map<String, dynamic> validateChauffeurDocument(Map<String, dynamic>? decisionData) {
    if (decisionData == null) {
      return {'isValid': true, 'reason': null};
    }

    final session = (decisionData['session'] as Map<String, dynamic>?) ?? decisionData;
    final idVerifList = session['id_verifications'] as List?;
    final idVerif = (idVerifList != null && idVerifList.isNotEmpty)
        ? (idVerifList.first as Map<String, dynamic>?)
        : (session['id_verification'] as Map<String, dynamic>?);

    if (idVerif != null) {
      final docType = (idVerif['document_type'] as String? ?? '').toLowerCase();
      final country = (idVerif['issuing_country'] as String? ??
              idVerif['country'] as String? ??
              '')
          .toUpperCase();
      final issuingState = (idVerif['issuing_state'] as String? ??
              idVerif['issuing_state_name'] as String? ??
              '')
          .trim();

      // Must be driver's license
      final isDriverLicense = docType.contains('driver') ||
          docType.contains('driving') ||
          docType.contains('license') ||
          docType == 'dl';

      if (!isDriverLicense && docType.isNotEmpty) {
        return {
          'isValid': false,
          'reason':
              'Only Driver\'s License is accepted for chauffeur verification. Please submit a valid USA Driver\'s License.',
        };
      }

      // Must be USA (strictly without writing the word region)
      final isUsa = country == 'USA' ||
          country == 'US' ||
          country == 'UNITED STATES' ||
          country.contains('USA') ||
          country.contains('UNITED STATES') ||
          issuingState.isNotEmpty;

      if (!isUsa && country.isNotEmpty) {
        return {
          'isValid': false,
          'reason':
              'Only USA Driver\'s License is accepted for chauffeur verification. Please submit a valid USA Driver\'s License.',
        };
      }
    }

    return {'isValid': true, 'reason': null};
  }

  /// Extracts explicit rejection or decline reason from Didit decision data
  String? extractRejectionReason(Map<String, dynamic>? decisionData) {
    if (decisionData == null) return null;
    final session = (decisionData['session'] as Map<String, dynamic>?) ?? decisionData;

    final directReason = session['rejection_reason'] as String? ??
        session['decline_reason'] as String?;
    if (directReason != null && directReason.isNotEmpty) return directReason;

    final idVerifList = session['id_verifications'] as List?;
    final idVerif = (idVerifList != null && idVerifList.isNotEmpty)
        ? (idVerifList.first as Map<String, dynamic>?)
        : (session['id_verification'] as Map<String, dynamic>?);

    if (idVerif != null) {
      final reasons = idVerif['rejection_reasons'] as List?;
      if (reasons != null && reasons.isNotEmpty) {
        return reasons.map((e) => e.toString()).join(', ');
      }
    }

    final warnings = session['warnings'] as List?;
    if (warnings != null && warnings.isNotEmpty) {
      return warnings.map((e) => e.toString()).join(', ');
    }

    return null;
  }

  /// Extracts photographic assets (front, back, selfie) from Didit decision data
  List<String> extractDocumentImages(Map<String, dynamic>? decisionData) {
    final urls = <String>[];
    if (decisionData == null) return urls;
    final session = (decisionData['session'] as Map<String, dynamic>?) ?? decisionData;

    final idVerifList = session['id_verifications'] as List?;
    final idVerif = (idVerifList != null && idVerifList.isNotEmpty)
        ? (idVerifList.first as Map<String, dynamic>?)
        : (session['id_verification'] as Map<String, dynamic>?);

    if (idVerif != null) {
      final front = idVerif['front_image'] as String? ??
          idVerif['full_front_image'] as String?;
      final back = idVerif['back_image'] as String? ??
          idVerif['full_back_image'] as String?;
      final portrait = idVerif['portrait_image'] as String?;

      if (front != null && front.isNotEmpty && !urls.contains(front)) urls.add(front);
      if (back != null && back.isNotEmpty && !urls.contains(back)) urls.add(back);
      if (portrait != null && portrait.isNotEmpty && !urls.contains(portrait)) {
        urls.add(portrait);
      }
    }

    final livenessList = session['liveness'] as List?;
    final liveness = (livenessList != null && livenessList.isNotEmpty)
        ? (livenessList.first as Map<String, dynamic>?)
        : (session['liveness'] as Map<String, dynamic>?);

    if (liveness != null) {
      final ref = liveness['reference_image'] as String?;
      if (ref != null && ref.isNotEmpty && !urls.contains(ref)) urls.add(ref);
    }

    return urls;
  }

  String? resultStatusToString(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.approved:
        return 'approved';
      case VerificationStatus.pending:
        return 'pending';
      case VerificationStatus.declined:
        return 'declined';
      default:
        return null;
    }
  }
}
