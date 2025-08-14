// lib/screens/no_connection_screen.dart
import 'package:flutter/material.dart';

class NoConnectionScreen extends StatelessWidget {
  const NoConnectionScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // pastel arka plan
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İKON YERİNE PNG: baglantı.png
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    'lib/assets/images/chatbot/baglanti.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bağlantıyı kaybettik! 😴📶',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF364152),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'İnternete tekrar sarılıp geri dönelim mi?\nBir dokunuşla yeniden dene!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF5D6B82),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8AB4F8), // pastel primary
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 1.5,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Yeniden Dene',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
