import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_up_shops/src/presentation/screens/home/home_screen.dart';
import 'package:top_up_shops/src/presentation/theme/colors.dart';
import 'package:top_up_shops/src/providers/auth_provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../providers/local_provider.dart';
import '../../../utils/colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // پر کردن ایمیل ذخیره شده
    _loadSavedEmail();
  }

  void _loadSavedEmail() {
    final authState = ref.read(authProvider);
    if (authState.rememberMe && authState.savedEmail != null) {
      _emailController.text = authState.savedEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final rememberMe = ref.read(authProvider).rememberMe;

    if (email.isEmpty || password.isEmpty) {
      _showTopSnackBar('لطفاً ایمیل و رمز عبور را وارد کنید');
      return;
    }

    try {
      await ref.read(authProvider.notifier).loginWithEmailAndPassword(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      // اگر لاگین موفقیت‌آمیز بود
      if (ref.read(authProvider).isLoggedIn) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      // خطا در provider مدیریت می‌شود
    }
  }

  void _showTopSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kPrimaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final localeState = ref.watch(localeProvider);
    final currentLanguage = localeState.locale.languageCode;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // لوگو
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
                l10n.appSubTitle,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // انتخابگر زبان
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _languageButton(
                    title: 'فارسی',
                    value: 'fa',
                    isSelected: currentLanguage == 'fa',
                    onTap: () => ref.read(localeProvider.notifier).changeLanguage('fa'),
                  ),
                  const SizedBox(width: 12),
                  _languageButton(
                    title: 'پشتو',
                    value: 'ps',
                    isSelected: currentLanguage == 'ps',
                    onTap: () => ref.read(localeProvider.notifier).changeLanguage('ps'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // فیلد ایمیل
              _buildInputField(
                label: l10n.email,
                controller: _emailController,
                isPassword: false,
                icon: Icons.email,
                hintText: 'Ali@gmail.com',
              ),

              const SizedBox(height: 12),

              // فیلد رمز عبور
              _buildInputField(
                label: l10n.password,
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

              // چک‌باکس "مرا به خاطر بسپار"
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: authState.rememberMe,
                      onChanged: (value) {
                        ref.read(authProvider.notifier).toggleRememberMe();
                      },
                      activeColor: kPrimaryColor,
                    ),
                    Text(l10n.memorizeMe),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        l10n.forgotPassword,
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // نمایش خطا
              if (authState.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // دکمه لاگین
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authState.isLoading
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
                    children: [
                      Text(
                        l10n.login,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.login),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // لینک پشتیبانی
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700]),
                  children: [
                     TextSpan(text:l10n.noAccount),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                         l10n.callWithSupport,
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

  Widget _languageButton({
    required String title,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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