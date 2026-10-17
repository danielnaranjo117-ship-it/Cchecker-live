import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repos.dart';
import 'screens/lock.dart';
import 'screens/setup.dart';
import 'screens/shell.dart';
import 'theme.dart';

const appTitle = 'CCheker Live';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Vault.init();
  runApp(const ProviderScope(child: App()));
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: _ready
            ? const ShellScreen()
            : (Vault.hasPin
                ? LockScreen(onUnlock: () => setState(() => _ready = true))
                : SetupScreen(onDone: () => setState(() => _ready = true))),
      );
}
