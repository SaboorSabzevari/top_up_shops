// مسیر پیشنهادی: lib/src/providers/permission_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_provider.dart';

/// استفاده در UI:
///   final canBuy = ref.watch(hasPermissionProvider(PermissionKeys.canManageInventory));
///   if (canBuy) ... نمایش دکمه ...
final hasPermissionProvider = Provider.family<bool, String>((ref, key) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.hasPermission(key);
});

final isOwnerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isOwner ?? false;
});