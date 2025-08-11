import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Anasayfa',
          style: TextStyle(
            fontFamily: 'Montserrat', // Varsayılan font olarak ayarlanabilir
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Hoş Geldiniz!',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Bu sizin ana ekranınız.',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
