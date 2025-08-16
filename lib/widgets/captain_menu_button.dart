import 'package:flutter/material.dart';
import 'captain_menu_icon.dart';

class CaptainMenuButton extends StatelessWidget {
  final bool assistantHidden; // gizliyse animasyon oynar
  final VoidCallback onTap; // kısa dokunuş: menü sheet
  final VoidCallback onLongPress; // uzun basış: asistan toggle

  const CaptainMenuButton({
    super.key,
    required this.assistantHidden,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: Colors.black12,
        radius: 44,
        child: Container(
          width: 68, // daire çapı (büyüklük burada)
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 10,
                  offset: Offset(0, 6)),
            ],
            border: Border.all(color: const Color(0xFFE9EEF6), width: 1),
          ),
          alignment: Alignment.center,
          child: CaptainMenuIcon(
            active: assistantHidden,
            size: 40, // şapka boyutu (buton içinde büyük)
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
