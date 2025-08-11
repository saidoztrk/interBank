import 'package:flutter/material.dart';
import 'package:interbank/utils/colors.dart'; // Renk paletimizi import ediyoruz
import 'home_screen.dart'; // Giriş yapınca gidilecek ekranı import ediyoruz

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true; // Şifre gizleme için

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        // Klavye açıldığında taşmayı önler
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
              ), // Üst boşluk
              // Uygulama logosu veya adı
              const Text(
                'Mobil Bankacılık Uygulaması',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // Kullanıcı Adı Giriş Alanı
              _buildTextField(
                controller: _usernameController,
                label: 'Kullanıcı Adı',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              // Şifre Giriş Alanı
              _buildTextField(
                controller: _passwordController,
                label: 'Şifre',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),
              // Giriş Yap Butonu
              ElevatedButton(
                onPressed: () {
                  // Buraya giriş mantığı gelecek
                  // Şimdilik ana sayfaya yönlendiriyoruz
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Şifremi Unuttum linki
              TextButton(
                onPressed: () {
                  // Şifremi unuttum sayfasına yönlendirme
                },
                child: const Text(
                  'Şifremi Unuttum?',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ortak TextField bileşeni
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.secondaryTextColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.secondaryTextColor,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.cardBackground,
      ),
      style: const TextStyle(color: AppColors.textColor),
    );
  }
}
