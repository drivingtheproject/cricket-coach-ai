import 'pose_frame.dart';

/// Finds a person's body landmarks in a still image.
abstract interface class PoseEstimator {
  /// Returns the 33 landmarks normalised to the image, or null when nobody is
  /// detected.
  Future<List<PoseLandmark>?> estimate(String imagePath);

  Future<void> dispose();
}
