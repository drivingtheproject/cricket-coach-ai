import 'dart:convert';

import '../sessions/session.dart';
import 'metric.dart';

/// A named moment in the movement, such as "Impact".
class PhaseMarker {
  const PhaseMarker(this.label, this.timeMs);

  final String label;
  final int timeMs;
}

/// Everything measured from one clip. This (never the video) is what a coach
/// provider receives.
class TechniqueAnalysis {
  const TechniqueAnalysis({
    required this.discipline,
    required this.handedness,
    required this.metrics,
    required this.phases,
  });

  factory TechniqueAnalysis.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return TechniqueAnalysis(
      discipline: Discipline.values.byName(json['discipline'] as String),
      handedness: Handedness.values.byName(json['handedness'] as String),
      metrics: [
        for (final item in json['metrics'] as List<dynamic>)
          MetricResult.fromJson(item as Map<String, dynamic>),
      ],
      phases: [
        for (final item in json['phases'] as List<dynamic>)
          PhaseMarker(
            (item as Map<String, dynamic>)['label'] as String,
            (item['t'] as num).toInt(),
          ),
      ],
    );
  }

  final Discipline discipline;
  final Handedness handedness;
  final List<MetricResult> metrics;
  final List<PhaseMarker> phases;

  /// Overall technique score, 0-100: the mean of the metric scores.
  double get score {
    if (metrics.isEmpty) return 0;
    return metrics.fold<double>(0, (sum, m) => sum + m.score) / metrics.length;
  }

  /// Metrics inside their guide range.
  List<MetricResult> get strengths =>
      metrics.where((m) => m.status == MetricStatus.good).toList();

  /// Metrics outside their guide range, furthest off first.
  List<MetricResult> get weaknesses =>
      metrics.where((m) => m.status != MetricStatus.good).toList()
        ..sort((a, b) => a.score.compareTo(b.score));

  String encode() => jsonEncode({
        'v': 1,
        'discipline': discipline.name,
        'handedness': handedness.name,
        'score': (score * 10).round() / 10,
        'metrics': [for (final metric in metrics) metric.toJson()],
        'phases': [
          for (final phase in phases) {'label': phase.label, 't': phase.timeMs},
        ],
      });
}
