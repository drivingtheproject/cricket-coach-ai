/// A language model that runs on the phone.
abstract interface class OnDeviceLlm {
  /// What the model is called and how big its download is.
  LocalModelInfo get info;

  Future<bool> isInstalled();

  /// Downloads the model. [onProgress] receives 0-100.
  Future<void> install({void Function(int percent)? onProgress});

  Future<void> uninstall();

  /// Runs [prompt] and returns the whole reply.
  Future<String> generate(String prompt, {int maxOutputTokens = 512});
}

class LocalModelInfo {
  const LocalModelInfo({
    required this.name,
    required this.fileName,
    required this.url,
    required this.sizeLabel,
  });

  final String name;
  final String fileName;
  final String url;

  /// Download size as shown to the player, such as "2.4 GB".
  final String sizeLabel;
}

/// Gemma 4 E2B, the smaller of the two on-device Gemma 4 models.
const LocalModelInfo gemma4E2b = LocalModelInfo(
  name: 'Gemma 4 E2B',
  fileName: 'gemma-4-E2B-it.litertlm',
  url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
      'resolve/main/gemma-4-E2B-it.litertlm',
  sizeLabel: '2.4 GB',
);
