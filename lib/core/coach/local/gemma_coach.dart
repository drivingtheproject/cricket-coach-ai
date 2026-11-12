import '../../analysis/technique_analysis.dart';
import '../coach_feedback.dart';
import '../coach_prompt.dart';
import '../coach_provider.dart';
import '../feedback_parser.dart';
import 'on_device_llm.dart';

/// Coach backed by a model running on the phone: works offline and nothing
/// leaves the device.
class GemmaCoach implements CoachProvider {
  const GemmaCoach(this.llm);

  final OnDeviceLlm llm;

  @override
  CoachProviderKind get kind => CoachProviderKind.localGemma;

  @override
  Future<bool> isAvailable() async {
    try {
      return await llm.isInstalled();
    } on Exception {
      return false;
    }
  }

  @override
  Future<CoachFeedback> analyze(TechniqueAnalysis analysis) async {
    final String reply;
    try {
      reply = await llm.generate(buildCoachPrompt(analysis).combined);
    } on Exception {
      throw CoachException(
        '${llm.info.name} could not run on this phone. It may not have '
        'enough free memory.',
      );
    }
    return parseCoachFeedback(reply);
  }
}
