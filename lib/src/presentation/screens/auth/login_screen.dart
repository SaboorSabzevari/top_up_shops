import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // اضافه کردن این خط
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
        margin: EdgeInsets.all(16.r), // ریسپانسیو
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
        ),
        duration: Duration(seconds: durationSeconds),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              SizedBox(width: 10.w), // ریسپانسیو
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp, // ریسپانسیو
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

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        message: 'لطفاً ایمیل و رمز عبور را وارد کنید',
        backgroundColor: Colors.red.shade600,
        icon: Icons.error_outline,
      );
      return;
    }

    try {
      _hasShownSuccessSnackBar = false;

      await ref
          .read(authProvider.notifier)
          .loginWithEmailAndPassword(
            email: email,
            password: password,
            rememberMe: rememberMe,
          );

      if (!mounted) return;

      final authState = ref.read(authProvider);

      if (authState.isLoggedIn && !_hasShownSuccessSnackBar) {
        _hasShownSuccessSnackBar = true;

        _showSnackBar(
          message: 'ورود با موفقیت انجام شد',
          backgroundColor: Colors.green.shade600,
          icon: Icons.check_circle_outline,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      } else if (authState.error != null) {
        _showSnackBar(
          message: authState.error!,
          backgroundColor: Colors.red.shade600,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        message: 'خطای غیرمنتظره: $e',
        backgroundColor: Colors.red.shade600,
        icon: Icons.error_outline,
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    // مقداردهی اولیه ScreenUtil
    ScreenUtil.init(
      context,
      designSize: const Size(360, 800),
    ); // اندازه طراحی مورد نظر

    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final localeState = ref.watch(localeProvider);
    final currentLanguage = localeState.locale.languageCode;

    ref.listen<AuthState>(authProvider, (previous, current) {
      if (current.error != null &&
          current.error!.isNotEmpty &&
          (previous == null || previous.error != current.error)) {
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
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 40.h,
          ), // ریسپانسیو
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h), // ریسپانسیو
              // LOGO
              Container(
                height: 100.h, // ریسپانسیو
                width: 100.w, // ریسپانسیو
                padding: EdgeInsets.all(12.r), // ریسپانسیو
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.r), // ریسپانسیو
                  color: Colors.red.shade100,
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 50.sp, // ریسپانسیو
                  color: kPrimaryColor,
                ),
              ),

              SizedBox(height: 20.h), // ریسپانسیو

              Text(
                l10n.appTitle,
                style: TextStyle(
                  fontSize: 24.sp, // ریسپانسیو
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8.h), // ریسپانسیو

              Text(
                l10n.appSubTitle,
                style: TextStyle(
                  fontSize: 16.sp, // ریسپانسیو
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h), // ریسپانسیو
              // LANGUAGE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _languageButton(
                    title: 'فارسی',
                    isSelected: currentLanguage == 'fa',
                    onTap: () =>
                        ref.read(localeProvider.notifier).changeLanguage('fa'),
                  ),
                  SizedBox(width: 12.w), // ریسپانسیو
                  _languageButton(
                    title: 'پشتو',
                    isSelected: currentLanguage == 'ps',
                    onTap: () =>
                        ref.read(localeProvider.notifier).changeLanguage('ps'),
                  ),
                ],
              ),

              SizedBox(height: 30.h), // ریسپانسیو

              _buildInputField(
                label: l10n.email,
                controller: _emailController,
                icon: Icons.email,
                hintText: 'ایمیل خود را وارد کنید',
                isPassword: false,
              ),

              SizedBox(height: 12.h), // ریسپانسیو

              _buildInputField(
                label: l10n.password,
                controller: _passwordController,
                icon: Icons.lock,
                hintText: 'گذرواژه خود را وارد کنید',
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                trailing: GestureDetector(
                  onTap: () {
                    // عملیات فراموشی رمز
                  },
                  child: Text(
                    l10n.forgotPassword,
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 12.sp, // ریسپانسیو
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h), // ریسپانسیو
                child: Row(
                  children: [
                    Checkbox(
                      value: authState.rememberMe,
                      activeColor: kPrimaryColor,
                      onChanged: (_) {
                        ref.read(authProvider.notifier).toggleRememberMe();
                      },
                    ),
                    Text(
                      l10n.memorizeMe,
                      style: TextStyle(fontSize: 14.sp), // ریسپانسیو
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h), // ریسپانسیو

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h), // ریسپانسیو
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
                    ),
                  ),
                  child: authState.isLoading
                      ? SizedBox(
                          height: 24.h, // ریسپانسیو
                          width: 24.w, // ریسپانسیو
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
                              style: TextStyle(
                                fontSize: 18.sp, // ریسپانسیو
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8.w), // ریسپانسیو
                            Icon(Icons.login, size: 20.sp), // ریسپانسیو
                          ],
                        ),
                ),
              ),

              SizedBox(height: 25.h), // ریسپانسیو

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14.sp, // ریسپانسیو
                  ),
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
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 10.h,
        ), // ریسپانسیو
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r), // ریسپانسیو
          border: Border.all(
            color: isSelected ? Colors.red.shade100 : Colors.grey.shade400,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? kPrimaryColor : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp, // ریسپانسیو
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
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp, // ریسپانسیو
                fontWeight: FontWeight.bold,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        SizedBox(height: 8.h), // ریسپانسیو
        Container(
          decoration: BoxDecoration(
            color: kComponentColor,
            borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp, // ریسپانسیو
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ), // ریسپانسیو
              prefixIcon: Icon(icon, size: 20.sp), // ریسپانسیو
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20.sp, // ریسپانسیو
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
