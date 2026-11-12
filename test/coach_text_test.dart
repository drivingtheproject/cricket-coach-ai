import 'package:cricket_coach_ai/core/analysis/analyzers.dart';
import 'package:cricket_coach_ai/core/analysis/batting_analyzer.dart';
import 'package:cricket_coach_ai/core/coach/coach_feedback.dart';
import 'package:cricket_coach_ai/core/coach/coach_prompt.dart';
import 'package:cricket_coach_ai/core/coach/coach_provider.dart';
import 'package:cricket_coach_ai/core/coach/drills.dart';
import 'package:cricket_coach_ai/core/coach/feedback_parser.dart';
import 'package:cricket_coach_ai/core/coach/rule_based_coach.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_analysis.dart';

void main() {
  group('CoachFeedback', () {
    test('survives encoding and decoding', () {
      const feedback = CoachFeedback(
        summary: 'Good shape.',
        strengths: ['a'],
        improvements: ['b', 'c'],
        drills: ['d'],
        notice: 'n',
      );

      final decoded = CoachFeedback.decode(feedback.encode());

      expect(decoded.summary, 'Good shape.');
      expect(decoded.strengths, ['a']);
      expect(decoded.improvements, ['b', 'c']);
      expect(decoded.drills, ['d']);
      expect(decoded.notice, 'n');
    });

    test('decodes when optional parts are missing', () {
      final decoded = CoachFeedback.decode('{"summary": "x"}');
      expect(decoded.strengths, isEmpty);
      expect(decoded.notice, isNull);
    });
  });

  group('buildCoachPrompt', () {
    final prompt = buildCoachPrompt(sampleAnalysis());

    test('lists every measurement with its range and status', () {
      expect(prompt.user, contains('Discipline: batting'));
      expect(prompt.user, contains('Player: right-handed'));
      expect(
        prompt.user,
        contains(
          '- Front knee bend at impact: 130° (guide range 115-155°, in range)',
        ),
      );
      expect(prompt.user, contains('above range'));
      expect(prompt.user, contains('below range'));
    });

    test('asks for JSON and rules out comments on the bat and ball', () {
      expect(prompt.system, contains('single JSON object'));
      expect(prompt.system, contains('"improvements"'));
      expect(prompt.system, contains('cannot see the video'));
    });

    test('combined holds both parts', () {
      expect(prompt.combined, startsWith(prompt.system));
      expect(prompt.combined, endsWith(prompt.user));
    });
  });

  group('parseCoachFeedback', () {
    test('reads a plain JSON reply', () {
      final feedback = parseCoachFeedback(
        '{"summary": "Solid.", "strengths": ["Head still"], '
        '"improvements": ["Longer stride"], "drills": ["Cone drill"]}',
      );

      expect(feedback.summary, 'Solid.');
      expect(feedback.strengths, ['Head still']);
      expect(feedback.improvements, ['Longer stride']);
      expect(feedback.drills, ['Cone drill']);
    });

    test('reads JSON wrapped in a code fence and extra words', () {
      final feedback = parseCoachFeedback(
        'Here you go:\n```json\n{"summary": "Solid.", "strengths": []}\n```',
      );
      expect(feedback.summary, 'Solid.');
    });

    test('accepts a single string where a list was asked for', () {
      final feedback = parseCoachFeedback(
        '{"summary": "s", "improvements": "Bend the knee"}',
      );
      expect(feedback.improvements, ['Bend the knee']);
    });

    test('keeps at most five points and drops blank ones', () {
      final feedback = parseCoachFeedback(
        '{"summary": "s", "drills": ["1", " ", "2", "3", "4", "5", "6"]}',
      );
      expect(feedback.drills, ['1', '2', '3', '4', '5']);
    });

    test('uses prose as the summary when there is no JSON', () {
      final feedback = parseCoachFeedback('  Keep your head still.  ');
      expect(feedback.summary, 'Keep your head still.');
      expect(feedback.strengths, isEmpty);
    });

    test('uses the whole reply when the JSON is broken or empty', () {
      expect(parseCoachFeedback('{"summary": ').summary, '{"summary":');
      expect(parseCoachFeedback('{}').summary, '{}');
    });

    test('rejects an empty reply', () {
      expect(() => parseCoachFeedback('  '), throwsA(isA<CoachException>()));
    });
  });

  group('RuleBasedCoach', () {
    const coach = RuleBasedCoach();

    test('is always available', () async {
      expect(await coach.isAvailable(), isTrue);
      expect(coach.kind, CoachProviderKind.builtIn);
    });

    test('names the weakest area and quotes the numbers', () async {
      final feedback = await coach.analyze(sampleAnalysis());

      expect(feedback.summary, contains('1 of 3 measurements'));
      expect(feedback.strengths, [BattingAnalyzer.frontKnee.good]);
      expect(feedback.improvements, hasLength(2));
      expect(feedback.improvements.first, contains('You measured'));
      expect(feedback.improvements.first, contains('guide range'));
      expect(feedback.drills, hasLength(2));
    });

    test('says so when everything is in range', () async {
      final feedback = await coach.analyze(cleanAnalysis());

      expect(feedback.summary, contains('Every measurement'));
      expect(feedback.improvements, isEmpty);
      expect(feedback.drills, isEmpty);
    });
  });

  group('drills', () {
    test('no drill for a measurement in range', () {
      expect(drillFor(BattingAnalyzer.stride.evaluate(45)), isNull);
    });

    test('low and high values get different drills', () {
      final low = drillFor(BattingAnalyzer.stride.evaluate(10));
      final high = drillFor(BattingAnalyzer.stride.evaluate(85));

      expect(low, isNotNull);
      expect(high, isNotNull);
      expect(low!.title, isNot(high!.title));
      expect(low.text, startsWith('${low.title}: '));
    });

    test('every metric an analyzer can report has a drill', () {
      final analyzers = defaultAnalyzers();
      expect(analyzers, isNotEmpty);
      const battingIds = [
        'front_knee',
        'front_elbow',
        'head_over_front_foot',
        'stride',
        'backlift',
        'head_level',
        'finish_balance',
      ];
      expect(metricIdsWithDrills, containsAll(battingIds));
    });
  });
}
