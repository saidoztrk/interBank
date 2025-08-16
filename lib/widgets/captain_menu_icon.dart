import 'dart:async';
import 'package:flutter/material.dart';

/// Asistan gizliyken (active=true) şapka "alttan bakıyor" animasyonu oynatır.
/// Asistan görünürken (active=false) normal hamburger menü ikonu gösterir.
class CaptainMenuIcon extends StatefulWidget {
  final bool active; // asistan gizli mi? true => peek animasyonu
  final double size; // ikon boyutu (BottomNavigation için 26~30 ideal)
  final Color? color; // hamburger ikon rengi (active=false iken)

  const CaptainMenuIcon({
    super.key,
    required this.active,
    this.size = 28,
    this.color,
  });

  @override
  State<CaptainMenuIcon> createState() => _CaptainMenuIconState();
}

class _CaptainMenuIconState extends State<CaptainMenuIcon> {
  // Animasyon frameleri
  late final List<ImageProvider> _frames;
  Timer? _timer;
  int _i = 0;
  bool _goingUp = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Frame’leri yükle + önbelleğe al (didChangeDependencies içinde context hazır)
    _frames = const [
      AssetImage('lib/assets/images/captain/hat/hat_peek_0.png'),
      AssetImage('lib/assets/images/captain/hat/hat_peek_1.png'),
      AssetImage('lib/assets/images/captain/hat/hat_peek_2.png'),
      AssetImage('lib/assets/images/captain/hat/hat_peek_3.png'),
    ];
    for (final f in _frames) {
      precacheImage(f, context);
    }
    precacheImage(
      const AssetImage('lib/assets/images/captain/hat/hat_idle.png'),
      context,
    );
    _restartIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CaptainMenuIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _restartIfNeeded();
    }
  }

  void _restartIfNeeded() {
    _timer?.cancel();
    _i = 0;
    _goingUp = true;

    if (!widget.active) {
      setState(() {});
      return;
    }

    // 2 turda bir küçük bekleme verelim (daha doğal dursun)
    int cycles = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      setState(() {
        // 0->1->2->3->2->1->0 şeklinde gitsin
        if (_goingUp) {
          if (_i < _frames.length - 1) {
            _i++;
          } else {
            _goingUp = false;
          }
        } else {
          if (_i > 0) {
            _i--;
          } else {
            _goingUp = true;
            cycles++;
            // 2 tam salınımda 900ms dur
            if (cycles % 2 == 0) {
              _timer?.cancel();
              Future.delayed(
                  const Duration(milliseconds: 900), _restartIfNeeded);
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    if (!widget.active) {
      // Asistan görünür: klasik hamburger ikonu
      return Icon(Icons.menu_rounded, size: s, color: widget.color);
    }

    // Asistan gizli: peek animasyonu
    return Image(
      image: _frames[_i],
      width: s,
      height: s,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
