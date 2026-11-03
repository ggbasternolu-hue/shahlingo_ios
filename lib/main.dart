import 'package:flutter/material.dart';

import 'app.dart';
import 'state/player_progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = PlayerProgress();
  runApp(ShahlingoApp(progress: progress));
  await progress.load();
}
