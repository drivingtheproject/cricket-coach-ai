import 'dart:io';
import 'dart:math' as math;

import '../analysis_exception.dart';
import 'frame_extractor.dart';
import 'jpeg_size.dart';
import 'pose_estimator.dart';
import 'pose_frame.dart';

class PoseExtractionResult {
  const PoseExtractionResult({
    required this.frames,
    required this.durationMs,
    this.aspectRatio = 16 / 9,
  });

  /// One entry per sampled time; empty frames mark times with no detection.
  final List<PoseFrame> frames;
  final int durationMs;

  /// Width of the analysed frames divided by their height.
  final double aspectRatio;

  /// Share of sampled frames in which a person was found, 0..1.
  double get detectionRate {
    if (frames.isEmpty) return 0;
    return frames.where((frame) => !frame.isEmpty).length / frames.length;
  }
}

/// Turns a video file into a timed sequence of body poses by sampling frames
/// and running the pose estimator on each one.
class PoseExtractionService {
  PoseExtractionService({
    required this.extractor,
    required this.estimator,
    this.sampleFps = 15,
    this.maxDurationMs = 12000,
  });

  final FrameExtractor extractor;
  final PoseEstimator estimator;

  /// Frames analysed per second of video.
  final int sampleFps;

  /// Longer clips are analysed up to this point only.
  final int maxDurationMs;

  /// [workDirectory] must exist; temporary frame images are written there and
  /// removed as they are processed.
  Future<PoseExtractionResult> run(
    String videoPath, {
    required String workDirectory,
    void Function(double progress)? onProgress,
  }) async {
    final info = await extractor.probe(videoPath);
    if (info == null || info.durationMs <= 0) {
      throw const AnalysisException(
        'This clip could not be read. Try a different video.',
      );
    }

    final durationMs = math.min(info.durationMs, maxDurationMs);
    final times = sampleTimes(durationMs, sampleFps);
    final frames = <PoseFrame>[];
    double? aspectRatio;
    for (var i = 0; i < times.length; i++) {
      final written = await extractor.extractFrame(
        videoPath,
        times[i],
        '$workDirectory/frame_$i.jpg',
      );
      List<PoseLandmark>? landmarks;
      if (written != null) {
        try {
          // Measured from a real frame, so a rotated video is handled.
          aspectRatio ??= _aspectRatioOf(written);
          landmarks = await estimator.estimate(written);
        } finally {
          _deleteQuietly(written);
        }
      }
      frames.add(
        PoseFrame(timestampMs: times[i], landmarks: landmarks ?? const []),
      );
      onProgress?.call((i + 1) / times.length);
    }
    return PoseExtractionResult(
      frames: frames,
      durationMs: durationMs,
      aspectRatio: aspectRatio ??
          (info.height > 0 ? info.width / info.height : 16 / 9),
    );
  }

  static double? _aspectRatioOf(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return null;
      final size = readJpegSize(file.readAsBytesSync());
      if (size == null || size.width == 0 || size.height == 0) return null;
      return size.width / size.height;
    } on FileSystemException {
      return null;
    }
  }

  /// Evenly spaced sample times in milliseconds covering [durationMs].
  static List<int> sampleTimes(int durationMs, int fps) {
    final count = (durationMs * fps / 1000).ceil();
    return [for (var i = 0; i < count; i++) (i * 1000 / fps).round()];
  }

  static void _deleteQuietly(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // A leftover temporary frame is harmless; the work folder is removed
      // when the analysis ends.
    }
  }
}
