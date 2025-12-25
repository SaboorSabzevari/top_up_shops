import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_up_shops/src/presentation/screens/home/home_screen.dart';

import 'package:top_up_shops/src/presentation/theme/colors.dart';
import 'package:top_up_shops/src/utils/colors.dart';

import '../../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String _selectedLanguage = 'fa';

  // ===================== TOP SNACKBAR =====================
  void _showTopSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 40,
        ),
        backgroundColor: kPrimaryColor,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ===================== LOGIN =====================
  Future<void> _loginWithEmail() async {
    final email = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showTopSnackBar('لطفاً ایمیل و رمز عبور را وارد کنید');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'شما هنوز راجستر نشده‌اید';
          break;
        case 'wrong-password':
          message = 'رمز عبور اشتباه است';
          break;
        case 'invalid-email':
          message = 'فرمت ایمیل نادرست است';
          break;
        case 'user-disabled':
          message = 'این حساب غیرفعال شده است';
          break;
        case 'too-many-requests':
          message = 'تعداد تلاش زیاد است، بعداً امتحان کنید';
          break;
        case 'network-request-failed':
          message = 'اتصال اینترنت برقرار نیست';
          break;
        default:
          message = 'خطای نامشخصی رخ داد';
      }

      if (!mounted) return;
      _showTopSnackBar(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Container(
                height: 100,
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.red.shade100,
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 50,
                  color: kPrimaryColor,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                l10n.appTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'برای مدیریت فروشگاه خود وارد شوید',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              _buildLanguageSelector(),

              const SizedBox(height: 30),

              _buildInputField(
                label: 'ایمیل',
                controller: _phoneController,
                isPassword: false,
                icon: Icons.email,
                hintText: 'Ali@gmail.com',
              ),

              const SizedBox(height: 12),

              _buildInputField(
                label: 'رمز عبور',
                controller: _passwordController,
                isPassword: true,
                icon: Icons.lock,
                hintText: '********',
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'ورود به سیستم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.login),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700]),
                  children: [
                    const TextSpan(text: 'حساب کاربری ندارید؟ '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          'تماس با پشتیبانی',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== WIDGETS =====================
  Widget _buildLanguageSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _languageButton(title: 'فارسی', value: 'fa'),
        const SizedBox(width: 12),
        _languageButton(title: 'پشتو', value: 'ps'),
      ],
    );
  }

  Widget _languageButton({required String title, required String value}) {
    final bool isSelected = _selectedLanguage == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.red.shade100 : Colors.grey.shade400,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? kPrimaryColor : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isPassword,
    required IconData icon,
    required String hintText,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (isPassword)
              TextButton(
                onPressed: () {},
                child: Text(
                  'رمز عبور را فراموش کردید؟',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kComponentColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(icon, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
