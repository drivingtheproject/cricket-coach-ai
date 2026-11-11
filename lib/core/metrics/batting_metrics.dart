/// Body-mechanics measurements for one batting shot.
///
/// This is the only thing sent to a coach provider - never the video.
/// Fields are nullable because a metric is skipped when its landmarks are
/// not visible enough. The calculations land in M2.
class BattingMetrics {
  const BattingMetrics({
    this.frontKneeAngleAtImpact,
    this.frontElbowAngleAtImpact,
    this.headOverFrontFootOffset,
    this.strideLengthRatio,
    this.hipShoulderSeparation,
  });

  /// Degrees. Around 180 is a straight front leg.
  final double? frontKneeAngleAtImpact;

  /// Degrees. A high front elbow is a hallmark of straight-bat shots.
  final double? frontElbowAngleAtImpact;

  /// Horizontal distance from head to front foot, as a fraction of body
  /// height. 0 means the head is directly over the front foot.
  final double? headOverFrontFootOffset;

  /// Stride length as a fraction of body height.
  final double? strideLengthRatio;

  /// Degrees of rotation between the hip line and the shoulder line.
  final double? hipShoulderSeparation;

  Map<String, Object?> toJson() => {
        'frontKneeAngleAtImpact': frontKneeAngleAtImpact,
        'frontElbowAngleAtImpact': frontElbowAngleAtImpact,
        'headOverFrontFootOffset': headOverFrontFootOffset,
        'strideLengthRatio': strideLengthRatio,
        'hipShoulderSeparation': hipShoulderSeparation,
      };
}
