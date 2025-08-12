import 'package:flutter/material.dart';

class SubesizIslemEkrani extends StatelessWidget {
  const SubesizIslemEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Şubesiz İşlemler",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(Icons.account_balance, "Hesap Aç"),
            _buildCard(Icons.attach_money, "Para Çek"),
            _buildCard(Icons.send, "Para Gönder"),
            _buildCard(Icons.credit_card, "Kredi Başvurusu"),
            _buildCard(Icons.mobile_friendly, "Mobil Ödeme"),
            _buildCard(Icons.help_outline, "Yardım"),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: null, // pasif
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue[800]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SubesizIslemEkrani(),
  ));
}
