import '../analysis/technique_analysis.dart';
import 'coach_feedback.dart';

enum CoachProviderKind {
  localGemma('Gemma 4 on this phone', isCloud: false),
  claude('Claude', isCloud: true),
  openAi('ChatGPT', isCloud: true),
  gemini('Gemini', isCloud: true),
  builtIn('Built-in coach', isCloud: false);

  const CoachProviderKind(this.label, {required this.isCloud});

  final String label;

  /// Cloud coaches need the player's own API key and an internet connection.
  final bool isCloud;
}

/// A coach could not produce feedback. [message] is written for the player.
class CoachException implements Exception {
  const CoachException(this.message);

  final String message;

  @override
  String toString() => 'CoachException: $message';
}

/// Turns a clip's measurements into coaching feedback.
abstract interface class CoachProvider {
  CoachProviderKind get kind;

  /// True when the provider can run right now: the local model is
  /// downloaded, or an API key is saved for a cloud provider.
  Future<bool> isAvailable();

  /// Throws [CoachException] when feedback could not be produced.
  Future<CoachFeedback> analyze(TechniqueAnalysis analysis);
}
