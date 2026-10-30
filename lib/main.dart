import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CraveCartApp());
}

class CraveCartApp extends StatelessWidget {
  const CraveCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CraveCart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Keep accessibility text scaling, but cap it so the layout stays intact.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const RootShell(),
    );
  }
}
