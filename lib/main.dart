import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'providers/auth_provider.dart';
import 'providers/iptv_provider.dart';
import 'providers/parental_control_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/tv_global_focus_root.dart';
import 'widgets/tv_key_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      MediaKit.ensureInitialized();
    } catch (_) {}
  }
  
  // Set preferred orientation to landscape only
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (_) {}

  runApp(const SmartIptvApp());
}

class SmartIptvApp extends StatelessWidget {
  const SmartIptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IptvProvider()),
        ChangeNotifierProvider(create: (_) => ParentalControlProvider()),
      ],
      child: MaterialApp(
        title: 'Smart IPTV',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => TVKeyHandler(
          onKeyPressed: (key) {},
          child: TvGlobalFocusRoot(child: child ?? const SizedBox.shrink()),
        ),
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
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
              Image.asset(
                'smartiptv_source/app/src/main/res/drawable/app_logo.png',
                height: 90,
                cacheWidth: 300,
                cacheHeight: 300,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'JOKER TV',
                  style: TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFFE50914)),
            ],
          ),
        ),
      );
    }

    if (auth.isLoggedIn) {
      return const DashboardScreen();
    } else if (auth.showLogin) {
      return const LoginScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}
