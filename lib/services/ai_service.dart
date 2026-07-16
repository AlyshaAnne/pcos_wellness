import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  late final GenerativeModel _model;

  AIService() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY was not provided. '
            'Run Flutter using --dart-define=GEMINI_API_KEY=your_key',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: _apiKey,
    );
  }

  Future<String> generateWellnessInsight({
    required double mood,
    required double sleep,
    required double water,
    required double stress,
    required double energy,
    required double weight,
    required String cycleSummary,
    required String foodSummary,
  }) async {
    final prompt = '''
You are an AI wellness coach inside a PCOS wellness tracking app.

Do not diagnose. Do not claim to treat or cure PCOS.
Use gentle, supportive language.
Keep it short.

Mood: $mood / 5
Sleep: $sleep hours
Water: $water glasses
Stress: $stress / 10
Energy: $energy / 10
Weight: $weight kg

Cycle summary:
$cycleSummary

Food summary:
$foodSummary

Give:
1. A short pattern summary
2. 3 practical suggestions
3. One gentle reminder to seek medical advice for serious symptoms
''';

    try {
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      return response.text ??
          'AI insight could not be generated. Please try again later.';
    } catch (e) {
      return '''
Based on your current logs, your sleep appears low and stress appears high.

Try focusing on these first:
1. Aim for a more consistent sleep schedule.
2. Increase hydration throughout the day.
3. Keep logging mood, food, and cycle symptoms so the app can identify stronger patterns.

Gentle reminder: If symptoms feel severe or unusual, consider speaking with a healthcare professional.
''';
    }
  }
}