// lib/qr/qr_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:interbank/qr/qr_intents.dart'; // QRPaymentData & tryParseQrPayment

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1200,
    formats: const [BarcodeFormat.qrCode],
    torchEnabled: false,
    autoStart: true,
  );

  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    final String? code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);

    if (code == null) return;

    final parsed = tryParseQrPayment(code);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçersiz veya desteklenmeyen QR.')),
      );
      return;
    }

    _handled = true;
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.7;
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Oku'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (_, msState, __) {
                final isOn = msState.torchState == TorchState.on;
                return Icon(isOn ? Icons.flash_on : Icons.flash_off);
              },
            ),
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // v7: errorBuilder imzası 2 argüman
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _humanizeError(error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55000000), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'QR’ı çerçeve içine hizalayın',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _humanizeError(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Kamera izni reddedildi. Ayarlardan izin verip tekrar deneyin.';
      case MobileScannerErrorCode.unsupported:
        return 'Bu cihazda kamera/QR okuma desteklenmiyor.';
      case MobileScannerErrorCode.controllerUninitialized:
        return 'Kamera başlatılamadı, lütfen tekrar deneyin.';
      default:
        return 'Kamera hatası: ${error.errorCode.name}';
    }
  }
}
