import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';

// Couleurs Online Ink Solutions
class OIS {
  static const red = Color(0xFFE2231A);
  static const black = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const green = Color(0xFF18C957);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ApiService.load();
    await NotificationService.init();
  } catch (_) {
    // Ne jamais bloquer le demarrage de l'application.
  }

  runApp(const OISApp());
}

class OISApp extends StatelessWidget {
  const OISApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: OIS.red,
        primary: OIS.red,
        secondary: OIS.black,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: OIS.black,
        foregroundColor: OIS.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: OIS.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OIS.red,
          foregroundColor: OIS.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'OIS Orders Mobile',
      debugShowCheckedModeBanner: false,
      theme: base,
      home: ApiService.isLoggedIn
          ? const OrdersScreen()
          : const LoginScreen(),
    );
  }
}
