import 'package:cricket_coach_ai/core/analysis/body.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/synthetic_clips.dart';

void main() {
  test('angleBetween measures the angle at the middle point', () {
    expect(
      angleBetween(const Pt(0, 1), const Pt(0, 0), const Pt(1, 0)),
      closeTo(90, 1e-9),
    );
    expect(
      angleBetween(const Pt(-1, 0), const Pt(0, 0), const Pt(1, 0)),
      closeTo(180, 1e-9),
    );
    expect(angleBetween(const Pt(0, 0), const Pt(0, 0), const Pt(1, 0)), 0);
  });

  test('sides follow the playing hand', () {
    expect(BodySide.dominant(Handedness.right), same(BodySide.right));
    expect(BodySide.leading(Handedness.right), same(BodySide.left));
    expect(BodySide.dominant(Handedness.left), same(BodySide.left));
    expect(BodySide.leading(Handedness.left), same(BodySide.right));
  });

  group('BodyFrame', () {
    test('corrects for the aspect ratio so angles are true', () {
      // In a 2:1 frame these normalised points form a right angle with equal
      // arms; uncorrected they would not.
      final frame = BodyFrame(
        frameOf(0, const {
          PoseLandmarkIndex.leftHip: (0.25, 0.5),
          PoseLandmarkIndex.leftKnee: (0.25, 0.9),
          PoseLandmarkIndex.leftAnkle: (0.45, 0.9),
        }),
        2,
      );

      expect(frame.at(PoseLandmarkIndex.leftHip)!.x, 0.5);
      expect(
        frame.angle(
          PoseLandmarkIndex.leftHip,
          PoseLandmarkIndex.leftKnee,
          PoseLandmarkIndex.leftAnkle,
        ),
        closeTo(90, 1e-9),
      );
    });

    test('hides landmarks the detector was unsure of', () {
      final frame = BodyFrame(
        frameOf(0, const {PoseLandmarkIndex.nose: (0.5, 0.2)}),
        1,
      );

      expect(frame.head, isNotNull);
      expect(frame.at(PoseLandmarkIndex.leftWrist), isNull);
      expect(frame.wrists, isNull);
      expect(frame.sideLength(BodySide.left), isNull);
    });

    test('an empty frame has no points', () {
      const frame = BodyFrame(PoseFrame(timestampMs: 0, landmarks: []), 1);
      expect(frame.head, isNull);
    });
  });

  group('BodyTrack', () {
    test('scale is the shoulder-to-ankle length', () {
      final track = BodyTrack(battingClip(), 1);
      // Stance: torso 0.25, thigh and shin about 0.15 each.
      expect(track.scale, closeTo(0.55, 0.03));
    });

    test('scale is null when the body is never fully seen', () {
      final track = BodyTrack(
        [frameOf(0, const {PoseLandmarkIndex.nose: (0.5, 0.2)})],
        1,
      );
      expect(track.scale, isNull);
      expect(track.speedOf((f) => f.head), [0]);
    });

    test('speed peaks during the fast part of the movement', () {
      final track = BodyTrack(battingClip(), 1);
      final speed = track.speedOf((f) => f.wrists);

      final peak = track.peak(speed)!;
      expect(peak, inInclusiveRange(battingSwingStart, battingSwingEnd));
      expect(speed[2], closeTo(0, 1e-9));
      expect(speed[peak], greaterThan(1));
    });

    test('peak and trough respect their range and skip NaN', () {
      final track = BodyTrack(battingClip(frames: 5), 1);
      final values = [3.0, double.nan, 1.0, 9.0, 2.0];

      expect(track.peak(values), 3);
      expect(track.peak(values, to: 3), 0);
      expect(track.trough(values), 2);
      expect(track.trough(values, from: 3), 4);
      expect(track.peak(values, from: 4, to: 4), isNull);
    });

    test('indexBefore steps back by time', () {
      final track = BodyTrack(battingClip(), 1);
      // 15 fps: 400 ms is 6 frames.
      expect(track.indexBefore(20, 400), 14);
      expect(track.indexBefore(3, 5000), 0);
    });

    test('near falls back to neighbouring frames', () {
      final track = BodyTrack(battingClip(frames: 6), 1);
      final value = track.near(3, (f) => f.timeMs == timeOf(4) ? 42.0 : null);
      expect(value, 42);
      expect(track.near(0, (f) => null), isNull);
    });
  });
}
