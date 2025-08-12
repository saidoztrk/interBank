import 'package:flutter/material.dart';

// İleride oluşturacağımız ekranları buraya import edeceğiz
import 'screens/login_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobil Bankacılık Uygulaması',
      theme: ThemeData(
        // Tasarımınızdaki renklere göre burayı güncelleyelim
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50], // Açık gri bir arka plan
        fontFamily: 'Montserrat', // Varsayılan font
      ),
      home:
          const BankStyleLoginScreen(), // Uygulama başladığında giriş ekranı açılacak
    );
  }
}