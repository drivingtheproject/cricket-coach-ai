import 'package:material_ui/material_ui.dart';

import '../../widgets/empty_state.dart';
import 'session_detail_page.dart';
import 'session_list_builder.dart';
import 'session_tile.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: SessionListBuilder(
        builder: (context, sessions) {
          if (sessions.isEmpty) {
            return const Align(
              alignment: Alignment.topLeft,
              child: EmptyState(
                icon: Icons.video_library_outlined,
                title: 'No sessions yet',
                message: 'Every clip you analyse is saved here to review later.',
              ),
            );
          }
          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(indent: 20, endIndent: 20),
            itemBuilder: (context, index) => SessionTile(
              session: sessions[index],
              onTap: () => openSession(context, sessions[index].id),
            ),
          );
        },
      ),
    );
  }
}
