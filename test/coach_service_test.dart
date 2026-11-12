import 'dart:convert';

import 'package:cricket_coach_ai/core/analysis/technique_analysis.dart';
import 'package:cricket_coach_ai/core/coach/coach_feedback.dart';
import 'package:cricket_coach_ai/core/coach/coach_provider.dart';
import 'package:cricket_coach_ai/core/coach/coach_service.dart';
import 'package:cricket_coach_ai/core/coach/coach_settings.dart';
import 'package:cricket_coach_ai/core/settings/secret_store.dart';
import 'package:cricket_coach_ai/core/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/sample_analysis.dart';
import 'support/test_database.dart';

class FakeLocalCoach implements CoachProvider {
  FakeLocalCoach({this.available = true});

  bool available;

  @override
  CoachProviderKind get kind => CoachProviderKind.localGemma;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<CoachFeedback> analyze(TechniqueAnalysis analysis) async =>
      const CoachFeedback(summary: 'from the phone');
}

void main() {
  const user = 'user-1';
  late Database db;
  late InMemorySecretStore secrets;
  late CoachSettings settings;
  late List<Uri> calls;

  setUp(() async {
    db = await openTestDatabase();
    await insertTestUser(db);
    secrets = InMemorySecretStore();
    settings = CoachSettings(
      settings: SettingsRepository(db),
      secrets: secrets,
    );
    calls = [];
  });

  tearDown(() => db.close());

  http.Client client({int status = 200}) => MockClient((request) async {
        calls.add(request.url);
        return http.Response(
          jsonEncode({
            'content': [
              {'type': 'text', 'text': '{"summary": "from Claude"}'},
            ],
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"summary": "from Gemini"}'},
                  ],
                },
              },
            ],
          }),
          status,
        );
      });

  group('SettingsRepository', () {
    test('stores, replaces and removes values per user', () async {
      final repository = SettingsRepository(db);
      await insertTestUser(db, id: 'user-2');

      expect(await repository.get(user, 'k'), isNull);
      await repository.set(user, 'k', 'one');
      await repository.set(user, 'k', 'two');
      await repository.set('user-2', 'k', 'other');

      expect(await repository.get(user, 'k'), 'two');
      expect(await repository.get('user-2', 'k'), 'other');

      await repository.remove(user, 'k');
      expect(await repository.get(user, 'k'), isNull);
      expect(await repository.get('user-2', 'k'), 'other');
    });
  });

  group('CoachSettings', () {
    test('preferred coach defaults to automatic and can be cleared', () async {
      expect(await settings.preferred(user), isNull);

      await settings.setPreferred(user, CoachProviderKind.gemini);
      expect(await settings.preferred(user), CoachProviderKind.gemini);

      await settings.setPreferred(user, null);
      expect(await settings.preferred(user), isNull);
    });

    test('keys go to the secret store, trimmed, and never to the database',
        () async {
      await settings.setApiKey(user, CoachProviderKind.claude, '  sk-abc \n');

      expect(await settings.apiKey(user, CoachProviderKind.claude), 'sk-abc');
      expect(await settings.apiKey(user, CoachProviderKind.openAi), isNull);
      expect(secrets.values.values, ['sk-abc']);
      expect(await db.query('user_settings'), isEmpty);
    });

    test('keys are separate for each user', () async {
      await settings.setApiKey(user, CoachProviderKind.claude, 'mine');
      expect(await settings.apiKey('user-2', CoachProviderKind.claude), isNull);
    });

    test('saving an empty key removes it', () async {
      await settings.setApiKey(user, CoachProviderKind.claude, 'sk-abc');
      await settings.setApiKey(user, CoachProviderKind.claude, ' ');

      expect(await settings.apiKey(user, CoachProviderKind.claude), isNull);
      expect(secrets.values, isEmpty);
    });

    test('model falls back to the default', () async {
      final fallback = CoachSettings.defaultModel(CoachProviderKind.claude);
      expect(fallback, isNotEmpty);
      expect(await settings.model(user, CoachProviderKind.claude), fallback);

      await settings.setModel(user, CoachProviderKind.claude, ' custom ');
      expect(await settings.model(user, CoachProviderKind.claude), 'custom');

      await settings.setModel(user, CoachProviderKind.claude, '');
      expect(await settings.model(user, CoachProviderKind.claude), fallback);
    });
  });

  group('CoachService', () {
    CoachService service({CoachProvider? local, int status = 200}) =>
        CoachService(
          settings: settings,
          client: client(status: status),
          localCoach: local,
        );

    test('uses the built-in coach when nothing is set up', () async {
      final result = await service().feedbackFor(user, sampleAnalysis());

      expect(result.kind, CoachProviderKind.builtIn);
      expect(result.feedback.notice, isNull);
      expect(calls, isEmpty);
    });

    test('automatic prefers the on-device coach over a cloud key', () async {
      await settings.setApiKey(user, CoachProviderKind.claude, 'k');

      final result = await service(local: FakeLocalCoach())
          .feedbackFor(user, sampleAnalysis());

      expect(result.kind, CoachProviderKind.localGemma);
      expect(calls, isEmpty);
    });

    test('automatic uses a cloud coach that has a key', () async {
      await settings.setApiKey(user, CoachProviderKind.claude, 'k');

      final result = await service(local: FakeLocalCoach(available: false))
          .feedbackFor(user, sampleAnalysis());

      expect(result.kind, CoachProviderKind.claude);
      expect(result.feedback.summary, 'from Claude');
      expect(calls.single.host, 'api.anthropic.com');
    });

    test('the preferred coach wins over the automatic order', () async {
      await settings.setApiKey(user, CoachProviderKind.claude, 'k');
      await settings.setApiKey(user, CoachProviderKind.gemini, 'k');
      await settings.setPreferred(user, CoachProviderKind.gemini);

      final result = await service(local: FakeLocalCoach())
          .feedbackFor(user, sampleAnalysis());

      expect(result.kind, CoachProviderKind.gemini);
      expect(result.feedback.summary, 'from Gemini');
    });

    test('falls back to the built-in coach and says why', () async {
      await settings.setApiKey(user, CoachProviderKind.claude, 'bad');

      final result =
          await service(status: 401).feedbackFor(user, sampleAnalysis());

      expect(result.kind, CoachProviderKind.builtIn);
      expect(result.feedback.improvements, isNotEmpty);
      expect(
        result.feedback.notice,
        'Claude rejected the API key. Check it in Settings. The built-in '
        'coach wrote this instead.',
      );
    });

    test('lists the built-in coach last', () {
      final kinds = service(local: FakeLocalCoach())
          .providersFor(user)
          .map((p) => p.kind)
          .toList();

      expect(kinds.first, CoachProviderKind.localGemma);
      expect(kinds.last, CoachProviderKind.builtIn);
      expect(kinds, hasLength(5));
    });
  });
}
