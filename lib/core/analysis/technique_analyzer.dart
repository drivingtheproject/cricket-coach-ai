import '../pose/pose_frame.dart';
import '../sessions/session.dart';
import 'technique_analysis.dart';

/// Measures one discipline's technique from a clip's tracked poses.
abstract interface class TechniqueAnalyzer {
  Discipline get discipline;

  /// [aspectRatio] is the clip's width divided by its height.
  ///
  /// Throws an `AnalysisException` with a user-facing message when the
  /// movement cannot be found in the clip.
  TechniqueAnalysis analyze(
    List<PoseFrame> frames, {
    required Handedness handedness,
    required double aspectRatio,
  });
}
