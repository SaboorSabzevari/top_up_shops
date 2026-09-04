// مسیر پیشنهادی: lib/src/utils/app_notifier.dart
//
// ۱) AppToast: یک toast عمومیِ یکسان برای کل اپ (۳ ثانیه، بالای همه چیز،
//    قابل استفاده از هر جای اپ بدون نیاز به context محلی).
// ۲) AppLoader: یک لودینگ تمام‌صفحه‌ی شفاف که هنگام هر عملیات شبکه‌ای
//    نمایش داده می‌شود تا کاربر فکر نکند اپ هنگ کرده یا عملیات لغو شده.
//
// هر دو از appNavigatorKey استفاده می‌کنند، پس باید در main.dart این خط
// را به MaterialApp اضافه کنید:  navigatorKey: appNavigatorKey

import 'dart:async';
import 'package:flutter/material.dart';
import 'app_navigation.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
      String message, {
        ToastType type = ToastType.info,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlayState = appNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    // اگر toast قبلی هنوز روی صفحه است، اول آن را بردار
    _dismiss();

    final entry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message, type: type),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void success(String message) => show(message, type: ToastType.success);
  static void error(String message) => show(message, type: ToastType.error);
  static void info(String message) => show(message, type: ToastType.info);
  static void warning(String message) => show(message, type: ToastType.warning);
}

class _ToastWidget extends StatelessWidget {
  final String message;
  final ToastType type;

  const _ToastWidget({required this.message, required this.type});

  Color get _bgColor {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF2E7D32);
      case ToastType.error:
        return const Color(0xFFC62828);
      case ToastType.warning:
        return const Color(0xFFEF6C00);
      case ToastType.info:
        return const Color(0xFF1B0E0E);
    }
  }

  IconData get _icon {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// لودینگ تمام‌صفحه‌ی مسدودکننده — برای هر عملیاتی که با شبکه/Firestore
/// کار دارد استفاده شود تا کاربر منتظر بماند و فکر نکند عملیات لغو شده.
class AppLoader {
  static OverlayEntry? _entry;
  static int _refCount = 0; // برای عملیات‌های تودرتو

  static void show([String? message]) {
    _refCount++;
    if (_entry != null) return; // از قبل نمایش داده شده

    final overlayState = appNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _entry = OverlayEntry(
      builder: (context) => _LoaderWidget(message: message),
    );
    overlayState.insert(_entry!);
  }

  static void hide() {
    _refCount = (_refCount - 1).clamp(0, 999);
    if (_refCount > 0) return;
    _entry?.remove();
    _entry = null;
  }

  /// برای مواقع اضطراری (مثلاً بعد از خطای غیرمنتظره) که می‌خواهید مطمئن
  /// شوید لودر حتماً بسته می‌شود.
  static void forceHide() {
    _refCount = 0;
    _entry?.remove();
    _entry = null;
  }
}

class _LoaderWidget extends StatelessWidget {
  final String? message;
  const _LoaderWidget({this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withOpacity(0.25),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFEA2A33)),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Text(message!, style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}