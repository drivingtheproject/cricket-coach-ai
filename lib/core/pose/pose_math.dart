import 'dart:math' as math;

import 'pose_frame.dart';

/// Index of the frame whose timestamp is closest to [positionMs], or -1 when
/// there are no frames. [frames] must be in time order.
int nearestFrameIndex(List<PoseFrame> frames, int positionMs) {
  if (frames.isEmpty) return -1;
  var low = 0;
  var high = frames.length - 1;
  while (low < high) {
    final mid = (low + high) ~/ 2;
    if (frames[mid].timestampMs < positionMs) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  if (low > 0) {
    final before = positionMs - frames[low - 1].timestampMs;
    final after = frames[low].timestampMs - positionMs;
    if (before <= after) return low - 1;
  }
  return low;
}

/// Reduces frame-to-frame jitter with a moving average over [radius] frames
/// either side. Frames without a detection are left empty and never used as
/// neighbours.
List<PoseFrame> smoothPoses(List<PoseFrame> frames, {int radius = 1}) {
  if (radius <= 0) return frames;
  return [
    for (var i = 0; i < frames.length; i++)
      frames[i].isEmpty ? frames[i] : _average(frames, i, radius),
  ];
}

PoseFrame _average(List<PoseFrame> frames, int index, int radius) {
  final centre = frames[index];
  final first = math.max(0, index - radius);
  final last = math.min(frames.length - 1, index + radius);
  final neighbours = [
    for (var j = first; j <= last; j++)
      if (frames[j].landmarks.length == centre.landmarks.length) frames[j],
  ];
  return PoseFrame(
    timestampMs: centre.timestampMs,
    landmarks: [
      for (var k = 0; k < centre.landmarks.length; k++)
        PoseLandmark(
          x: _mean(neighbours.map((frame) => frame[k].x)),
          y: _mean(neighbours.map((frame) => frame[k].y)),
          z: centre[k].z,
          visibility: centre[k].visibility,
        ),
    ],
  );
}

double _mean(Iterable<double> values) {
  var sum = 0.0;
  var count = 0;
  for (final value in values) {
    sum += value;
    count++;
  }
  return count == 0 ? 0 : sum / count;
}
