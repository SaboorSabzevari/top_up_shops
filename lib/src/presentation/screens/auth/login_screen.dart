
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
  bool _hasShownSuccessSnackBar = false;

  @override
  void initState() {
    super.initState();
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

  // ================= SNACKBAR =================

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    IconData? icon,
    int durationSeconds = 3,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: durationSeconds),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LOGIN =================

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final rememberMe = ref.read(authProvider).rememberMe;

    // اعتبارسنجی فیلدها
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        message: 'لطفاً ایمیل و رمز عبور را وارد کنید',
        backgroundColor: Colors.red.shade600,
        icon: Icons.error_outline,
        durationSeconds: 3,
      );
      return;
    }

    try {
      // ریست کردن فلگ
      _hasShownSuccessSnackBar = false;

      // فراخوانی لاگین
      await ref.read(authProvider.notifier).loginWithEmailAndPassword(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      // کمی تأخیر برای به‌روزرسانی state
      await Future.delayed(const Duration(milliseconds: 300));

      final authState = ref.read(authProvider);

      // بررسی موفقیت‌آمیز بودن لاگین
      if (authState.isLoggedIn && !_hasShownSuccessSnackBar) {
        _hasShownSuccessSnackBar = true;

        // نمایش اسنک‌بار موفقیت
        _showSnackBar(
          message: 'ورود با موفقیت انجام شد ',
          backgroundColor: Colors.green.shade600,
          icon: Icons.check_circle_outline,
          durationSeconds: 2,
        );

        // تأخیر برای نمایش اسنک‌بار قبل از ناوبری
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // ناوبری به صفحه اصلی
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
        );
      }
    } catch (_) {
      // خواندن خطا از provider
      final authState = ref.read(authProvider);
      final errorMessage = authState.error ?? 'خطا در ورود، دوباره تلاش کنید';

      // نمایش اسنک‌بار خطا
      _showSnackBar(
        message: errorMessage,
        backgroundColor: Colors.red.shade600,
        icon: Icons.error_outline,
        durationSeconds: 4,
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final localeState = ref.watch(localeProvider);
    final currentLanguage = localeState.locale.languageCode;

    // گوش دادن به تغییرات auth state برای نمایش خطاها
    ref.listen<AuthState>(authProvider, (previous, current) {
      // نمایش خطاها به صورت خودکار (اگر خطای جدیدی وجود داشته باشد)
      if (current.error != null &&
          current.error!.isNotEmpty &&
          (previous == null || previous.error != current.error)) {

        // تأخیر برای اطمینان از mount بودن
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _showSnackBar(
              message: current.error!,
              backgroundColor: Colors.red.shade600,
              icon: Icons.error_outline,
              durationSeconds: 4,
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // LOGO
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

              // LANGUAGE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _languageButton(
                    title: 'فارسی',
                    isSelected: currentLanguage == 'fa',
                    onTap: () => ref
                        .read(localeProvider.notifier)
                        .changeLanguage('fa'),
                  ),
                  const SizedBox(width: 12),
                  _languageButton(
                    title: 'پشتو',
                    isSelected: currentLanguage == 'ps',
                    onTap: () => ref
                        .read(localeProvider.notifier)
                        .changeLanguage('ps'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildInputField(
                label: l10n.email,
                controller: _emailController,
                icon: Icons.email,
                hintText: 'ایمیل خود را وارد کنید',
                isPassword: false,
              ),

              const SizedBox(height: 12),

              _buildInputField(
                label: l10n.password,
                controller: _passwordController,
                icon: Icons.lock,
                hintText: 'گذرواژه خود را وارد کنبد',
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: authState.rememberMe,
                      activeColor: kPrimaryColor,
                      onChanged: (_) {
                        ref
                            .read(authProvider.notifier)
                            .toggleRememberMe();
                      },
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700]),
                  children: [
                    TextSpan(text: l10n.noAccount),
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

  // ================= WIDGETS =================

  Widget _languageButton({
    required String title,
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
    required IconData icon,
    required String hintText,
    required bool isPassword,
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
              hintStyle: TextStyle(
                color: Colors.grey
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
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