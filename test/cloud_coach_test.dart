import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cricket_coach_ai/core/coach/cloud/claude_coach.dart';
import 'package:cricket_coach_ai/core/coach/cloud/cloud_coach.dart';
import 'package:cricket_coach_ai/core/coach/cloud/gemini_coach.dart';
import 'package:cricket_coach_ai/core/coach/cloud/openai_coach.dart';
import 'package:cricket_coach_ai/core/coach/coach_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/sample_analysis.dart';

const reply = '{"summary": "Solid base.", "improvements": ["Longer stride"]}';

typedef Build = CloudCoach Function(http.Client client, {String? key});

void main() {
  CloudCoach claude(http.Client client, {String? key = 'sk-test'}) =>
      ClaudeCoach(
        client: client,
        apiKey: () async => key,
        model: () async => 'claude-test',
      );
  CloudCoach openAi(http.Client client, {String? key = 'sk-test'}) =>
      OpenAiCoach(
        client: client,
        apiKey: () async => key,
        model: () async => 'gpt-test',
      );
  CloudCoach gemini(http.Client client, {String? key = 'sk-test'}) =>
      GeminiCoach(
        client: client,
        apiKey: () async => key,
        model: () async => 'gemini-test',
      );

  http.Response json(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  group('ClaudeCoach', () {
    test('sends the Messages API request and reads the reply', () async {
      late http.Request sent;
      final coach = claude(
        MockClient((request) async {
          sent = request;
          return json({
            'content': [
              {'type': 'text', 'text': reply},
            ],
          });
        }),
      );

      final feedback = await coach.analyze(sampleAnalysis());

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(sent.headers['x-api-key'], 'sk-test');
      expect(sent.headers['anthropic-version'], '2023-06-01');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-test');
      expect(body['system'], contains('cricket coach'));
      expect(body['messages'][0]['role'], 'user');
      expect(body['messages'][0]['content'], contains('Front knee'));
      expect(feedback.summary, 'Solid base.');
      expect(feedback.improvements, ['Longer stride']);
    });
  });

  group('OpenAiCoach', () {
    test('sends the Responses API request and reads the reply', () async {
      late http.Request sent;
      final coach = openAi(
        MockClient((request) async {
          sent = request;
          return json({
            'output': [
              {'type': 'reasoning', 'summary': []},
              {
                'type': 'message',
                'content': [
                  {'type': 'output_text', 'text': reply},
                ],
              },
            ],
          });
        }),
      );

      final feedback = await coach.analyze(sampleAnalysis());

      expect(sent.url.toString(), 'https://api.openai.com/v1/responses');
      expect(sent.headers['authorization'], 'Bearer sk-test');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['model'], 'gpt-test');
      expect(body['instructions'], contains('cricket coach'));
      expect(body['input'], contains('Front knee'));
      expect(feedback.summary, 'Solid base.');
    });
  });

  group('GeminiCoach', () {
    test('sends the generateContent request and reads the reply', () async {
      late http.Request sent;
      final coach = gemini(
        MockClient((request) async {
          sent = request;
          return json({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': reply},
                  ],
                },
              },
            ],
          });
        }),
      );

      final feedback = await coach.analyze(sampleAnalysis());

      expect(
        sent.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-test:generateContent',
      );
      expect(sent.headers['x-goog-api-key'], 'sk-test');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(
        body['systemInstruction']['parts'][0]['text'],
        contains('cricket coach'),
      );
      expect(body['contents'][0]['parts'][0]['text'], contains('Front knee'));
      expect(feedback.summary, 'Solid base.');
    });
  });

  group('every cloud coach', () {
    final builders = <String, Build>{
      'Claude': claude,
      'ChatGPT': openAi,
      'Gemini': gemini,
    };

    for (final MapEntry(key: name, value: build) in builders.entries) {
      Future<String> failure(http.Client client, {String? key = 'k'}) async {
        try {
          await build(client, key: key).analyze(sampleAnalysis());
        } on CoachException catch (e) {
          return e.message;
        }
        return fail('expected a CoachException');
      }

      test('$name is available only with a key', () async {
        final client = MockClient((_) async => json({}));
        expect(await build(client, key: 'k').isAvailable(), isTrue);
        expect(await build(client, key: '').isAvailable(), isFalse);
        expect(await build(client, key: null).isAvailable(), isFalse);
      });

      test('$name asks for a key before calling out', () async {
        var called = false;
        final client = MockClient((_) async {
          called = true;
          return json({});
        });

        expect(await failure(client, key: null), contains('API key'));
        expect(called, isFalse);
      });

      test('$name explains a rejected key', () async {
        final message = await failure(MockClient((_) async => json({}, 401)));
        expect(message, '$name rejected the API key. Check it in Settings.');
      });

      test('$name explains an unknown model, a limit and other errors',
          () async {
        expect(
          await failure(MockClient((_) async => json({}, 404))),
          contains('model name'),
        );
        expect(
          await failure(MockClient((_) async => json({}, 429))),
          contains('limiting requests'),
        );
        expect(
          await failure(MockClient((_) async => json({}, 500))),
          contains('(500)'),
        );
      });

      test('$name explains a dropped connection', () async {
        expect(
          await failure(
            MockClient((_) async => throw const SocketException('offline')),
          ),
          contains('could not be reached'),
        );
        expect(
          await failure(
            MockClient((_) async => throw http.ClientException('reset')),
          ),
          contains('could not be reached'),
        );
        expect(
          await failure(
            MockClient((_) async => throw TimeoutException('slow')),
          ),
          contains('took too long'),
        );
      });

      test('$name rejects an empty or unreadable reply', () async {
        expect(
          await failure(MockClient((_) async => json({}))),
          contains('empty reply'),
        );
        expect(
          await failure(MockClient((_) async => http.Response('<html>', 200))),
          contains('could not be read'),
        );
      });
    }
  });
}
