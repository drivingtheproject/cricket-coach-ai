import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'analysis/analyzers.dart';
import 'auth/auth_controller.dart';
import 'auth/local_auth_repository.dart';
import 'capture/clip_picker.dart';
import 'db/app_database.dart';
import 'pose/plugins/mlkit_pose_estimator.dart';
import 'pose/plugins/thumbnail_frame_extractor.dart';
import 'pose/pose_extraction_service.dart';
import 'sessions/analysis_pipeline.dart';
import 'sessions/session_repository.dart';
import 'sessions/video_store.dart';

/// The long-lived objects the app is built from.
class AppServices {
  AppServices({
    required this.database,
    required this.auth,
    required this.sessions,
    required this.videos,
    required this.clipPicker,
    required this.pipeline,
  });

  final Database database;
  final AuthController auth;
  final SessionRepository sessions;
  final VideoStore videos;
  final ClipPicker clipPicker;
  final AnalysisPipeline pipeline;

  /// Opens the on-device database and restores the previous sign-in.
  static Future<AppServices> create() async {
    final database = await AppDatabase.openOnDevice();
    final auth = AuthController(LocalAuthRepository(database));
    await auth.restore();
    final sessions = SessionRepository(database);
    final videos = VideoStore.onDevice();
    return AppServices(
      database: database,
      auth: auth,
      sessions: sessions,
      videos: videos,
      clipPicker: ImagePickerClipPicker(),
      pipeline: AnalysisPipeline(
        videos: videos,
        sessions: sessions,
        analyzers: defaultAnalyzers(),
        poses: PoseExtractionService(
          extractor: const ThumbnailFrameExtractor(),
          estimator: MlKitPoseEstimator(),
        ),
      ),
    );
  }
}

/// Makes [AppServices] available to every widget below it.
class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'No ServicesScope above this widget.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope oldWidget) =>
      oldWidget.services != services;
}
