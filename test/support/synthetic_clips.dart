import 'dart:math' as math;

import 'package:cricket_coach_ai/core/pose/pose_frame.dart';

/// Builds a 33-landmark frame from the named points; everything else is
/// marked as not visible.
PoseFrame frameOf(int timeMs, Map<int, (double, double)> points) {
  final landmarks = List<PoseLandmark>.filled(
    PoseLandmarkIndex.count,
    const PoseLandmark(x: 0, y: 0, visibility: 0),
  );
  points.forEach((index, point) {
    landmarks[index] = PoseLandmark(x: point.$1, y: point.$2, visibility: 0.95);
  });
  return PoseFrame(timestampMs: timeMs, landmarks: landmarks);
}

(double, double) lerp((double, double) a, (double, double) b, double t) =>
    (a.$1 + (b.$1 - a.$1) * t, a.$2 + (b.$2 - a.$2) * t);

/// Moves through [keys] (frame number -> point), holding the first and last.
(double, double) keyframed(Map<int, (double, double)> keys, int frame) {
  final frames = keys.keys.toList()..sort();
  if (frame <= frames.first) return keys[frames.first]!;
  for (var i = 1; i < frames.length; i++) {
    if (frame <= frames[i]) {
      final a = frames[i - 1];
      final b = frames[i];
      return lerp(keys[a]!, keys[b]!, (frame - a) / (b - a));
    }
  }
  return keys[frames.last]!;
}

const int clipFps = 15;
int timeOf(int frame) => (frame * 1000 / clipFps).round();

/// Batting clip numbers, in frames at 15 fps: stance until 10, backlift to
/// its top at 17, downswing 17-21, follow-through until 29.
const int battingTopFrame = 17;
const int battingSwingStart = 17;
const int battingSwingEnd = 21;

/// Lower-body positions once the front foot has landed (from frame 16 on).
const (double, double) battingFrontHip = (0.54, 0.56);
const (double, double) battingFrontKnee = (0.64, 0.70);
const (double, double) battingFrontAnkle = (0.68, 0.85);
const (double, double) battingBackAnkle = (0.44, 0.85);

/// A right-hander's front-foot drive seen from side-on, in a square frame.
/// Pass [leftHanded] to mirror which landmarks are the front side.
List<PoseFrame> battingClip({bool leftHanded = false, int frames = 30}) {
  // For a right-hander the front (leading) side is the left side.
  final front = leftHanded
      ? (
          shoulder: PoseLandmarkIndex.rightShoulder,
          elbow: PoseLandmarkIndex.rightElbow,
          wrist: PoseLandmarkIndex.rightWrist,
          hip: PoseLandmarkIndex.rightHip,
          knee: PoseLandmarkIndex.rightKnee,
          ankle: PoseLandmarkIndex.rightAnkle,
        )
      : (
          shoulder: PoseLandmarkIndex.leftShoulder,
          elbow: PoseLandmarkIndex.leftElbow,
          wrist: PoseLandmarkIndex.leftWrist,
          hip: PoseLandmarkIndex.leftHip,
          knee: PoseLandmarkIndex.leftKnee,
          ankle: PoseLandmarkIndex.leftAnkle,
        );
  final back = leftHanded
      ? (
          shoulder: PoseLandmarkIndex.leftShoulder,
          elbow: PoseLandmarkIndex.leftElbow,
          wrist: PoseLandmarkIndex.leftWrist,
          hip: PoseLandmarkIndex.leftHip,
          knee: PoseLandmarkIndex.leftKnee,
          ankle: PoseLandmarkIndex.leftAnkle,
        )
      : (
          shoulder: PoseLandmarkIndex.rightShoulder,
          elbow: PoseLandmarkIndex.rightElbow,
          wrist: PoseLandmarkIndex.rightWrist,
          hip: PoseLandmarkIndex.rightHip,
          knee: PoseLandmarkIndex.rightKnee,
          ankle: PoseLandmarkIndex.rightAnkle,
        );

  return [
    for (var i = 0; i < frames; i++)
      () {
        final hands = keyframed(const {
          10: (0.52, 0.50),
          17: (0.44, 0.28),
          21: (0.66, 0.60),
          29: (0.62, 0.30),
        }, i);
        final head = keyframed(const {10: (0.50, 0.20), 16: (0.62, 0.21)}, i);
        final frontShoulder =
            keyframed(const {10: (0.52, 0.30), 16: (0.58, 0.31)}, i);
        return frameOf(timeOf(i), {
          PoseLandmarkIndex.nose: head,
          front.shoulder: frontShoulder,
          back.shoulder: keyframed(const {10: (0.48, 0.30), 16: (0.52, 0.31)}, i),
          front.elbow: (
            lerp(frontShoulder, hands, 0.5).$1 + 0.05,
            lerp(frontShoulder, hands, 0.5).$2,
          ),
          back.elbow: lerp(frontShoulder, hands, 0.5),
          front.wrist: (hands.$1 + 0.01, hands.$2),
          back.wrist: (hands.$1 - 0.01, hands.$2),
          front.hip: keyframed(const {10: (0.51, 0.55), 16: battingFrontHip}, i),
          back.hip: keyframed(const {10: (0.49, 0.55), 16: (0.50, 0.56)}, i),
          front.knee:
              keyframed(const {10: (0.53, 0.70), 16: battingFrontKnee}, i),
          back.knee: const (0.46, 0.70),
          front.ankle:
              keyframed(const {10: (0.54, 0.85), 16: battingFrontAnkle}, i),
          back.ankle: battingBackAnkle,
        });
      }(),
  ];
}

