import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create();
  runApp(CricketCoachApp(services: services));
}
