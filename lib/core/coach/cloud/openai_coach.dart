import 'package:http/http.dart' as http;

import '../coach_prompt.dart';
import '../coach_provider.dart';
import 'cloud_coach.dart';

/// Coach backed by OpenAI's Responses API.
class OpenAiCoach extends CloudCoach {
  OpenAiCoach({
    required super.client,
    required super.apiKey,
    required super.model,
    super.timeout,
  });

  static const String defaultModel = 'gpt-6-luna';
  static final Uri endpoint = Uri.parse('https://api.openai.com/v1/responses');

  @override
  CoachProviderKind get kind => CoachProviderKind.openAi;

  @override
  http.Request buildRequest(CoachPrompt prompt, String key, String model) {
    return CloudCoach.post(
      endpoint,
      {'authorization': 'Bearer $key'},
      {'model': model, 'instructions': prompt.system, 'input': prompt.user},
    );
  }

  @override
  String? extractText(Map<String, dynamic> body) {
    final output = body['output'];
    if (output is! List) return null;
    return [
      for (final item in output)
        if (item is Map && item['type'] == 'message' && item['content'] is List)
          for (final part in item['content'] as List)
            if (part is Map && part['type'] == 'output_text') '${part['text']}',
    ].join();
  }
}
