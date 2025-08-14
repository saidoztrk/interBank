import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InterBankApp());
}

class InterBankApp extends StatelessWidget {
  const InterBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InterBank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Montserrat',
        colorSchemeSeed: const Color(0xFF0F62FE),
        brightness: Brightness.light,
      ),
      // Uygulama login ekranıyla başlasın
      initialRoute: '/login',
      routes: {
        '/login': (_) => const BankStyleLoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/chat': (_) => const ChatScreen(),
      },
    );
  }
}
