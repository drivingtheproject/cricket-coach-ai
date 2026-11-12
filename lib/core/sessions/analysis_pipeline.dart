import '../analysis/technique_analysis.dart';
import '../analysis/technique_analyzer.dart';
import '../analysis_exception.dart';
import '../auth/user.dart';
import '../pose/pose_extraction_service.dart';
import '../pose/pose_frame.dart';
import '../pose/pose_math.dart';
import '../util/ids.dart';
import 'session.dart';
import 'session_repository.dart';
import 'video_store.dart';

enum AnalysisStage {
  savingClip('Saving your clip'),
  trackingBody('Tracking your body position'),
  measuring('Measuring your technique'),
  coaching('Writing your feedback'),
  saving('Saving the session');

  const AnalysisStage(this.label);
  final String label;
}

typedef AnalysisProgress = void Function(AnalysisStage stage, double? progress);

/// Takes a picked clip all the way to a saved session.
class AnalysisPipeline {
  AnalysisPipeline({
    required this.videos,
    required this.poses,
    required this.sessions,
    this.analyzers = const {},
    this.minDetectionRate = 0.4,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final VideoStore videos;
  final PoseExtractionService poses;
  final SessionRepository sessions;

  /// Disciplines without an analyzer are saved with pose tracking only.
  final Map<Discipline, TechniqueAnalyzer> analyzers;

  /// Below this share of frames with a person in them, the clip is rejected.
  final double minDetectionRate;
  final DateTime Function() _now;

  /// Throws [AnalysisException] with a user-facing message when the clip
  /// cannot be analysed. Nothing is saved in that case.
  Future<Session> run({
    required User user,
    required String sourcePath,
    required Discipline discipline,
    required Handedness handedness,
    AnalysisProgress? onProgress,
  }) async {
    final id = newId();
    onProgress?.call(AnalysisStage.savingClip, null);
    final videoPath = await videos.importClip(sourcePath, id);
    try {
      final frames = await _trackBody(id, videoPath, onProgress);

      TechniqueAnalysis? analysis;
      final analyzer = analyzers[discipline];
      if (analyzer != null) {
        onProgress?.call(AnalysisStage.measuring, null);
        analysis = analyzer.analyze(
          frames.frames,
          handedness: handedness,
          aspectRatio: frames.aspectRatio,
        );
      }

      onProgress?.call(AnalysisStage.saving, null);
      final now = _now();
      final session = Session(
        id: id,
        userId: user.id,
        title: '${discipline.label} clip',
        discipline: discipline,
        handedness: handedness,
        videoPath: videoPath,
        durationMs: frames.durationMs,
        analysisJson: analysis?.encode(),
        score: analysis?.score,
        createdAt: now,
        updatedAt: now,
      );
      await sessions.insert(session);
      await sessions.savePoses(id, PoseCodec.encode(frames.frames));
      return session;
    } catch (_) {
      await videos.delete(videoPath);
      rethrow;
    }
  }

  Future<PoseExtractionResult> _trackBody(
    String id,
    String videoPath,
    AnalysisProgress? onProgress,
  ) async {
    onProgress?.call(AnalysisStage.trackingBody, 0);
    final video = await videos.resolve(videoPath);
    final workDirectory = await videos.createWorkDirectory(id);
    try {
      final result = await poses.run(
        video.path,
        workDirectory: workDirectory.path,
        onProgress: (value) =>
            onProgress?.call(AnalysisStage.trackingBody, value),
      );
      if (result.detectionRate < minDetectionRate) {
        throw const AnalysisException(
          'We could not see a person clearly enough in this clip. Film from '
          'side-on with your whole body in the frame and good light.',
        );
      }
      return PoseExtractionResult(
        frames: smoothPoses(result.frames),
        durationMs: result.durationMs,
        aspectRatio: result.aspectRatio,
      );
    } finally {
      await videos.removeWorkDirectory(id);
    }
  }
}
