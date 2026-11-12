import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import '../on_device_llm.dart';

/// Runs Gemma on the phone through LiteRT-LM (the flutter_edge_ai plugin).
class EdgeAiLlm implements OnDeviceLlm {
  EdgeAiLlm({this.info = gemma4E2b});

  @override
  final LocalModelInfo info;

  Future<void>? _initialised;

  Future<void> _ready() => _initialised ??= FlutterEdgeAi.initialize(
        inferenceEngines: const [LiteRtLmEngine()],
      );

  @override
  Future<bool> isInstalled() async {
    await _ready();
    return FlutterEdgeAi.isModelInstalled(info.fileName);
  }

  @override
  Future<void> install({void Function(int percent)? onProgress}) async {
    await _ready();
    await FlutterEdgeAi.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    )
        .fromNetwork(info.url)
        .withProgress((progress) => onProgress?.call(progress))
        .install();
  }

  @override
  Future<void> uninstall() async {
    await _ready();
    await FlutterEdgeAi.uninstallModel(info.fileName);
  }

  @override
  Future<String> generate(String prompt, {int maxOutputTokens = 512}) async {
    await _ready();
    // The context window has to hold the prompt and the reply.
    final model = await FlutterEdgeAi.getActiveModel(maxTokens: 2048);
    try {
      final chat = await model.createChat(maxOutputTokens: maxOutputTokens);
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final reply = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) reply.write(response.token);
      }
      return reply.toString();
    } finally {
      // Frees the model's memory (around 2 GB) as soon as the reply is done.
      await model.close();
    }
  }
}
