import 'package:material_ui/material_ui.dart';

import '../../core/coach/local/model_download_controller.dart';
import '../../widgets/section_title.dart';

/// Download, progress and removal of the on-device model.
class LocalModelSection extends StatelessWidget {
  const LocalModelSection({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final ModelDownloadController controller;

  /// Called after the model is installed or removed.
  final VoidCallback? onChanged;

  Future<void> _download() async {
    await controller.download();
    onChanged?.call();
  }

  Future<void> _remove() async {
    await controller.remove();
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = controller.llm.info;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final error = controller.error;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('On-device model'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${info.name} writes feedback on this phone, offline, '
                    'with nothing sent anywhere. It is a ${info.sizeLabel} '
                    'download and suits recent phones with 8 GB of memory or '
                    'more.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...switch (controller.status) {
                    ModelStatus.checking => const [
                        LinearProgressIndicator(),
                      ],
                    ModelStatus.notInstalled => [
                        FilledButton.tonal(
                          key: const Key('model-download'),
                          onPressed: _download,
                          child: Text('Download ${info.sizeLabel} model'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use Wi-Fi and keep the app open while it '
                          'downloads.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ModelStatus.downloading => [
                        LinearProgressIndicator(
                          value: controller.percent / 100,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Downloading, ${controller.percent}%',
                          key: const Key('model-progress'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ModelStatus.installed => [
                        Text(
                          'Downloaded and ready.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const Key('model-remove'),
                          onPressed: _remove,
                          child: const Text('Remove model'),
                        ),
                      ],
                  },
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      key: const Key('model-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
