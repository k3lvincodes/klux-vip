import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kenick_vip/config/env_config.dart';

class VehicleEvaluationResult {
  const VehicleEvaluationResult({
    required this.isApproved,
    required this.reason,
    this.executiveTier = '',
    this.evaluatedByAi = false,
  });

  factory VehicleEvaluationResult.fromJson(Map<String, dynamic> json, {bool evaluatedByAi = true}) {
    return VehicleEvaluationResult(
      isApproved: json['is_approved'] == true,
      reason: json['reason']?.toString() ?? '',
      executiveTier: json['executive_tier']?.toString() ?? '',
      evaluatedByAi: evaluatedByAi,
    );
  }

  final bool isApproved;
  final String reason;
  final String executiveTier;
  final bool evaluatedByAi;
}

class AiVehicleService {
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Evaluates a vehicle proposal submitted by a chauffeur using VIP Fleet AI.
  /// Strictly enforces:
  /// 1. Color MUST be Black (case-insensitive).
  /// 2. Vehicle must be an executive VIP tier vehicle (e.g., Escalade, S-Class, Yukon Denali, Navigator).
  /// Economy/mid-tier consumer vehicles are disqualified.
  static Future<VehicleEvaluationResult> evaluateVehicle({
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    final cleanColor = color.trim().toLowerCase();

    // Immediate hard rule: Color MUST be black
    if (!_isBlackColor(cleanColor)) {
      return VehicleEvaluationResult(
        isApproved: false,
        reason:
            'Kenick VIP chauffeur standards strictly require vehicles to have a Black exterior (Onyx, Metallic, or Jet Black) for VIP executive protocol. "$color" vehicles cannot be accepted into the VIP fleet.',
        executiveTier: 'Disqualified (Color)',
      );
    }

    // Try Gemini AI evaluation if key is available
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final aiResult = await _evaluateWithAi(
          apiKey: apiKey,
          make: make,
          model: model,
          year: year,
          color: color,
        );
        if (aiResult != null) return aiResult;
      } catch (e) {
        debugPrint('AI evaluation failed, falling back to rule engine: $e');
      }
    }

