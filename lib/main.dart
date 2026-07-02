import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const WalletShellApp());
}
