import 'dart:convert';

/// Indexes of the 33 body landmarks (the BlazePose topology used by both
/// MediaPipe and ML Kit).
abstract final class PoseLandmarkIndex {
  static const int nose = 0;
  static const int leftEar = 7;
  static const int rightEar = 8;
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
  static const int leftHeel = 29;
  static const int rightHeel = 30;
  static const int leftFootIndex = 31;
  static const int rightFootIndex = 32;

  static const int count = 33;
}

/// One body landmark. [x] and [y] are normalised to the image (0..1, with y
/// growing downwards). [visibility] is the detector's confidence, 0..1.
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

/// All landmarks detected in a single video frame. [landmarks] is empty when
/// nobody was found in the frame.
class PoseFrame {
  const PoseFrame({required this.timestampMs, required this.landmarks});

  final int timestampMs;
  final List<PoseLandmark> landmarks;

  bool get isEmpty => landmarks.isEmpty;

  PoseLandmark operator [](int index) => landmarks[index];
}

/// Compact JSON encoding for storing a clip's frames in the database:
/// `[{"t": ms, "l": [x, y, visibility, x, y, visibility, ...]}, ...]`.
abstract final class PoseCodec {
  static String encode(List<PoseFrame> frames) {
    return jsonEncode([
      for (final frame in frames)
        {
          't': frame.timestampMs,
          'l': [
            for (final point in frame.landmarks) ...[
              _round(point.x),
              _round(point.y),
              _round(point.visibility),
            ],
          ],
        },
    ]);
  }

  static List<PoseFrame> decode(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return [
      for (final item in list) _frame(item as Map<String, dynamic>),
    ];
  }

  static PoseFrame _frame(Map<String, dynamic> map) {
    final values = (map['l'] as List<dynamic>).cast<num>();
    return PoseFrame(
      timestampMs: (map['t'] as num).toInt(),
      landmarks: [
        for (var i = 0; i + 2 < values.length; i += 3)
          PoseLandmark(
            x: values[i].toDouble(),
            y: values[i + 1].toDouble(),
            visibility: values[i + 2].toDouble(),
          ),
      ],
    );
  }

  static double _round(double value) => (value * 10000).round() / 10000;
}