    // Fallback: Deterministic local rule engine
    return _evaluateLocal(make: make, model: model, year: year, color: color);
  }

  static bool _isBlackColor(String color) {
    final c = color.toLowerCase();
    return c == 'black' ||
        c.contains('black') ||
        c.contains('onyx') ||
        c.contains('nero') ||
        c.contains('noir');
  }

  static Future<VehicleEvaluationResult?> _evaluateWithAi({
    required String apiKey,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    final uri = Uri.parse('$_geminiEndpoint?key=$apiKey');

    final prompt = '''
You are the Chief Fleet Inspection AI for Kenick VIP, a world-class executive luxury chauffeur service.
Analyze the following proposed vehicle to determine whether it qualifies for executive VIP chauffeur service.

Vehicle Details:
- Make: $make
- Model: $model
- Year: $year
- Color: $color

Strict Fleet Criteria:
1. Exterior Color: ONLY Black (Onyx, Metallic Black, Jet Black) is allowed. Any other color must be rejected immediately.
2. Executive Luxury Tier: Only genuine luxury/VIP executive vehicles qualify:
   - Full-Size Luxury SUVs: Cadillac Escalade/ESV, GMC Yukon Denali/XL, Lincoln Navigator, Range Rover, Mercedes GLS/G-Wagon, BMW X7.
   - Tier-1 Executive Sedans: Mercedes S-Class, Maybach, BMW 7-Series, Audi A8L, Genesis G90, Porsche Panamera, Rolls-Royce, Bentley.
   - Executive Vans: Mercedes-Benz Sprinter VIP.
   - Disqualified: Economy/Standard consumer sedans or hatchbacks (e.g. Toyota Camry/Corolla, Honda Civic/Accord, Nissan Altima, Hyundai, Kia, standard minivans).
3. Minimum Model Year: Must be 2018 or newer.

Respond ONLY with a valid JSON object in this exact schema (no markdown, no backticks):
{
  "is_approved": boolean,
  "executive_tier": "string (e.g. First Class Executive SUV, Disqualified)",
  "reason": "string (Clear, professional explanation addressed to the chauffeur explaining why it was approved or why it was declined)"
}
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      },
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String;
          final parsed = jsonDecode(text.trim()) as Map<String, dynamic>;
          return VehicleEvaluationResult.fromJson(parsed);
        }
      }
    }
    return null;
  }

  static VehicleEvaluationResult _evaluateLocal({
    required String make,
    required String model,
    required int year,
    required String color,
  }) {
    final cleanMake = make.trim().toLowerCase();
    final cleanModel = model.trim().toLowerCase();

    // 1. Color check
    if (!_isBlackColor(color)) {
      return VehicleEvaluationResult(
        isApproved: false,
        reason:
            'Kenick VIP protocol strictly requires an all-black exterior. "$color" does not meet executive fleet standards.',
        executiveTier: 'Disqualified',
      );
    }

    // 2. Year check (minimum 2018)
    if (year < 2018) {
      return VehicleEvaluationResult(
        isApproved: false,
        reason:
            'Vehicle year ($year) does not meet Kenick VIP requirements. Vehicles must be 2018 or newer to ensure modern passenger safety and prestige.',
        executiveTier: 'Disqualified',
      );
    }

    // 3. Known Disqualified Economy/Everyday Makes & Models
    final everydayMakes = [
      'toyota',
      'honda',
      'nissan',
      'hyundai',
      'kia',
      'mazda',
      'volkswagen',
      'subaru',
      'mitsubishi',
      'chrysler',
      'dodge',
      'jeep',
      'ford',
    ];

    // Allowed exceptions for Ford/GMC/Chevy (Only large VIP SUVs)
    final allowedAmericanVipSuvs = [
      'expedition',
      'navigator',
      'escalade',
      'yukon',
      'suburban',
      'tahoe',
    ];

    final isDisqualifiedMake = everydayMakes.contains(cleanMake);
    final hasVipAmericanSuvModel = allowedAmericanVipSuvs.any((vip) => cleanModel.contains(vip));

    if (isDisqualifiedMake && !hasVipAmericanSuvModel) {
      return VehicleEvaluationResult(
        isApproved: false,
        reason:
            '$make $model is classified as a standard/consumer vehicle. Kenick VIP exclusively admits Tier-1 Executive Sedans and Full-Size Luxury SUVs (e.g. Cadillac Escalade, Mercedes-Benz S-Class, GMC Yukon Denali, Lincoln Navigator).',
        executiveTier: 'Disqualified (Standard Class)',
      );
    }

    // 4. Recognized Luxury & VIP Brands
    final luxuryMakes = [
      'cadillac',
      'mercedes',
      'mercedes-benz',
      'bmw',
      'audi',
      'lincoln',
      'land rover',
      'range rover',
      'rolls-royce',
      'bentley',
      'genesis',
      'porsche',
      'gmc',
      'lexus',
    ];

    final isLuxuryMake = luxuryMakes.any((lux) => cleanMake.contains(lux));

    if (!isLuxuryMake && !hasVipAmericanSuvModel) {
      return VehicleEvaluationResult(
        isApproved: false,
        reason:
            '$make does not belong to the recognized executive VIP manufacturer registry for Kenick VIP. Only vetted premier luxury marques are eligible.',
        executiveTier: 'Disqualified',
      );
    }

    // Check for lower-tier compact luxury cars (e.g. Mercedes A-Class, BMW 1/2/3 series, Audi A3)
    final lowerTierKeywords = ['a-class', 'cla', 'b-class', '1 series', '2 series', '3 series', 'a3', 'q3', 'x1', 'x2', 'ct4'];
    if (lowerTierKeywords.any((kw) => cleanModel.contains(kw))) {
      return VehicleEvaluationResult(
        isApproved: false,
        reason:
            '$make $model is an entry-level compact vehicle. Kenick VIP requires full-size executive luxury sedans or flagship SUVs.',
        executiveTier: 'Disqualified (Compact)',
      );
    }

    // Passed all VIP criteria!
    return VehicleEvaluationResult(
      isApproved: true,
      reason:
          'Qualified! The $year $make $model in Black satisfies Kenick VIP flagship standards. Your proposal will be submitted to the Fleet Admin for final review.',
      executiveTier: 'Executive Flagship Class',
    );
  }
}
