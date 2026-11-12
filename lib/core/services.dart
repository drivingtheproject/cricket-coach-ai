import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'analysis/analyzers.dart';
import 'auth/auth_controller.dart';
import 'auth/local_auth_repository.dart';
import 'capture/clip_picker.dart';
import 'coach/coach_service.dart';
import 'coach/coach_settings.dart';
import 'coach/local/gemma_coach.dart';
import 'coach/local/model_download_controller.dart';
import 'coach/local/plugins/edge_ai_llm.dart';
import 'db/app_database.dart';
import 'guide/filming_tour.dart';
import 'pose/plugins/mlkit_pose_estimator.dart';
import 'pose/plugins/thumbnail_frame_extractor.dart';
import 'pose/pose_extraction_service.dart';
import 'sessions/analysis_pipeline.dart';
import 'sessions/session_repository.dart';
import 'sessions/video_store.dart';
import 'settings/plugins/secure_secret_store.dart';
import 'settings/settings_repository.dart';
import 'sync/cloud_backend.dart';
import 'sync/sync_service.dart';

/// The long-lived objects the app is built from.
class AppServices {
  AppServices({
    required this.database,
    required this.auth,
    required this.sessions,
    required this.videos,
    required this.clipPicker,
    required this.pipeline,
    required this.coachSettings,
    required this.coach,
    required this.sync,
    required this.tours,
    this.localModel,
  });

  final Database database;
  final AuthController auth;
  final SessionRepository sessions;
  final VideoStore videos;
  final ClipPicker clipPicker;
  final AnalysisPipeline pipeline;
  final CoachSettings coachSettings;
  final CoachService coach;
  final SyncService sync;
  final TourProgress tours;

  /// The on-device model's download state; null in builds without one.
  final ModelDownloadController? localModel;

  /// Opens the on-device database and restores the previous sign-in.
  static Future<AppServices> create() async {
    final database = await AppDatabase.openOnDevice();
    final auth = AuthController(LocalAuthRepository(database));
    await auth.restore();
    final sessions = SessionRepository(database);
    final videos = VideoStore.onDevice();
    final settings = SettingsRepository(database);
    final coachSettings = CoachSettings(
      settings: settings,
      secrets: const SecureSecretStore(),
    );
    final llm = EdgeAiLlm();
    final coach = CoachService(
      settings: coachSettings,
      client: http.Client(),
      localCoach: GemmaCoach(llm),
    );
    return AppServices(
      database: database,
      auth: auth,
      sessions: sessions,
      videos: videos,
      clipPicker: ImagePickerClipPicker(),
      coachSettings: coachSettings,
      coach: coach,
      localModel: ModelDownloadController(llm),
      tours: TourProgress(settings),
      // Swap in a Firebase-backed CloudBackend here to turn sync on.
      sync: SyncService(
        sessions: sessions,
        settings: settings,
        backend: const NoCloudBackend(),
      ),
      pipeline: AnalysisPipeline(
        videos: videos,
        sessions: sessions,
        analyzers: defaultAnalyzers(),
        coach: coach,
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
