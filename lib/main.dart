import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The game is landscape-only: lock it here and hide the system chrome.
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const AeroPulseApp());
}

class AeroPulseApp extends StatelessWidget {
  const AeroPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameState>(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'AeroPulse: Horizon Drift',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF22D3EE),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF05070D),
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
