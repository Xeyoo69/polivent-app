import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_navigator.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PoliVentApp());
}

class PoliVentApp extends StatefulWidget {
  const PoliVentApp({super.key});

  @override
  State<PoliVentApp> createState() => _PoliVentAppState();
}

class _PoliVentAppState extends State<PoliVentApp> {
  @override
  void initState() {
    super.initState();

    // Token tidak valid (401) -> hapus session & kembali ke Login.
    ApiService.onUnauthorized = AuthService.instance.handleUnauthorized;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoliVent',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      // Selalu mulai dari Splash. Tanpa ini, Flutter web bisa "deep link"
      // dari URL hash (mis. /#/admin) dan menumpuk Splash di bawah halaman
      // sehingga muncul tombol back yang tidak perlu.
      onGenerateInitialRoutes: (initialRoute) => [
        MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
      ],
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.home: (context) => const MainShell(),
        AppRoutes.admin: (context) => const AdminShell(),
      },
    );
  }
}
