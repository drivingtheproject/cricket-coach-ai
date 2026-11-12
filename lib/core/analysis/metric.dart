/// Where a measured value sits against its guide range.
enum MetricStatus { low, good, high }

/// What one measurement means: its guide range and what to say about it.
///
/// Guide ranges are starting points drawn from common coaching advice, not
/// absolutes; they are meant to be tuned with a coach.
class MetricSpec {
  const MetricSpec({
    required this.id,
    required this.label,
    required this.unit,
    required this.idealMin,
    required this.idealMax,
    required this.tolerance,
    required this.scaleMin,
    required this.scaleMax,
    required this.good,
    required this.low,
    required this.high,
  });

  final String id;
  final String label;
  final String unit;
  final double idealMin;
  final double idealMax;

  /// How far outside the guide range the score reaches zero.
  final double tolerance;

  /// Ends of the bar the value is drawn on.
  final double scaleMin;
  final double scaleMax;

  /// Notes shown for a value inside, below and above the guide range.
  final String good;
  final String low;
  final String high;

  MetricResult evaluate(double value) {
    final status = value < idealMin
        ? MetricStatus.low
        : value > idealMax
            ? MetricStatus.high
            : MetricStatus.good;
    return MetricResult(
      id: id,
      label: label,
      unit: unit,
      value: value,
      idealMin: idealMin,
      idealMax: idealMax,
      scaleMin: scaleMin,
      scaleMax: scaleMax,
      score: rangeScore(value, idealMin, idealMax, tolerance),
      status: status,
      note: switch (status) {
        MetricStatus.good => good,
        MetricStatus.low => low,
        MetricStatus.high => high,
      },
    );
  }
}

/// 100 inside [min]..[max], falling in a straight line to 0 at [tolerance]
/// outside it.
double rangeScore(double value, double min, double max, double tolerance) {
  final outside = value < min
      ? min - value
      : value > max
          ? value - max
          : 0.0;
  if (outside == 0) return 100;
  if (tolerance <= 0 || outside >= tolerance) return 0;
  return 100 * (1 - outside / tolerance);
}

/// One measurement of a clip, stored with everything needed to draw it.
class MetricResult {
  const MetricResult({
    required this.id,
    required this.label,
    required this.unit,
    required this.value,
    required this.idealMin,
    required this.idealMax,
    required this.scaleMin,
    required this.scaleMax,
    required this.score,
    required this.status,
    required this.note,
  });

  factory MetricResult.fromJson(Map<String, dynamic> json) => MetricResult(
        id: json['id'] as String,
        label: json['label'] as String,
        unit: json['unit'] as String,
        value: (json['value'] as num).toDouble(),
        idealMin: (json['idealMin'] as num).toDouble(),
        idealMax: (json['idealMax'] as num).toDouble(),
        scaleMin: (json['scaleMin'] as num).toDouble(),
        scaleMax: (json['scaleMax'] as num).toDouble(),
        score: (json['score'] as num).toDouble(),
        status: MetricStatus.values.byName(json['status'] as String),
        note: json['note'] as String,
      );

  final String id;
  final String label;
  final String unit;
  final double value;
  final double idealMin;
  final double idealMax;
  final double scaleMin;
  final double scaleMax;

  /// 0-100.
  final double score;
  final MetricStatus status;
  final String note;

  /// "142°" or "38%".
  String get valueText => '${value.round()}$unit';

  /// "115-155°".
  String get guideText => '${idealMin.round()}-${idealMax.round()}$unit';

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'unit': unit,
        'value': _round(value),
        'idealMin': idealMin,
        'idealMax': idealMax,
        'scaleMin': scaleMin,
        'scaleMax': scaleMax,
        'score': _round(score),
        'status': status.name,
        'note': note,
      };

  static double _round(double value) => (value * 10).round() / 10;
}
