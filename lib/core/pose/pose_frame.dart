/// Indexes of the MediaPipe pose landmarks (33 in total) that the metrics
/// engine reads.
abstract final class PoseLandmarkIndex {
  static const int nose = 0;
  static const int leftShoulder = 11;
  static const int rightShoulder = 12;
  static const int leftElbow = 13;
  static const int rightElbow = 14;
  static const int leftWrist = 15;
  static const int rightWrist = 16;
  static const int leftHip = 23;
  static const int rightHip = 24;
  static const int leftKnee = 25;
  static const int rightKnee = 26;
  static const int leftAnkle = 27;
  static const int rightAnkle = 28;

  static const int count = 33;
}

/// One body landmark. [x] and [y] are normalised to the image (0..1).
class PoseLandmark {
  const PoseLandmark({
    required this.x,
    required this.y,
    this.z = 0,
    this.visibility = 1,
  });

  final double x;
  final double y;
  final double z;
  final double visibility;
}

/// All landmarks detected in a single video frame.
class PoseFrame {
  const PoseFrame({required this.timestampMs, required this.landmarks});

  final int timestampMs;
  final List<PoseLandmark> landmarks;

  PoseLandmark operator [](int index) => landmarks[index];
}
