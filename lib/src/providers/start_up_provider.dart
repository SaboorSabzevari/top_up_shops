import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/prefrence_services.dart';
import 'session_provider.dart';

class StartupState {
  final bool isInitialized;
  final String? error;
  final bool isLoading; // اضافه شدن برای مدیریت وضعیت دکمه ریترای

  StartupState({
    this.isInitialized = false,
    this.error,
    this.isLoading = false,
  });

  StartupState copyWith({bool? isInitialized, String? error, bool? isLoading}) {
    return StartupState(
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StartupNotifier extends StateNotifier<StartupState> {
  final Ref ref;
  StartupNotifier(this.ref) : super(StartupState()) {
    initApp();
  }

  // متد برای تلاش مجدد که در UI به آن نیاز دارید
  Future<void> retry() async {
    state = state.copyWith(isLoading: true, error: null);
    await initApp();
  }

  // اصلاح در start_up_provider.dart
  Future<void> initApp() async {
    try {
      final prefs = await ref.read(preferencesServiceProvider.future);
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser != null && prefs.isLoggedIn) {
        UserModel? finalUser;

        try {
          // تلاش برای دریافت از فایربیس
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get(const GetOptions(source: Source.serverAndCache));

          if (doc.exists) {
            final data = doc.data()!;
            finalUser = UserModel(
              uid: currentUser.uid,
              email: currentUser.email ?? '',
              role: data['role'] ?? 'STAFF',
              shopId: data['shopId'] ?? '',
            );

            // 🔴 ذخیره در session provider
            await ref.read(currentUserProvider.notifier).setUser(finalUser!);

            // آپدیت preferences
            await ref
                .read(preferencesServiceProvider.notifier)
                .saveFullLogin(
                  email: finalUser.email,
                  uid: finalUser.uid,
                  role: finalUser.role,
                  shopId: finalUser.shopId,
                  rememberMe: true,
                );
          }
        } catch (e) {
          // استفاده از دیتای ذخیره شده
          if (prefs.userId != null) {
            finalUser = UserModel(
              uid: prefs.userId!,
              email: prefs.userEmail ?? '',
              role: prefs.userRole ?? 'STAFF',
              shopId: prefs.shopId ?? '',
            );

            // 🔴 ذخیره در session provider
            await ref.read(currentUserProvider.notifier).setUser(finalUser!);
          }
        }
      }

      state = StartupState(isInitialized: true);
    } catch (e) {
      state = StartupState(
        isInitialized: false,
        error: "خطا در راه‌اندازی: $e",
      );
    }
  }
}

final startupProvider = StateNotifierProvider<StartupNotifier, StartupState>((
  ref,
) {
  return StartupNotifier(ref);
});
