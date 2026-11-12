import '../analysis/metric.dart';
import '../analysis/technique_analysis.dart';

/// The instructions and the question sent to an AI coach.
class CoachPrompt {
  const CoachPrompt({required this.system, required this.user});

  final String system;
  final String user;

  /// Both parts as one text, for models without a separate system prompt.
  String get combined => '$system\n\n$user';
}

/// Builds the prompt for a clip's measurements. Only numbers and labels are
/// included; the video never leaves the phone.
CoachPrompt buildCoachPrompt(TechniqueAnalysis analysis) {
  final activity = analysis.discipline.label.toLowerCase();
  final lines = StringBuffer()
    ..writeln('Discipline: $activity')
    ..writeln('Player: ${analysis.handedness.label.toLowerCase()}')
    ..writeln('Overall technique score: ${analysis.score.round()} out of 100')
    ..writeln('Measurements from pose tracking of one side-on clip:');
  for (final metric in analysis.metrics) {
    lines.writeln(
      '- ${metric.label}: ${metric.valueText} '
      '(guide range ${metric.guideText}, ${_status(metric.status)})',
    );
  }
  lines.write(
    'Write feedback for this player based only on these measurements.',
  );

  return CoachPrompt(
    system: 'You are an experienced cricket coach reviewing a player\'s '
        '$activity. You are given body-position measurements taken from a '
        'video by pose tracking; you cannot see the video, the bat or the '
        'ball, so do not comment on them. Be specific, encouraging and '
        'practical, and use plain language a club player understands.\n'
        'Reply with a single JSON object and nothing else, in this shape:\n'
        '{"summary": "two or three sentences", '
        '"strengths": ["up to three short points"], '
        '"improvements": ["up to three short points, most important first"], '
        '"drills": ["up to three drills, each one sentence saying what to do '
        'and how many repetitions"]}',
    user: lines.toString(),
  );
}

String _status(MetricStatus status) => switch (status) {
      MetricStatus.good => 'in range',
      MetricStatus.low => 'below range',
      MetricStatus.high => 'above range',
    };
