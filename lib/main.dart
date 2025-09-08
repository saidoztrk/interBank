// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/session_manager.dart';
import 'services/api_db_manager.dart';
import 'services/api_service_manager.dart';
import 'providers/db_provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.initialize();

  const dbBase = String.fromEnvironment('DB_BASE_URL');
  if (dbBase.isEmpty) {
    print(
        '[Erenay][MAIN] UyarÄ±: DB_BASE_URL tanÄ±mlÄ± deÄŸil. flutter run --dart-define=DB_BASE_URL=... ile verin.');
  }

  final dbApi = ApiDbManager(dbBase);

  runApp(
    ChangeNotifierProvider<DbProvider>(
      create: (_) => DbProvider(dbApi),
      child: const InterBankApp(),
    ),
  );
}

class InterBankApp extends StatefulWidget {
  const InterBankApp({super.key});

  @override
  State<InterBankApp> createState() => _InterBankAppState();
}

class _InterBankAppState extends State<InterBankApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('[Erenay][MAIN] App build. SessionID=${SessionManager.sessionId}');

    // İlk chat session'ı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Uygulama kapanırken session sonlandır
    _endChatSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // Uygulama arkaplan durumunda session sonlandır
        print('[Erenay][MAIN] App paused - ending chat session');
        _endChatSession();
        break;
      case AppLifecycleState.detached:
        // Uygulama kapatma durumunda session sonlandır
        print('[Erenay][MAIN] App detached - ending chat session');
        _endChatSession();
        break;
      case AppLifecycleState.resumed:
        // Uygulama tekrar aktif olduğunda yeni session başlat
        print('[Erenay][MAIN] App resumed - initializing new chat session');
        _initializeChatSession();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Geçici durumlar için özel işlem yapma
        break;
    }
  }

  void _initializeChatSession() {
    ApiServiceManager.initializeSession().then((sessionId) {
      print('[Erenay][MAIN] Chat session başlatıldı: $sessionId');
    }).catchError((e) {
      print('[Erenay][MAIN] Chat session başlatma hatası: $e');
    });
  }

  void _endChatSession() {
    ApiServiceManager.endSession().then((_) {
      print('[Erenay][MAIN] Chat session sonlandırıldı');
    }).catchError((e) {
      print('[Erenay][MAIN] Chat session sonlandırma hatası: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAPTAN BANK',
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
        '/home': (_) => const HomeScreen(),
        '/chat': (_) => const ChatScreen(),
        '/cards': (_) => const CardsScreen(),
        '/transactions': (_) => const TransactionsScreen(),
      },
    );
  }
}
