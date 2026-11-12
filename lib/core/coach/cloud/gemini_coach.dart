import 'package:http/http.dart' as http;

import '../coach_prompt.dart';
import '../coach_provider.dart';
import 'cloud_coach.dart';

/// Coach backed by Google's Gemini API.
class GeminiCoach extends CloudCoach {
  GeminiCoach({
    required super.client,
    required super.apiKey,
    required super.model,
    super.timeout,
  });

  static const String defaultModel = 'gemini-3.6-flash';

  static Uri endpointFor(String model) => Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
      );

  @override
  CoachProviderKind get kind => CoachProviderKind.gemini;

  @override
  http.Request buildRequest(CoachPrompt prompt, String key, String model) {
    return CloudCoach.post(
      endpointFor(model),
      {'x-goog-api-key': key},
      {
        'systemInstruction': {
          'parts': [
            {'text': prompt.system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt.user},
            ],
          },
        ],
      },
    );
  }

  @override
  String? extractText(Map<String, dynamic> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    final content = first is Map ? first['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) return null;
    return [
      for (final part in parts)
        if (part is Map && part['text'] != null) '${part['text']}',
    ].join();
  }
}
