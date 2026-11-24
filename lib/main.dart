import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'providers/auth_provider.dart';
import 'providers/iptv_provider.dart';
import 'providers/parental_control_provider.dart';
import 'widgets/tv_navigation_engine.dart';
import 'screens/ios_media_source_screen.dart';
import 'tv/tv_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      MediaKit.ensureInitialized();
    } catch (_) {}
  }

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (_) {}

  runApp(const StandaloneTVApp());
}

class StandaloneTVApp extends StatelessWidget {
  const StandaloneTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IptvProvider()),
        ChangeNotifierProvider(create: (_) => ParentalControlProvider()),
      ],
      child: MaterialApp(
        title: 'Jokar TV - iOS Personal Media Player',
        debugShowCheckedModeBanner: false,
        shortcuts: <ShortcutActivator, Intent>{
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        },
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0B0B0B),
          primaryColor: const Color(0xFFE50914),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE50914),
            secondary: Color(0xFF3B82F6),
            surface: Color(0xFF141414),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return TVAppRoot(child: child ?? const SizedBox.shrink());
        },
        home: const TVAuthGateScreen(),
      ),
    );
  }
}

class TVAuthGateScreen extends StatelessWidget {
  const TVAuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tv_rounded, size: 64, color: Color(0xFFE50914)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFFE50914)),
            ],
          ),
        ),
      );
    }

    if (auth.isLoggedIn) {
      return const TVHomeScreen();
    } else {
      return const IosMediaSourceScreen();
    }
  }
}

class TVAppRoot extends StatelessWidget {
  final Widget child;

  const TVAppRoot({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TVNavigationEngine(
      child: child,
    );
  }
}
