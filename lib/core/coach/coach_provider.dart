import '../metrics/batting_metrics.dart';
import 'coach_feedback.dart';

enum CoachProviderKind { localGemma, claude, openAi, gemini }

/// A model that turns metrics into coaching feedback.
///
/// Implementations: on-device Gemma (M4) and the cloud providers (M3).
abstract interface class CoachProvider {
  CoachProviderKind get kind;

  /// True when the provider can run right now: the local model is
  /// downloaded, or an API key is saved for a cloud provider.
  Future<bool> isAvailable();

  Future<CoachFeedback> analyze(BattingMetrics metrics);
}
