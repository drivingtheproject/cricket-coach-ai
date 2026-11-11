import 'package:cricket_coach_ai/core/analysis_exception.dart';
import 'package:cricket_coach_ai/core/pose/pose_extraction_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_pose.dart';

void main() {
  test('sampleTimes spaces samples evenly across the clip', () {
    expect(PoseExtractionService.sampleTimes(1000, 10), [
      0, 100, 200, 300, 400, 500, 600, 700, 800, 900, //
    ]);
    final at15 = PoseExtractionService.sampleTimes(1000, 15);
    expect(at15, hasLength(15));
    expect(at15.first, 0);
    expect(at15.last, 933);
    expect(PoseExtractionService.sampleTimes(1, 15), [0]);
    expect(PoseExtractionService.sampleTimes(0, 15), isEmpty);
  });

  test('extracts one pose per sampled frame', () async {
    final extractor = FakeFrameExtractor(durationMs: 1000);
    final service = PoseExtractionService(
      extractor: extractor,
      estimator: FakePoseEstimator(),
      sampleFps: 10,
    );

    final result = await service.run('clip.mp4', workDirectory: 'work');

    expect(result.frames, hasLength(10));
    expect(result.durationMs, 1000);
    expect(result.detectionRate, 1);
    expect(extractor.requestedTimes.first, 0);
    expect(extractor.requestedTimes.last, 900);
    expect(result.frames.map((f) => f.timestampMs), extractor.requestedTimes);
  });

  test('reports progress that rises to 1', () async {
    final service = PoseExtractionService(
      extractor: FakeFrameExtractor(durationMs: 500),
      estimator: FakePoseEstimator(),
      sampleFps: 10,
    );
    final progress = <double>[];

    await service.run('clip.mp4', workDirectory: 'work', onProgress: progress.add);

    expect(progress, hasLength(5));
    expect(progress.last, 1);
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThan(progress[i - 1]));
    }
  });

  test('keeps an empty frame where nobody was detected', () async {
    final service = PoseExtractionService(
      extractor: FakeFrameExtractor(durationMs: 1000),
      estimator: FakePoseEstimator(detects: (call) => call.isEven),
      sampleFps: 10,
    );

    final result = await service.run('clip.mp4', workDirectory: 'work');

    expect(result.frames, hasLength(10));
    expect(result.frames[0].isEmpty, isFalse);
    expect(result.frames[1].isEmpty, isTrue);
    expect(result.detectionRate, 0.5);
  });

  test('analyses only the first part of a long clip', () async {
    final service = PoseExtractionService(
      extractor: FakeFrameExtractor(durationMs: 20000),
      estimator: FakePoseEstimator(),
      sampleFps: 5,
      maxDurationMs: 2000,
    );

    final result = await service.run('clip.mp4', workDirectory: 'work');

    expect(result.frames, hasLength(10));
    expect(result.durationMs, 2000);
  });

  test('explains when the video cannot be read', () async {
    final service = PoseExtractionService(
      extractor: FakeFrameExtractor(readable: false),
      estimator: FakePoseEstimator(),
    );

    await expectLater(
      service.run('broken.mp4', workDirectory: 'work'),
      throwsA(
        isA<AnalysisException>().having(
          (e) => e.message,
          'message',
          contains('could not be read'),
        ),
      ),
    );
  });
}
