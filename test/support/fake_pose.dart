import 'package:cricket_coach_ai/core/pose/frame_extractor.dart';
import 'package:cricket_coach_ai/core/pose/pose_estimator.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';

/// 33 well-detected landmarks in a vertical line, optionally shifted sideways.
List<PoseLandmark> standingPose({double shift = 0}) => List.generate(
      PoseLandmarkIndex.count,
      (i) => PoseLandmark(x: 0.5 + shift, y: i / 40, visibility: 0.9),
    );

class FakeFrameExtractor implements FrameExtractor {
  FakeFrameExtractor({this.durationMs = 1000, this.readable = true});

  final int durationMs;
  final bool readable;
  final List<int> requestedTimes = [];

  @override
  Future<VideoInfo?> probe(String videoPath) async => readable
      ? VideoInfo(durationMs: durationMs, width: 1280, height: 720)
      : null;

  @override
  Future<String?> extractFrame(
    String videoPath,
    int timeMs,
    String outputPath,
  ) async {
    requestedTimes.add(timeMs);
    return outputPath;
  }
}

class FakePoseEstimator implements PoseEstimator {
  /// [detects] decides, per call (0-based), whether a person is found.
  FakePoseEstimator({bool Function(int call)? detects})
      : _detects = detects ?? ((_) => true);

  final bool Function(int call) _detects;
  int calls = 0;

  @override
  Future<List<PoseLandmark>?> estimate(String imagePath) async {
    final call = calls++;
    return _detects(call) ? standingPose() : null;
  }

  @override
  Future<void> dispose() async {}
}
