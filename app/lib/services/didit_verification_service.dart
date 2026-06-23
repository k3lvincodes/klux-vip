import 'dart:convert';

import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kenick_vip/config/env_config.dart';

class DiditVerificationService {
  String get _apiKey => EnvConfig.diditApiKey;
  String get _workflowId => EnvConfig.diditVerificationWorkflowId;

  Future<String?> _createSession({
    required String workflowId,
    String? vendorData,
  }) async {
    final apiKey = _apiKey;

    if (apiKey.isEmpty) {
      debugPrint('DiditService: Missing DIDIT_API_KEY in .env');
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
        debugPrint('DiditService: Session created successfully');
        return sessionToken;
      } else {
        debugPrint('DiditService: Session creation failed with status ${sessionResponse.statusCode}: ${sessionResponse.body}');
        return null;
      }
    } catch (e) {
      debugPrint('DiditService: Error creating session: $e');
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
