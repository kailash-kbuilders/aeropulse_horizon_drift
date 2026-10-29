import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Entry point.
///
/// This is intentionally a placeholder home screen: the real game (3D scene
/// inside a WebView, HUD, menus) is built once the PRD is in. What is already
/// wired here is the orientation policy — the game is landscape-only, so the
/// app locks to landscape and hides the system UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const NewProjectApp());
}

class NewProjectApp extends StatelessWidget {
  const NewProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5)),
      ),
      home: const Scaffold(
        backgroundColor: Color(0xFF10131A),
        body: Center(
          child: Text(
            'Project ready',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
      ),
    );
  }
}
