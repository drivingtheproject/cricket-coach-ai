import 'package:cricket_coach_ai/core/pose/jpeg_size.dart';
import 'package:cricket_coach_ai/core/pose/landmark_names.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:cricket_coach_ai/core/pose/pose_math.dart';
import 'package:cricket_coach_ai/core/pose/skeleton.dart';
import 'package:flutter_test/flutter_test.dart';

PoseFrame frameAt(int ms, {double x = 0.5}) => PoseFrame(
      timestampMs: ms,
      landmarks: [PoseLandmark(x: x, y: 0.25, visibility: 0.8)],
    );

void main() {
  group('PoseCodec', () {
    test('round-trips frames, including ones with no detection', () {
      final frames = [
        const PoseFrame(
          timestampMs: 0,
          landmarks: [
            PoseLandmark(x: 0.12345678, y: 0.5, visibility: 0.9),
            PoseLandmark(x: 1, y: 0, visibility: 0),
          ],
        ),
        const PoseFrame(timestampMs: 67, landmarks: []),
      ];

      final decoded = PoseCodec.decode(PoseCodec.encode(frames));

      expect(decoded, hasLength(2));
      expect(decoded[0].timestampMs, 0);
      expect(decoded[0][0].x, closeTo(0.1235, 1e-9));
      expect(decoded[0][0].visibility, 0.9);
      expect(decoded[0][1].x, 1);
      expect(decoded[1].timestampMs, 67);
      expect(decoded[1].isEmpty, isTrue);
    });

    test('encodes an empty clip as an empty list', () {
      expect(PoseCodec.decode(PoseCodec.encode(const [])), isEmpty);
    });
  });

  group('nearestFrameIndex', () {
    final frames = [frameAt(0), frameAt(100), frameAt(200), frameAt(300)];

    test('returns -1 when there are no frames', () {
      expect(nearestFrameIndex(const [], 50), -1);
    });

    test('finds the closest frame either side of the position', () {
      expect(nearestFrameIndex(frames, 0), 0);
      expect(nearestFrameIndex(frames, 40), 0);
      expect(nearestFrameIndex(frames, 60), 1);
      expect(nearestFrameIndex(frames, 100), 1);
      expect(nearestFrameIndex(frames, 249), 2);
      expect(nearestFrameIndex(frames, 251), 3);
    });

    test('clamps to the first and last frame', () {
      expect(nearestFrameIndex(frames, -500), 0);
      expect(nearestFrameIndex(frames, 99999), 3);
    });
  });

  group('smoothPoses', () {
    test('averages each landmark with its neighbours', () {
      final smoothed = smoothPoses([
        frameAt(0, x: 0.1),
        frameAt(100, x: 0.4),
        frameAt(200, x: 0.7),
      ]);

      expect(smoothed[0][0].x, closeTo(0.25, 1e-9));
      expect(smoothed[1][0].x, closeTo(0.4, 1e-9));
      expect(smoothed[2][0].x, closeTo(0.55, 1e-9));
      expect(smoothed.map((f) => f.timestampMs), [0, 100, 200]);
    });

    test('keeps empty frames empty and ignores them as neighbours', () {
      final smoothed = smoothPoses([
        frameAt(0, x: 0.2),
        const PoseFrame(timestampMs: 100, landmarks: []),
        frameAt(200, x: 0.8),
      ]);

      expect(smoothed[1].isEmpty, isTrue);
      expect(smoothed[0][0].x, closeTo(0.2, 1e-9));
      expect(smoothed[2][0].x, closeTo(0.8, 1e-9));
    });

    test('radius 0 leaves the frames untouched', () {
      final frames = [frameAt(0, x: 0.1), frameAt(100, x: 0.9)];
      expect(smoothPoses(frames, radius: 0), same(frames));
    });
  });

  group('skeleton', () {
    test('only refers to valid landmark indexes', () {
      final indexes = [
        for (final (a, b) in skeletonBones) ...[a, b],
        ...skeletonJoints,
      ];
      expect(
        indexes.every((i) => i >= 0 && i < PoseLandmarkIndex.count),
        isTrue,
      );
    });
  });

  group('landmarkIndexFor', () {
    test('matches measured landmarks by name, whatever their position', () {
      expect(landmarkIndexFor('leftKnee', 3), PoseLandmarkIndex.leftKnee);
      expect(landmarkIndexFor('rightWrist', 0), PoseLandmarkIndex.rightWrist);
    });

    test('falls back to the detector position for other landmarks', () {
      expect(landmarkIndexFor('leftEyeInner', 1), 1);
    });
  });

  group('readJpegSize', () {
    // SOI, an APP0 segment, then a baseline frame header for 1280x720.
    final jpeg = <int>[
      0xFF, 0xD8, //
      0xFF, 0xE0, 0x00, 0x10, ...List.filled(14, 0), //
      0xFF, 0xC0, 0x00, 0x11, 0x08, 0x02, 0xD0, 0x05, 0x00, 0x03, //
      ...List.filled(12, 0),
    ];

    test('reads width and height from the frame header', () {
      expect(readJpegSize(jpeg), (width: 1280, height: 720));
    });

    test('returns null for data that is not a JPEG', () {
      expect(readJpegSize([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0, 0, 0]), isNull);
      expect(readJpegSize(const []), isNull);
    });

    test('returns null when the header is cut off before the frame', () {
      expect(readJpegSize(jpeg.sublist(0, 22)), isNull);
    });
  });
}
