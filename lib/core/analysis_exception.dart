/// A clip could not be analysed. [message] is written for the user and says
/// what to do next.
class AnalysisException implements Exception {
  const AnalysisException(this.message);

  final String message;

  @override
  String toString() => 'AnalysisException: $message';
}
