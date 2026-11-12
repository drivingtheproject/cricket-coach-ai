import 'package:http/http.dart' as http;

import '../coach_prompt.dart';
import '../coach_provider.dart';
import 'cloud_coach.dart';

/// Coach backed by Anthropic's Messages API.
class ClaudeCoach extends CloudCoach {
  ClaudeCoach({
    required super.client,
    required super.apiKey,
    required super.model,
    super.timeout,
  });

  static const String defaultModel = 'claude-sonnet-5-5';
  static final Uri endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  @override
  CoachProviderKind get kind => CoachProviderKind.claude;

  @override
  http.Request buildRequest(CoachPrompt prompt, String key, String model) {
    return CloudCoach.post(
      endpoint,
      {'x-api-key': key, 'anthropic-version': '2023-06-01'},
      {
        'model': model,
        'max_tokens': 1024,
        'system': prompt.system,
        'messages': [
          {'role': 'user', 'content': prompt.user},
        ],
      },
    );
  }

  @override
  String? extractText(Map<String, dynamic> body) {
    final content = body['content'];
    if (content is! List) return null;
    return [
      for (final block in content)
        if (block is Map && block['type'] == 'text') '${block['text']}',
    ].join();
  }
}
