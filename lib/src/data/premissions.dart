// مسیر پیشنهادی: lib/src/utils/permissions.dart
//
// همه‌ی «سطح‌های دسترسی» قابل تنظیم برای کارمندان اینجا تعریف شده.
// مدیر (OWNER) همیشه همه‌چیز را دارد. برای هر کارمند (STAFF) این مقادیر
// در users/{uid}.permissions ذخیره می‌شود و مدیر می‌تواند از صفحه‌ی
// «مدیریت کارمندان» آن‌ها را روشن/خاموش کند.

class PermissionKeys {
  static const canViewProfit = 'canViewProfit'; // دیدن سود/درصد سود
  static const canManagePrices = 'canManagePrices'; // تغییر نرخ خرید/فروش واحد
  static const canManageInventory =
      'canManageInventory'; // ثبت خرید جدید (کریدیت/کارت کاغذی) و افزودن شرکت
  static const canViewReports = 'canViewReports'; // دسترسی به گزارش مشتریان
  static const canManageEmployees =
      'canManageEmployees'; // مدیریت کارمندان (همیشه فقط OWNER)

  static const all = [
    canViewProfit,
    canManagePrices,
    canManageInventory,
    canViewReports,
    canManageEmployees,
  ];

  // برچسب فارسیِ هر دسترسی برای نمایش در صفحه‌ی تنظیمات
  static const labels = {
    canViewProfit: 'دیدن سود و درصد رشد فروش',
    canManagePrices: 'تغییر نرخ خرید/فروش واحد',
    canManageInventory: 'ثبت خرید جدید و مدیریت شرکت‌ها',
    canViewReports: 'دسترسی به گزارش‌های مشتریان',
    canManageEmployees: 'مدیریت کارمندان (فقط مدیر)',
  };
}

/// دسترسی‌های پیش‌فرض برای مدیر (همه چیز true)
Map<String, bool> get kDefaultOwnerPermissions => {
  for (final k in PermissionKeys.all) k: true,
};

/// دسترسی‌های پیش‌فرض برای یک کارمند تازه‌ساخته‌شده
Map<String, bool> get kDefaultStaffPermissions => {
  PermissionKeys.canViewProfit: false,
  PermissionKeys.canManagePrices: false,
  PermissionKeys.canManageInventory: false,
  PermissionKeys.canViewReports: true,
  PermissionKeys.canManageEmployees: false,
};