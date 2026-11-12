import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../analysis/technique_analysis.dart';
import '../coach_feedback.dart';
import '../coach_prompt.dart';
import '../coach_provider.dart';
import '../feedback_parser.dart';

/// Shared behaviour of the coaches that call a hosted model over HTTPS with
/// the player's own API key.
abstract class CloudCoach implements CoachProvider {
  CloudCoach({
    required this.client,
    required this.apiKey,
    required this.model,
    this.timeout = const Duration(seconds: 45),
  });

  final http.Client client;

  /// Reads the saved key; null or empty when the player has not added one.
  final Future<String?> Function() apiKey;

  /// Reads the model id to use.
  final Future<String> Function() model;
  final Duration timeout;

  /// Builds the HTTP request for [prompt].
  http.Request buildRequest(CoachPrompt prompt, String key, String model);

  /// Pulls the reply text out of a successful response body, or null when it
  /// has none.
  String? extractText(Map<String, dynamic> body);

  @override
  Future<bool> isAvailable() async => (await apiKey())?.isNotEmpty ?? false;

  @override
  Future<CoachFeedback> analyze(TechniqueAnalysis analysis) async {
    final name = kind.label;
    final key = await apiKey();
    if (key == null || key.isEmpty) {
      throw CoachException('Add your $name API key in Settings first.');
    }
    final request =
        buildRequest(buildCoachPrompt(analysis), key, await model());

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await client.send(request).timeout(timeout),
      );
    } on TimeoutException {
      throw CoachException('$name took too long to reply.');
    } on SocketException {
      throw CoachException('$name could not be reached. Check your connection.');
    } on http.ClientException {
      throw CoachException('$name could not be reached. Check your connection.');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 401 || 403:
        throw CoachException(
          '$name rejected the API key. Check it in Settings.',
        );
      case 404:
        throw CoachException(
          '$name does not recognise the model name set in Settings.',
        );
      case 429:
        throw CoachException(
          '$name is limiting requests for this key or it is out of credit.',
        );
      default:
        throw CoachException(
          '$name returned an error (${response.statusCode}).',
        );
    }

    final String? text;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      text = body is Map<String, dynamic> ? extractText(body) : null;
    } on FormatException {
      throw CoachException('$name sent a reply that could not be read.');
    }
    if (text == null || text.trim().isEmpty) {
      throw CoachException('$name sent back an empty reply.');
    }
    return parseCoachFeedback(text);
  }

  /// A JSON POST request.
  static http.Request post(
    Uri url,
    Map<String, String> headers,
    Map<String, Object?> body,
  ) {
    return http.Request('POST', url)
      ..headers.addAll({'content-type': 'application/json', ...headers})
      ..body = jsonEncode(body);
  }
}
