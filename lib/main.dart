// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Erenay: local storage & session
import 'services/session_manager.dart';

// Erenay: DB API client + provider
import 'services/api_db_manager.dart';
import 'providers/db_provider.dart';

// Ekranlar
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/cards_screen.dart'; // ✅ yeni import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.initialize();

  // Erenay: DB API base URL – dart-define ile geliyor
  const dbBase = String.fromEnvironment('DB_BASE_URL');
  if (dbBase.isEmpty) {
    // ignore: avoid_print
    print('[Erenay][MAIN] Uyarı: DB_BASE_URL tanımlı değil. '
          'flutter run --dart-define=DB_BASE_URL=... ile verin.');
  }

  final dbApi = ApiDbManager(dbBase);

  runApp(
    ChangeNotifierProvider<DbProvider>(
      create: (_) => DbProvider(dbApi),
      child: const InterBankApp(),
    ),
  );
}

class InterBankApp extends StatelessWidget {
  const InterBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('[Erenay][MAIN] App build. SessionID=${SessionManager.sessionId}');
    return MaterialApp(
      title: 'InterBank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Montserrat',
        colorSchemeSeed: const Color(0xFF0F62FE),
        brightness: Brightness.light,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const BankStyleLoginScreen(),
        '/home' : (_) => const HomeScreen(),
        '/chat' : (_) => const ChatScreen(),
        '/cards': (_) => const CardsScreen(), // ✅ yeni route
      },
    );
  }
}
