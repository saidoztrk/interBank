import 'package:flutter/material.dart';
import 'package:interbank/services/session_manager.dart'; // SessionManager sınıfını doğru şekilde import et
//C:\Users\yagmu\rain\interBank\lib\services\session_manager.dart
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  // Flutter servislerini başlatmak için gerekli satır.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uygulama başlamadan önce session ID'yi başlatıyoruz.
  await SessionManager.initialize();

  runApp(const InterBankApp());
}

class InterBankApp extends StatelessWidget {
  const InterBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Session ID'yi kontrol etmek veya kullanmak için.
    // Bu satır sadece konsola yazdırır, ID'yi başka yerlerde de kullanabilirsin.
    print('Uygulama başlatıldı, Session ID: ${SessionManager.sessionId}');

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
