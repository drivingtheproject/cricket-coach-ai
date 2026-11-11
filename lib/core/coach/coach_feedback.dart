/// Structured coaching feedback, identical in shape whichever model wrote it.
class CoachFeedback {
  const CoachFeedback({
    required this.summary,
    this.strengths = const [],
    this.improvements = const [],
    this.drills = const [],
  });

  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> drills;
}
