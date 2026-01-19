import 'dart:convert';

class SessionInfo {
  final String shopId;
  final String employeeId;
  final String roleId;
  final String shopName;
  final bool subscriptionActive;
  final DateTime? subscriptionExpiry;
  final bool allowViewOnExpired;
  final Map<String, bool> permissions;

  const SessionInfo({
    required this.shopId,
    required this.employeeId,
    required this.roleId,
    required this.shopName,
    required this.subscriptionActive,
    required this.subscriptionExpiry,
    required this.allowViewOnExpired,
    required this.permissions,
  });

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'employee_id': employeeId,
      'role_id': roleId,
      'shop_name': shopName,
      'subscription_active': subscriptionActive,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'allow_view_on_expired': allowViewOnExpired,
      'permissions': permissions,
    };
  }

  static SessionInfo fromMap(Map<String, dynamic> map) {
    return SessionInfo(
      shopId: map['shop_id'] as String? ?? 'local_shop',
      employeeId: map['employee_id'] as String? ?? 'local_owner',
      roleId: map['role_id'] as String? ?? 'owner',
      shopName: map['shop_name'] as String? ?? 'فروشگاه من',
      subscriptionActive: map['subscription_active'] as bool? ?? true,
      subscriptionExpiry: map['subscription_expiry'] != null
          ? DateTime.tryParse(map['subscription_expiry'] as String)
          : null,
      allowViewOnExpired: map['allow_view_on_expired'] as bool? ?? true,
      permissions: _decodePermissions(map['permissions']),
    );
  }

  static Map<String, bool> _decodePermissions(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(key, value == true));
    }
    if (raw is String) {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      return parsed.map((key, value) => MapEntry(key, value == true));
    }
    return {};
  }
}

class SessionService {
  static final SessionService instance = SessionService._();
  SessionService._();

  SessionInfo _session = const SessionInfo(
    shopId: 'local_shop',
    employeeId: 'local_owner',
    roleId: 'owner',
    shopName: 'فروشگاه من',
    subscriptionActive: true,
    subscriptionExpiry: null,
    allowViewOnExpired: true,
    permissions: {},
  );

  SessionInfo get session => _session;
  String get currentShopId => _session.shopId;
  String get currentEmployeeId => _session.employeeId;
  String get currentRoleId => _session.roleId;
  String get currentShopName => _session.shopName;
  bool get subscriptionActive => _session.subscriptionActive;
  DateTime? get subscriptionExpiry => _session.subscriptionExpiry;
  bool get allowViewOnExpired => _session.allowViewOnExpired;
  Map<String, bool> get permissions => _session.permissions;

  bool hasPermission(String permission) => _session.permissions[permission] == true;
  bool get canWrite => _session.subscriptionActive;

  void update(SessionInfo info) {
    _session = info;
  }

  void updateFromMap(Map<String, dynamic> map) {
    _session = SessionInfo.fromMap(map);
  }

  Map<String, dynamic> toPrefsMap() => _session.toMap();

  void updateShopName(String name) {
    _session = SessionInfo(
      shopId: _session.shopId,
      employeeId: _session.employeeId,
      roleId: _session.roleId,
      shopName: name,
      subscriptionActive: _session.subscriptionActive,
      subscriptionExpiry: _session.subscriptionExpiry,
      allowViewOnExpired: _session.allowViewOnExpired,
      permissions: _session.permissions,
    );
  }

  void updateSubscription({required bool active, DateTime? expiry}) {
    _session = SessionInfo(
      shopId: _session.shopId,
      employeeId: _session.employeeId,
      roleId: _session.roleId,
      shopName: _session.shopName,
      subscriptionActive: active,
      subscriptionExpiry: expiry,
      allowViewOnExpired: _session.allowViewOnExpired,
      permissions: _session.permissions,
    );
  }
}
