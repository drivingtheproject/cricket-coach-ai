import 'package:http/http.dart' as http;

import '../analysis/technique_analysis.dart';
import 'cloud/claude_coach.dart';
import 'cloud/gemini_coach.dart';
import 'cloud/openai_coach.dart';
import 'coach_feedback.dart';
import 'coach_provider.dart';
import 'coach_router.dart';
import 'coach_settings.dart';
import 'rule_based_coach.dart';

/// Feedback and which coach wrote it.
class CoachResult {
  const CoachResult(this.feedback, this.kind);

  final CoachFeedback feedback;
  final CoachProviderKind kind;
}

/// Gets feedback for a clip from the best coach available to the player.
///
/// Order when the player has not picked one: the on-device model, then any
/// cloud coach with a saved key, then the built-in coach. If the chosen coach
/// fails, the built-in coach answers and the feedback says why.
class CoachService {
  CoachService({
    required this.settings,
    required this.client,
    this.localCoach,
    this.fallback = const RuleBasedCoach(),
  });

  final CoachSettings settings;
  final http.Client client;

  /// The on-device coach, when this build has one.
  final CoachProvider? localCoach;
  final CoachProvider fallback;

  List<CoachProvider> providersFor(String userId) {
    Future<String?> key(CoachProviderKind kind) => settings.apiKey(userId, kind);
    Future<String> model(CoachProviderKind kind) =>
        settings.model(userId, kind);
    return [
      if (localCoach != null) localCoach!,
      ClaudeCoach(
        client: client,
        apiKey: () => key(CoachProviderKind.claude),
        model: () => model(CoachProviderKind.claude),
      ),
      OpenAiCoach(
        client: client,
        apiKey: () => key(CoachProviderKind.openAi),
        model: () => model(CoachProviderKind.openAi),
      ),
      GeminiCoach(
        client: client,
        apiKey: () => key(CoachProviderKind.gemini),
        model: () => model(CoachProviderKind.gemini),
      ),
      fallback,
    ];
  }

  Future<CoachResult> feedbackFor(
    String userId,
    TechniqueAnalysis analysis,
  ) async {
    final preferred = await settings.preferred(userId);
    final provider = await CoachRouter(providersFor(userId))
            .pick(preferred: preferred) ??
        fallback;
    try {
      return CoachResult(await provider.analyze(analysis), provider.kind);
    } on CoachException catch (e) {
      if (identical(provider, fallback)) rethrow;
      final feedback = await fallback.analyze(analysis);
      return CoachResult(
        feedback.withNotice(
          '${e.message} The ${fallback.kind.label.toLowerCase()} wrote this '
          'instead.',
        ),
        fallback.kind,
      );
    }
  }
}
