import 'dart:convert';

import 'coach_feedback.dart';
import 'coach_provider.dart';

/// Reads a model's reply into [CoachFeedback].
///
/// Models are asked for a JSON object but often wrap it in a code fence or a
/// sentence, so the first `{...}` block is used. A reply with no usable JSON
/// becomes the summary. Throws [CoachException] for an empty reply.
CoachFeedback parseCoachFeedback(String reply) {
  final text = reply.trim();
  if (text.isEmpty) {
    throw const CoachException('The coach sent back an empty reply.');
  }

  final json = _firstJsonObject(text);
  if (json != null) {
    final summary = _string(json['summary']);
    final feedback = CoachFeedback(
      summary: summary,
      strengths: _list(json['strengths']),
      improvements: _list(json['improvements']),
      drills: _list(json['drills']),
    );
    final hasContent = summary.isNotEmpty ||
        feedback.strengths.isNotEmpty ||
        feedback.improvements.isNotEmpty;
    if (hasContent) return feedback;
  }
  return CoachFeedback(summary: text);
}

Map<String, dynamic>? _firstJsonObject(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final decoded = jsonDecode(text.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String _string(Object? value) => value is String ? value.trim() : '';

List<String> _list(Object? value) {
  if (value is String) return value.trim().isEmpty ? const [] : [value.trim()];
  if (value is! List) return const [];
  return [
    for (final item in value)
      if ('$item'.trim().isNotEmpty) '$item'.trim(),
  ].take(5).toList();
}