/// Bowling clip numbers, in frames at 15 fps: the front foot lands at 13 and
/// the ball is released at 16, with the arm vertical.
const int bowlingLandFrame = 13;
const int bowlingReleaseFrame = 16;
const (double, double) bowlingShoulder = (0.50, 0.30);
const double bowlingArmLength = 0.24;
const (double, double) bowlingFrontHip = (0.53, 0.56);
const (double, double) bowlingFrontKnee = (0.585, 0.70);
const (double, double) bowlingFrontAnkle = (0.62, 0.85);
const (double, double) bowlingBackAnkle = (0.40, 0.85);

/// A right-arm bowler's delivery seen from side-on, in a square frame. The
/// bowling arm swings in a circle about the shoulder at a steady speed.
/// [elbowBend] moves the elbow off the line of the arm to bend it.
List<PoseFrame> bowlingClip({
  bool leftArm = false,
  double elbowBend = 0,
  int frames = 30,
}) {
  final arm = leftArm ? _leftIndexes : _rightIndexes;
  final front = leftArm ? _rightIndexes : _leftIndexes;
  return [
    for (var i = 0; i < frames; i++)
      () {
        // 210 degrees (behind and low) at frame 12, vertical at 16, in front
        // and low at 20.
        final swing = i.clamp(12, 20) - 12;
        final angle = (210 - 30 * swing) * math.pi / 180;
        final hand = (
          bowlingShoulder.$1 + bowlingArmLength * math.cos(angle),
          bowlingShoulder.$2 - bowlingArmLength * math.sin(angle),
        );
        final elbow = lerp(bowlingShoulder, hand, 0.5);
        return frameOf(timeOf(i), {
          PoseLandmarkIndex.nose: const (0.52, 0.20),
          arm.shoulder: bowlingShoulder,
          arm.elbow: (elbow.$1 + elbowBend, elbow.$2),
          arm.wrist: hand,
          arm.hip: const (0.49, 0.56),
          arm.knee: const (0.44, 0.70),
          arm.ankle: bowlingBackAnkle,
          front.shoulder: const (0.52, 0.31),
          front.elbow: const (0.56, 0.36),
          front.wrist: const (0.60, 0.42),
          front.hip: bowlingFrontHip,
          front.knee: keyframed(
            const {8: (0.50, 0.70), bowlingLandFrame: bowlingFrontKnee},
            i,
          ),
          front.ankle: keyframed(
            const {8: (0.50, 0.85), bowlingLandFrame: bowlingFrontAnkle},
            i,
          ),
        });
      }(),
  ];
}

typedef SideIndexes = ({
  int shoulder,
  int elbow,
  int wrist,
  int hip,
  int knee,
  int ankle,
});

const SideIndexes _leftIndexes = (
  shoulder: PoseLandmarkIndex.leftShoulder,
  elbow: PoseLandmarkIndex.leftElbow,
  wrist: PoseLandmarkIndex.leftWrist,
  hip: PoseLandmarkIndex.leftHip,
  knee: PoseLandmarkIndex.leftKnee,
  ankle: PoseLandmarkIndex.leftAnkle,
);

const SideIndexes _rightIndexes = (
  shoulder: PoseLandmarkIndex.rightShoulder,
  elbow: PoseLandmarkIndex.rightElbow,
  wrist: PoseLandmarkIndex.rightWrist,
  hip: PoseLandmarkIndex.rightHip,
  knee: PoseLandmarkIndex.rightKnee,
  ankle: PoseLandmarkIndex.rightAnkle,
);

/// Catching clip numbers, in frames at 15 fps: ready until 10, the hands
/// reach and close by 14, then give until 18.
const int catchFrame = 14;
const double catchHandGap = 0.04;
const double catchStanceWidth = 0.20;
const double catchGive = 0.10;
const (double, double) catchHip = (0.54, 0.56);
const (double, double) catchKnee = (0.60, 0.70);
const (double, double) catchAnkle = (0.60, 0.85);

/// A two-handed catch seen from in front, in a square frame. With
/// [handsApart] the hands never move; with [wide] they reach but never
/// close.
List<PoseFrame> catchingClip({
  bool handsApart = false,
  bool wide = false,
  int frames = 30,
}) {
  return [
    for (var i = 0; i < frames; i++)
      () {
        final moving = keyframed(const {
          10: (0.60, 0.50),
          14: (0.52, 0.36),
          18: (0.52, 0.46),
        }, i);
        final left = handsApart
            ? const (0.60, 0.50)
            : wide
                ? (0.62, moving.$2)
                : moving;
        final right = (1 - left.$1, left.$2);
        return frameOf(timeOf(i), {
          PoseLandmarkIndex.nose: const (0.50, 0.22),
          PoseLandmarkIndex.leftShoulder: const (0.56, 0.32),
          PoseLandmarkIndex.rightShoulder: const (0.44, 0.32),
          PoseLandmarkIndex.leftElbow: (left.$1 + 0.06, left.$2 + 0.02),
          PoseLandmarkIndex.rightElbow: (right.$1 - 0.06, right.$2 + 0.02),
          PoseLandmarkIndex.leftWrist: left,
          PoseLandmarkIndex.rightWrist: right,
          PoseLandmarkIndex.leftHip: catchHip,
          PoseLandmarkIndex.rightHip: (1 - catchHip.$1, catchHip.$2),
          PoseLandmarkIndex.leftKnee: catchKnee,
          PoseLandmarkIndex.rightKnee: (1 - catchKnee.$1, catchKnee.$2),
          PoseLandmarkIndex.leftAnkle: catchAnkle,
          PoseLandmarkIndex.rightAnkle: (1 - catchAnkle.$1, catchAnkle.$2),
        });
      }(),
  ];
}
