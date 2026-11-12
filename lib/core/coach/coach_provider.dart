import '../analysis/technique_analysis.dart';
import 'coach_feedback.dart';

enum CoachProviderKind { localGemma, claude, openAi, gemini }

/// A model that turns a clip's measurements into coaching feedback.
abstract interface class CoachProvider {
  CoachProviderKind get kind;

  /// True when the provider can run right now: the local model is
  /// downloaded, or an API key is saved for a cloud provider.
  Future<bool> isAvailable();

  Future<CoachFeedback> analyze(TechniqueAnalysis analysis);
}
