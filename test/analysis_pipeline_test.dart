import 'dart:io';

import 'package:cricket_coach_ai/core/analysis_exception.dart';
import 'package:cricket_coach_ai/core/auth/user.dart';
import 'package:cricket_coach_ai/core/pose/pose_extraction_service.dart';
import 'package:cricket_coach_ai/core/pose/pose_frame.dart';
import 'package:cricket_coach_ai/core/sessions/analysis_pipeline.dart';
import 'package:cricket_coach_ai/core/sessions/session.dart';
import 'package:cricket_coach_ai/core/sessions/session_repository.dart';
import 'package:cricket_coach_ai/core/sessions/video_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_pose.dart';
import 'support/test_database.dart';

void main() {
  final user = User(
    id: 'user-1',
    email: 'user-1@example.com',
    displayName: 'Test Player',
    createdAt: DateTime(2026),
  );

  late Database db;
  late Directory root;
  late Directory documents;
  late Directory temporary;
  late File clip;
  late VideoStore videos;
  late SessionRepository sessions;

  setUp(() async {
    db = await openTestDatabase();
    await insertTestUser(db);
    root = await Directory.systemTemp.createTemp('cricket_coach_test');
    documents = await Directory(p.join(root.path, 'docs')).create();
    temporary = await Directory(p.join(root.path, 'tmp')).create();
    clip = File(p.join(root.path, 'picked.MOV'));
    await clip.writeAsBytes([1, 2, 3, 4]);
    videos = VideoStore(
      documentsDirectory: () async => documents,
      temporaryDirectory: () async => temporary,
    );
    sessions = SessionRepository(db);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  AnalysisPipeline pipeline({
    FakeFrameExtractor? extractor,
    FakePoseEstimator? estimator,
  }) {
    return AnalysisPipeline(
      videos: videos,
      sessions: sessions,
      now: () => DateTime(2026, 11, 12, 9, 5),
      poses: PoseExtractionService(
        extractor: extractor ?? FakeFrameExtractor(durationMs: 2000),
        estimator: estimator ?? FakePoseEstimator(),
        sampleFps: 10,
      ),
    );
  }

  Future<Session> run(AnalysisPipeline pipeline, {AnalysisProgress? onProgress}) {
    return pipeline.run(
      user: user,
      sourcePath: clip.path,
      discipline: Discipline.batting,
      handedness: Handedness.left,
      onProgress: onProgress,
    );
  }

  group('VideoStore', () {
    test('copies the clip in and returns a relative path', () async {
      final relative = await videos.importClip(clip.path, 'abc');

      expect(relative, 'videos/abc.mov');
      final stored = await videos.resolve(relative);
      expect(stored.path, p.join(documents.path, 'videos', 'abc.mov'));
      expect(await stored.readAsBytes(), [1, 2, 3, 4]);
    });

    test('uses .mp4 when the picked file has no extension', () async {
      final bare = File(p.join(root.path, 'picked'));
      await bare.writeAsBytes([9]);

      expect(await videos.importClip(bare.path, 'abc'), 'videos/abc.mp4');
    });

    test('delete removes the clip and tolerates missing ones', () async {
      final relative = await videos.importClip(clip.path, 'abc');

      await videos.delete(relative);
      await videos.delete(relative);
      await videos.delete(null);

      expect((await videos.resolve(relative)).existsSync(), isFalse);
    });

    test('work folders are created and removed per session', () async {
      final work = await videos.createWorkDirectory('abc');
      expect(work.existsSync(), isTrue);

      await videos.removeWorkDirectory('abc');
      await videos.removeWorkDirectory('abc');

      expect(work.existsSync(), isFalse);
    });
  });

  group('AnalysisPipeline', () {
    test('saves a session with its clip and pose data', () async {
      final session = await run(pipeline());

      final saved = await sessions.getById(session.id);
      expect(saved, isNotNull);
      expect(saved!.userId, 'user-1');
      expect(saved.title, 'Batting clip');
      expect(saved.discipline, Discipline.batting);
      expect(saved.handedness, Handedness.left);
      expect(saved.durationMs, 2000);
      expect(saved.createdAt, DateTime(2026, 11, 12, 9, 5));
      expect(saved.syncState, SyncState.pending);
      expect(saved.videoPath, 'videos/${session.id}.mov');
      expect((await videos.resolve(saved.videoPath!)).existsSync(), isTrue);

      final frames = PoseCodec.decode((await sessions.loadPoses(session.id))!);
      expect(frames, hasLength(20));
      expect(frames.first.landmarks, hasLength(PoseLandmarkIndex.count));
    });

    test('reports its stages in order and cleans up its work folder', () async {
      final stages = <AnalysisStage>[];

      await run(
        pipeline(),
        onProgress: (stage, _) {
          if (stages.isEmpty || stages.last != stage) stages.add(stage);
        },
      );

      expect(stages, [
        AnalysisStage.savingClip,
        AnalysisStage.trackingBody,
        AnalysisStage.saving,
      ]);
      expect(temporary.listSync(), isEmpty);
    });

    test('rejects a clip where the player is rarely visible', () async {
      final failing = pipeline(
        estimator: FakePoseEstimator(detects: (call) => call % 5 == 0),
      );

      await expectLater(
        run(failing),
        throwsA(
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('could not see a person'),
          ),
        ),
      );

      expect(await sessions.listForUser('user-1'), isEmpty);
      expect(Directory(p.join(documents.path, 'videos')).listSync(), isEmpty);
      expect(temporary.listSync(), isEmpty);
    });

    test('saves nothing when the video cannot be read', () async {
      final failing = pipeline(extractor: FakeFrameExtractor(readable: false));

      await expectLater(run(failing), throwsA(isA<AnalysisException>()));

      expect(await sessions.listForUser('user-1'), isEmpty);
      expect(Directory(p.join(documents.path, 'videos')).listSync(), isEmpty);
    });
  });
}
