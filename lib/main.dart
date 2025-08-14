import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/login_screen.dart';
import 'screens/no_connection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool hasConnection = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _listenConnectionChanges();
  }

  // İlk açılışta internet kontrolü
  Future<void> _checkConnection() async {
    var result = await Connectivity().checkConnectivity();
    setState(() {
      hasConnection = result != ConnectivityResult.none;
    });
  }

  // Sürekli bağlantı değişimini dinler
  void _listenConnectionChanges() {
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        hasConnection = result != ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobil Bankacılık Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Montserrat',
      ),
      home: hasConnection
          ? const BankStyleLoginScreen()
          : NoConnectionScreen(onRetry: _checkConnection),
    );
  }
}
