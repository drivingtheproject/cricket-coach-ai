import 'coach_provider.dart';

/// Chooses which coach provider handles a request (the "hybrid" part).
///
/// The user's preferred provider wins when it is available. Otherwise the
/// first available provider in [providers] order is used, so list the local
/// model first to default to offline.
class CoachRouter {
  const CoachRouter(this.providers);

  final List<CoachProvider> providers;

  /// Returns null when no provider is available.
  Future<CoachProvider?> pick({CoachProviderKind? preferred}) async {
    if (preferred != null) {
      for (final provider in providers) {
        if (provider.kind == preferred && await provider.isAvailable()) {
          return provider;
        }
      }
    }
    for (final provider in providers) {
      if (await provider.isAvailable()) return provider;
    }
    return null;
  }
}
