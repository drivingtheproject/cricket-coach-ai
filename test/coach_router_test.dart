import 'package:cricket_coach_ai/core/coach/coach_feedback.dart';
import 'package:cricket_coach_ai/core/coach/coach_provider.dart';
import 'package:cricket_coach_ai/core/coach/coach_router.dart';
import 'package:cricket_coach_ai/core/metrics/batting_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProvider implements CoachProvider {
  FakeProvider(this.kind, {required this.available});

  @override
  final CoachProviderKind kind;
  final bool available;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<CoachFeedback> analyze(BattingMetrics metrics) async =>
      const CoachFeedback(summary: 'ok');
}

void main() {
  final local = FakeProvider(CoachProviderKind.localGemma, available: true);
  final claude = FakeProvider(CoachProviderKind.claude, available: true);
  final noKey = FakeProvider(CoachProviderKind.openAi, available: false);

  test('defaults to the first available provider', () async {
    final picked = await CoachRouter([local, claude]).pick();
    expect(picked, same(local));
  });

  test('preferred provider wins when available', () async {
    final picked = await CoachRouter([local, claude])
        .pick(preferred: CoachProviderKind.claude);
    expect(picked, same(claude));
  });

  test('falls back when the preferred provider is unavailable', () async {
    final picked = await CoachRouter([noKey, local])
        .pick(preferred: CoachProviderKind.openAi);
    expect(picked, same(local));
  });

  test('returns null when nothing is available', () async {
    expect(await CoachRouter([noKey]).pick(), isNull);
  });
}
