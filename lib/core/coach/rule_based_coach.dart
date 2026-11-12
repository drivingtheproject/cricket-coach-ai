import '../analysis/technique_analysis.dart';
import 'coach_feedback.dart';
import 'coach_provider.dart';
import 'drills.dart';

/// Writes feedback straight from the measurements, with no AI model. Always
/// available, so the player gets feedback offline and without an API key.
class RuleBasedCoach implements CoachProvider {
  const RuleBasedCoach();

  @override
  CoachProviderKind get kind => CoachProviderKind.builtIn;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<CoachFeedback> analyze(TechniqueAnalysis analysis) async {
    final strengths = analysis.strengths;
    final weaknesses = analysis.weaknesses;
    final activity = analysis.discipline.label.toLowerCase();

    final String summary;
    if (weaknesses.isEmpty) {
      summary = 'Every measurement of your $activity is inside its guide '
          'range. Keep repeating this movement so it holds up under pressure.';
    } else {
      final focus = weaknesses.first.label.toLowerCase();
      summary = '${strengths.length} of ${analysis.metrics.length} '
          'measurements of your $activity are in their guide range. The '
          'biggest gain is in your $focus.';
    }

    return CoachFeedback(
      summary: summary,
      strengths: [for (final metric in strengths.take(3)) metric.note],
      improvements: [
        for (final metric in weaknesses.take(3))
          '${metric.note} You measured ${metric.valueText}; the guide range '
              'is ${metric.guideText}.',
      ],
      drills: [
        for (final metric in weaknesses.take(3))
          if (drillFor(metric) case final drill?) drill.text,
      ],
    );
  }
}
