import 'dart:io';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;

import '../jpeg_size.dart';
import '../landmark_names.dart';
import '../pose_estimator.dart';
import '../pose_frame.dart';

/// On-device pose estimation with Google ML Kit (33-point BlazePose model).
class MlKitPoseEstimator implements PoseEstimator {
  mlkit.PoseDetector? _detector;

  mlkit.PoseDetector get _ready => _detector ??= mlkit.PoseDetector(
        options: mlkit.PoseDetectorOptions(
          mode: mlkit.PoseDetectionMode.single,
          model: mlkit.PoseDetectionModel.accurate,
        ),
      );

  @override
  Future<List<PoseLandmark>?> estimate(String imagePath) async {
    // ML Kit reports pixel coordinates, so the image size is needed to
    // normalise them.
    final size = readJpegSize(await File(imagePath).readAsBytes());
    if (size == null || size.width == 0 || size.height == 0) return null;

    final poses = await _ready.processImage(
      mlkit.InputImage.fromFilePath(imagePath),
    );
    if (poses.isEmpty) return null;

    final landmarks = List<PoseLandmark>.filled(
      PoseLandmarkIndex.count,
      const PoseLandmark(x: 0, y: 0, visibility: 0),
    );
    for (final entry in poses.first.landmarks.entries) {
      final index = landmarkIndexFor(entry.key.name, entry.key.index);
      if (index < 0 || index >= landmarks.length) continue;
      final point = entry.value;
      landmarks[index] = PoseLandmark(
        x: point.x / size.width,
        y: point.y / size.height,
        z: point.z / size.width,
        visibility: point.likelihood,
      );
    }
    return landmarks;
  }

  @override
  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
  }
}
