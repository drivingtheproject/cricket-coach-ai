import '../settings/secret_store.dart';
import '../settings/settings_repository.dart';
import 'cloud/claude_coach.dart';
import 'cloud/gemini_coach.dart';
import 'cloud/openai_coach.dart';
import 'coach_provider.dart';

/// A player's coach choices: which coach they prefer, their API keys (kept
/// in secure storage, never in the database) and model names.
class CoachSettings {
  const CoachSettings({required this.settings, required this.secrets});

  final SettingsRepository settings;
  final SecretStore secrets;

  static const String _preferredKey = 'coach.preferred';

  static String defaultModel(CoachProviderKind kind) => switch (kind) {
        CoachProviderKind.claude => ClaudeCoach.defaultModel,
        CoachProviderKind.openAi => OpenAiCoach.defaultModel,
        CoachProviderKind.gemini => GeminiCoach.defaultModel,
        CoachProviderKind.localGemma || CoachProviderKind.builtIn => '',
      };

  /// The coach the player picked, or null for "choose automatically".
  Future<CoachProviderKind?> preferred(String userId) async {
    final name = await settings.get(userId, _preferredKey);
    for (final kind in CoachProviderKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }

  Future<void> setPreferred(String userId, CoachProviderKind? kind) async {
    if (kind == null) {
      await settings.remove(userId, _preferredKey);
    } else {
      await settings.set(userId, _preferredKey, kind.name);
    }
  }

  Future<String?> apiKey(String userId, CoachProviderKind kind) =>
      secrets.read(_secretName(userId, kind));

  /// Saves the key; an empty key removes it.
  Future<void> setApiKey(
    String userId,
    CoachProviderKind kind,
    String key,
  ) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await secrets.delete(_secretName(userId, kind));
    } else {
      await secrets.write(_secretName(userId, kind), trimmed);
    }
  }

  Future<String> model(String userId, CoachProviderKind kind) async =>
      await settings.get(userId, _modelKey(kind)) ?? defaultModel(kind);

  /// Saves the model name; an empty name goes back to the default.
  Future<void> setModel(
    String userId,
    CoachProviderKind kind,
    String model,
  ) async {
    final trimmed = model.trim();
    if (trimmed.isEmpty || trimmed == defaultModel(kind)) {
      await settings.remove(userId, _modelKey(kind));
    } else {
      await settings.set(userId, _modelKey(kind), trimmed);
    }
  }

  static String _modelKey(CoachProviderKind kind) => 'coach.model.${kind.name}';

  static String _secretName(String userId, CoachProviderKind kind) =>
      'api_key.$userId.${kind.name}';
}
