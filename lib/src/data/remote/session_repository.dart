import '../../services/session_service.dart';
import 'firestore_service.dart';

class SessionRepository {
  final FirestoreService _fs;

  SessionRepository({FirestoreService? firestoreService})
      : _fs = firestoreService ?? FirestoreService();

  Future<SessionInfo?> loadSession(String uid) async {
    final userSnap = await _fs.userDoc(uid).get();
    if (!userSnap.exists) return null;
    final userData = userSnap.data()!;
    final shopId = userData['shopId'] as String?;
    final roleId = userData['roleId'] as String?;
    final employeeId = userData['employeeId'] as String? ?? uid;
    if (shopId == null || roleId == null) return null;

    final shopSnap = await _fs.shopDoc(shopId).get();
    final shopData = shopSnap.data() ?? {};
    final subscription = shopData['subscription'] as Map<String, dynamic>?;
    final settings = shopData['settings'] as Map<String, dynamic>? ?? {};
    final flatStatus = shopData['subscription_status'] as String?;
    final flatExpiryMs = shopData['subscription_expiry_ms'] as int?;

    final roleSnap = await _fs.shopSubDoc(shopId, 'roles', roleId).get();
    final roleData = roleSnap.data() ?? {};
    final permissionsList = (roleData['permissions'] as List?)?.cast<String>() ?? [];
    final permissions = <String, bool>{
      for (final p in permissionsList) p: true,
    };

    return SessionInfo(
      shopId: shopId,
      employeeId: employeeId,
      roleId: roleId,
      shopName: shopData['name'] as String? ?? 'فروشگاه من',
      subscriptionActive: _resolveActive(subscription, flatStatus, flatExpiryMs),
      subscriptionExpiry: _resolveExpiry(subscription, flatExpiryMs),
      allowViewOnExpired: settings['allowViewOnExpired'] as bool? ?? true,
      permissions: permissions,
    );
  }

  bool _resolveActive(Map<String, dynamic>? subscription, String? flatStatus, int? flatExpiryMs) {
    if (subscription != null) {
      return (subscription['status'] as String? ?? 'active') == 'active' &&
          _isNotExpired(subscription['expiryDate']);
    }
    final status = flatStatus ?? 'active';
    if (status != 'active') return false;
    if (flatExpiryMs == null) return true;
    return DateTime.fromMillisecondsSinceEpoch(flatExpiryMs).isAfter(DateTime.now());
  }

  DateTime? _resolveExpiry(Map<String, dynamic>? subscription, int? flatExpiryMs) {
    if (subscription != null) {
      return _parseDate(subscription['expiryDate']);
    }
    if (flatExpiryMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(flatExpiryMs);
  }

  bool _isNotExpired(dynamic expiryRaw) {
    final expiry = _parseDate(expiryRaw);
    if (expiry == null) return true;
    return expiry.isAfter(DateTime.now());
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
