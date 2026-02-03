// debug_user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';

final debugUserProvider = Provider((ref) {
  final user = ref.watch(currentUserProvider);
  print('🔍 [DEBUG] User Status: ${user != null ? "EXISTS" : "NULL"}');
  if (user != null) {
    print('🔍 [DEBUG] User Details:');
    print('  UID: ${user.uid}');
    print('  Email: ${user.email}');
    print('  Role: ${user.role}');
    print('  Shop ID: ${user.shopId}');
  }
  return user;
});