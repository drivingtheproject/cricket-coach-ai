import 'dart:convert';

/// Structured coaching feedback, identical in shape whichever coach wrote it.
class CoachFeedback {
  const CoachFeedback({
    required this.summary,
    this.strengths = const [],
    this.improvements = const [],
    this.drills = const [],
    this.notice,
  });

  factory CoachFeedback.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    List<String> list(String key) =>
        [for (final item in json[key] as List<dynamic>? ?? const []) '$item'];
    return CoachFeedback(
      summary: json['summary'] as String? ?? '',
      strengths: list('strengths'),
      improvements: list('improvements'),
      drills: list('drills'),
      notice: json['notice'] as String?,
    );
  }

  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> drills;

  /// Set when the coach the player chose could not be used and another one
  /// wrote this instead; says why.
  final String? notice;

  CoachFeedback withNotice(String notice) => CoachFeedback(
        summary: summary,
        strengths: strengths,
        improvements: improvements,
        drills: drills,
        notice: notice,
      );

  String encode() => jsonEncode({
        'summary': summary,
        'strengths': strengths,
        'improvements': improvements,
        'drills': drills,
        if (notice != null) 'notice': notice,
      });
}
