import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../data/local/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/session_provider.dart';
import '../../../../providers/transaction_provider.dart';
import '../../../../utils/colors.dart';
import '../../../theme/colors.dart';
import '../../customer/add_customer.dart';
import '../invetory.dart';

class DigitalTopupSalePage extends ConsumerStatefulWidget {
  const DigitalTopupSalePage({super.key});

  @override
  ConsumerState<DigitalTopupSalePage> createState() =>
      _DigitalTopupSalePageState();
}

class _DigitalTopupSalePageState extends ConsumerState<DigitalTopupSalePage> {
  int? selectedCustomerId;
  String? selectedCustomerRemoteId;
  late final l10n = AppLocalizations.of(context)!;
  static const platform = MethodChannel('com.example.top_up_shops/ussd');

  // متغیرهای USSD
  String _ussdResponse = "";
  bool _isUssdLoading = false;
  bool _isResponseExpanded = false;
  double unitBuyPrice = 0.0;
  double unitSellPrice = 0.0; // ضریب فروش از دیتابیس
  double calculatedTotalPayable = 0.0; // مبلغ نهایی (با تخفیف)
  double remainingBalance = 0.0; // مانده حساب این تراکنش
  void _performCalculations() {
    // 1. گرفتن مقادیر از کنترلرها
    double credit = double.tryParse(creditCtrl.text) ?? 0.0;
    double discount = double.tryParse(discountCtrl.text) ?? 0.0;
    double paid = double.tryParse(paidCtrl.text) ?? 0.0;

    setState(() {
      // سناریو: 10000 * 0.97 = 9700
      double rawPrice = credit * unitSellPrice;

      // اعمال تخفیف: 9700 - 100 = 9600 (این مبلغی است که باید بدهد)
      calculatedTotalPayable = rawPrice - discount;

      // محاسبه مانده: 9600 - 5000 = 4600 (بدهکار)
      // اگر مثبت باشد: مشتری بدهکار است
      // اگر منفی باشد: مشتری اضافه پرداخت کرده (طلبکار)
      remainingBalance = calculatedTotalPayable - paid;
    });
  }

  // کنترلرها
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController customerNameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController companyCodeCtrl = TextEditingController();
  final TextEditingController creditCtrl = TextEditingController(text: '0');
  final TextEditingController discountCtrl = TextEditingController(text: '0');
  final TextEditingController paidCtrl = TextEditingController();
  final TextEditingController wholesalePhoneCtrl = TextEditingController();
  final customerCodeCtrl = TextEditingController();

  // لیست‌ها و متغیرهای حالت
  List<dynamic> _currentCustomerWholesaleCodes = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  bool _isOtherProviderSelected = false;
  List<String> _normalCustomerPhones = [];
  String? _selectedPhone;
  List<String> _bulkCustomerPhones = [];
  String? _selectedBulkPhone;
  String customerType = 'normal';
  String selectedOperator = '';
  String commMethod = 'person';
  bool isCompanySelectionLocked = false;
  String? _selectedNormalProviderCode;
  String? _selectedBulkProviderCode;

  // برای جستجوی لایو
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _searchFocusNode = FocusNode();

  // رنگ‌ها
  static const Color primary = Color(0xFFEA2A33);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Colors.white;
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textMuted = Color(0xFF6B7280);

  int get total =>
      (int.tryParse(creditCtrl.text) ?? 0) -
      (int.tryParse(discountCtrl.text) ?? 0);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _removeOverlay();
        Future.microtask(() => _loadUnitRates());
      }
    });

    // اضافه کردن لیسنر برای محاسبه آنی با تغییر هر فیلد
    creditCtrl.addListener(_performCalculations);
    discountCtrl.addListener(_performCalculations);
    paidCtrl.addListener(_performCalculations);
  }

  // 3. این متد را برای گرفتن نرخ از دیتابیس اضافه کنید
  Future<void> _loadUnitRates() async {
    // گرفتن اطلاعات کاربر فعلی از پروایدر
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    // پاس دادن shopId برای رفع ارور 1 positional argument expected
    final unit = await DatabaseHelper.instance.getSingleUnit(user.shopId);

    if (mounted) {
      setState(() {
        unitBuyPrice = (unit['buy_price'] as num?)?.toDouble() ?? 0.0;
        unitSellPrice = (unit['sell_price'] as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _searchFocusNode.dispose();
    customerCodeCtrl.dispose();
    customerNameCtrl.dispose();
    phoneCtrl.dispose();
    wholesalePhoneCtrl.dispose();
    companyCodeCtrl.dispose();
    super.dispose();
  }

  // --- متدهای USSD ---
  Future<void> _executeUssdAndSave(int simSlot) async {
    String ussdCode = _buildUSSDCode();

    if (ussdCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کد USSD معتبر تولید نشد! فیلدها را چک کنید.'),
        ),
      );
      return;
    }

    await _processAndSaveTransaction();

    setState(() {
      _isUssdLoading = true;
      _ussdResponse = "در حال ارسال درخواست به سیم‌کارت ${simSlot + 1}...";
    });

    try {
      final String result = await platform.invokeMethod('sendUssd', {
        "code": ussdCode,
        "slot": simSlot,
      });

      setState(() {
        _ussdResponse = result;
      });

      _showUssdResponseDialog(result);
    } on PlatformException catch (e) {
      setState(() => _ussdResponse = "خطا: ${e.message}");
    } finally {
      setState(() => _isUssdLoading = false);
    }
  }

  Future<void> _executeUssdOnly(int slotIndex) async {
    // ابتدا چک می‌کنیم که آیا شرکت سرویس‌دهنده انتخاب شده است
    if (selectedOperator.isEmpty) {
      _showSnackBar(
        'لطفاً ابتدا شرکت سرویس‌دهنده را انتخاب کنید',
        Colors.orange,
      );
      return;
    }

    // چک می‌کنیم که مقدار کریدیت وارد شده باشد
    double creditAmount = double.tryParse(creditCtrl.text) ?? 0.0;
    if (creditAmount <= 0) {
      _showSnackBar('لطفاً مقدار کریدیت را وارد کنید', Colors.orange);
      return;
    }

    // چک موجودی شرکت سرویس‌دهنده
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _showSnackBar("خطا: کاربر وارد نشده است", Colors.red);
        return;
      }

      double currentBalance = await DatabaseHelper.instance.getProviderBalance(
        selectedOperator,
        user.shopId,
      );

      if (currentBalance < creditAmount) {
        _showErrorDialog(
          'موجودی شرکت "$selectedOperator" کافی نیست!\n'
          'موجودی فعلی: $currentBalance\n'
          'مبلغ درخواستی: $creditAmount\n\n'
          'لطفاً ابتدا موجودی شرکت را افزایش دهید.',
        );
        return;
      }
    } catch (e) {
      _showSnackBar('خطا در بررسی موجودی: $e', Colors.red);
      return;
    }

    // اگر موجودی کافی بود، ادامه می‌دهیم
    setState(() {
      _isUssdLoading = true;
      _ussdResponse = "";
    });

    try {
      // ۱. بررسی مجوز
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
        if (!status.isGranted) {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message:
                'برای ارسال کد دستوری و مدیریت سیم‌کارت، تایید مجوز تماس الزامی است.',
          );
        }
      }

      // ۲. استفاده از کد USSD واقعی (نه کد سخت‌کد شده)
      String ussdCode = _buildUSSDCode();
      if (ussdCode.isEmpty) {
        throw PlatformException(
          code: 'INVALID_USSD',
          message: 'کد USSD معتبر تولید نشد! لطفاً فیلدها را پر کنید.',
        );
      }

      // ۳. فراخوانی متد
      final String result = await platform.invokeMethod('sendUssd', {
        'code': ussdCode, // استفاده از کد USSD واقعی
        'slot': slotIndex,
      });

      setState(() {
        _ussdResponse = result;
        _isUssdLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _isUssdLoading = false;
        _ussdResponse = "خطای سیستم: ${e.message}";
      });
    } catch (e) {
      setState(() {
        _isUssdLoading = false;
        _ussdResponse = "خطای ناشناخته: $e";
      });
    }
  }

  void _showUssdResponseDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("پاسخ شبکه"),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("بستن"),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('پاسخ کپی شد')));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processAndSaveTransaction() async {
    String finalPhone = (customerType == 'normal')
        ? phoneCtrl.text
        : wholesalePhoneCtrl.text;

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _showSnackBar("خطا: کاربر وارد نشده است", Colors.red);
        return;
      }
      // ۱. اعتبارسنجی ورودی‌ها
      String amountText = creditCtrl.text.trim();
      if (amountText.isEmpty) {
        _showSnackBar('لطفاً مقدار کریدیت را وارد کنید', Colors.orange);
        return;
      }

      double? sentAmount = double.tryParse(amountText);
      if (sentAmount == null || sentAmount <= 0) {
        _showSnackBar('مقدار کریدیت وارد شده معتبر نیست', Colors.red);
        return;
      }

      if (selectedCustomerId == null) {
        _showSnackBar('لطفاً مشتری را انتخاب کنید', Colors.orange);
        return;
      }

      // ۲. بررسی موجودی شرکت پروایدر (بخش جدید)
      // selectedOperator نام شرکت انتخاب شده است (مثلاً "افغان پی")
      double currentBalance = await DatabaseHelper.instance.getProviderBalance(
        selectedOperator,
        user.shopId,
      );
      if (currentBalance < sentAmount) {
        _showErrorDialog(
          'موجودی شرکت "$selectedOperator" کافی نیست!\nموجودی فعلی: $currentBalance\nمبلغ درخواستی: $sentAmount',
        );
        return;
      }

      // ۳. دریافت مقادیر ورودی مالی
      double discount = double.tryParse(discountCtrl.text) ?? 0.0;
      double paidCash = double.tryParse(paidCtrl.text) ?? 0.0;

      // ۴. محاسبات مالی
      // قیمت تمام شده (خرید) = مقدار کریدیت * نرخ خرید
      double costPrice = sentAmount * unitBuyPrice;

      // قیمت فروش اولیه = مقدار کریدیت * نرخ فروش
      double initialSalePrice = sentAmount * unitSellPrice;

      // مبلغ نهایی فاکتور = قیمت فروش اولیه - تخفیف
      double totalPrice = initialSalePrice - discount;

      // سود خالص
      double netProfit = totalPrice - costPrice;

      // محاسبه مانده حساب (بدهی)
      double remainingAmount = totalPrice - paidCash;
      // ۵. ذخیره تراکنش و کسر موجودی در یک transaction اتمیک
      await DatabaseHelper.instance.recordDigitalSale(
        providerName: selectedOperator,
        amount: sentAmount,
        user: user,
        transactionData: {
          'customer_id': selectedCustomerId,
          'customer_remote_id': selectedCustomerRemoteId,
          'customer_name': customerNameCtrl.text,
          'customer_type': customerType,
          'transaction_type': 'DIGITAL', // نوع تراکنش دیجیتال
          'operator_name': selectedOperator,
          'company_code': companyCodeCtrl.text,
          'phone_number': finalPhone,
          'sent_amount': sentAmount,
          'quantity': 1,

          // مالی
          'discount': discount,
          'total_price': totalPrice,
          'paid_amount': paidCash,
          'remaining_amount': remainingAmount,
          'received_amount': paidCash,
          'cost_price': costPrice,
          'profit': netProfit,

          'ussd_command': _buildUSSDCode(),
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // ۷. بروزرسانی UI و پاکسازی
      if (mounted) {
        // رفرش کردن تمام پرووایدرها
        _invalidateAllProviders();

        _showSuccessDialog(totalPrice, netProfit, _buildUSSDCode());

        // پاکسازی فیلدها
        creditCtrl.clear();
        discountCtrl.clear();
        paidCtrl.clear();
        phoneCtrl.clear();
        wholesalePhoneCtrl.clear();
      }
    } catch (e) {
      _showSnackBar('خطای غیرمنتظره: $e', Colors.red);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("خطا"),
          ],
        ),
        content: Text(msg, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("متوجه شدم", style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _invalidateAllProviders() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(todayProfitProvider);
    ref.invalidate(todayCountProvider);
    ref.invalidate(todaySalesProvider);
    ref.invalidate(salesGrowthProvider);
    ref.invalidate(recentTransactionsProvider);
  }

  void _showSuccessDialog(double received, double profit, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تراکنش با موفقیت ثبت شد',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text('مبلغ دریافتی: $received ؋'),
            Divider(),
            Text('سود شما: ${profit.toStringAsFixed(2)} ؋ '),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تایید', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    final user = ref.read(currentUserProvider);
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await DatabaseHelper.instance.searchCustomers(
        query,
        user!.shopId,
      );
      setState(() {
        _searchResults = results;
      });
      _showOverlay();
    });
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _searchResults.isEmpty
                  ? _buildNotFoundWidget()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final customer = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.person_search,
                            color: Color(0xFF6B7280),
                          ),
                          title: Text(
                            customer['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "کد: ${customer['customer_code']} | ${customer['type'] == 'WHOLESALE' ? 'عمده' : 'عادی'}",
                          ),
                          onTap: () => _selectCustomer(customer),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildNotFoundWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(l10n.customerNotFound),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _removeOverlay();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AddCustomerPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addNewCustomer),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // در فایل send_credit_screen.dart

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    final fullDetails = await DatabaseHelper.instance.getCustomerFullDetails(
      customer['id'],
    );

    setState(() {
      selectedCustomerId = customer['id'];
      selectedCustomerRemoteId = customer['remote_id'] as String?;
      customerNameCtrl.text = customer['name']?.toString() ?? '';
      customerCodeCtrl.text = customer['customer_code']?.toString() ?? '';
      customerType = (customer['type'] == 'WHOLESALE') ? 'bulk' : 'normal';
      isCompanySelectionLocked = false;
      _currentCustomerWholesaleCodes = fullDetails['wholesale_codes'] ?? [];

      _selectedNormalProviderCode = null;
      _selectedBulkProviderCode = null;
      _normalCustomerPhones = [];
      _selectedPhone = null;
      _bulkCustomerPhones = [];
      _selectedBulkPhone = null;
      _isOtherProviderSelected = false;
      _filteredProviders = [];
      wholesalePhoneCtrl.clear();
      companyCodeCtrl.clear();
      selectedOperator = '';

      // --- تغییرات اصلی اینجاست ---
      if (fullDetails['phones'] is List) {
        final phonesList = fullDetails['phones'] as List;

        // تابع کمکی برای تمیز کردن شماره
        String cleanPhone(dynamic p) {
          if (p is Map) {
            // اگر فرمت {"phone_number": "..."} باشد
            return p['phone_number']?.toString() ?? p.values.first.toString();
          } else {
            String str = p.toString();
            // اگر استرینگ کثیف مثل "{phone_number: 078...}" باشد
            if (str.contains('{') || str.contains('phone_number')) {
              // فقط اعداد را نگه دار
              return str.replaceAll(RegExp(r'[^0-9]'), '');
            }
            return str;
          }
        }

        if (customerType == 'normal') {
          _normalCustomerPhones = phonesList.map((p) => cleanPhone(p)).toList();

          if (_normalCustomerPhones.isNotEmpty) {
            // حذف شماره‌های تکراری یا خالی
            _normalCustomerPhones = _normalCustomerPhones
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();
          }

          if (_normalCustomerPhones.length == 1) {
            _selectedPhone = _normalCustomerPhones[0];
            phoneCtrl.text = _selectedPhone!;
          }
        } else {
          // برای مشتریان عمده
          _bulkCustomerPhones = phonesList.map((p) => cleanPhone(p)).toList();
          if (_bulkCustomerPhones.isNotEmpty) {
            _bulkCustomerPhones = _bulkCustomerPhones
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();
          }
          if (_bulkCustomerPhones.length == 1) {
            _selectedBulkPhone = _bulkCustomerPhones[0];
            wholesalePhoneCtrl.text = _selectedBulkPhone!;
          }
        }
      }
      // --- پایان تغییرات ---
    });

    if (customerType == 'bulk') {
      _prepareFilteredProviders();
    }
  }

  void _prepareFilteredProviders() {
    // استفاده از ref.read برای دریافت وضعیت فعلی لیست شرکت‌ها
    final providersAsync = ref.read(providersListProvider);

    providersAsync.whenData((providersData) {
      if (!mounted) return;

      // استخراج نام شرکت‌هایی که مشتری با آن‌ها کد عمده دارد
      final customerCompanyNames = _currentCustomerWholesaleCodes
          .map((e) => e['company_name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();

      List<Map<String, dynamic>>? filtered;

      // اگر مشتری کد خاصی نداشت، همه را نشان بده، در غیر این صورت فیلتر کن
      if (customerCompanyNames.isEmpty) {
        filtered = List<Map<String, dynamic>>.from(providersData);
      } else {
        filtered = providersData
            .where((provider) {
              final providerName = provider['name']?.toString().trim() ?? '';
              return customerCompanyNames.contains(providerName);
            })
            .cast<Map<String, dynamic>>()
            .toList();
      }

      // اضافه کردن گزینه "دیگر" به انتهای لیست
      final otherProvider = {
        'name': 'دیگر',
        'type': 'other',
        'id': -1,
        'ordinary_code': '*999*',
        'wholesale_code': '*999*',
      };

      if (mounted) {
        setState(() {
          _filteredProviders = [...?filtered, otherProvider];
        });
      }
    });
  }

  void _selectProviderForWholesale(Map<String, dynamic> provider) {
    final providerName = provider['name']?.toString().trim() ?? '';
    final providerCode = provider['wholesale_code']?.toString().trim() ?? '';

    setState(() {
      selectedOperator = providerName;
      _selectedBulkProviderCode = providerCode;
      _isOtherProviderSelected = (providerName == 'دیگر');

      if (_isOtherProviderSelected) {
        isCompanySelectionLocked = false;
        companyCodeCtrl.clear();

        if (_bulkCustomerPhones.isNotEmpty) {
          _selectedBulkPhone = _bulkCustomerPhones.first;
          wholesalePhoneCtrl.text = _selectedBulkPhone!;
        } else {
          _selectedBulkPhone = null;
          wholesalePhoneCtrl.clear();
        }
      } else {
        Map<String, dynamic>? foundCompanyData;

        for (var codeData in _currentCustomerWholesaleCodes) {
          final companyNameInCode =
              codeData['company_name']?.toString().trim() ?? '';
          if (companyNameInCode == providerName) {
            foundCompanyData = codeData;
            break;
          }
        }

        if (foundCompanyData != null && foundCompanyData.isNotEmpty) {
          final companyCode =
              foundCompanyData['company_code']?.toString() ??
              foundCompanyData['dealer_code']?.toString() ??
              foundCompanyData['code']?.toString() ??
              '';

          companyCodeCtrl.text = companyCode;
          isCompanySelectionLocked = true;

          final customerPhone =
              foundCompanyData['phone']?.toString() ??
              foundCompanyData['contact_number']?.toString();
          if (customerPhone != null && customerPhone.isNotEmpty) {
            wholesalePhoneCtrl.text = customerPhone;
            _selectedBulkPhone = customerPhone;
          } else if (_bulkCustomerPhones.isNotEmpty) {
            _selectedBulkPhone = _bulkCustomerPhones.first;
            wholesalePhoneCtrl.text = _selectedBulkPhone!;
          }
        } else {
          companyCodeCtrl.clear();
          isCompanySelectionLocked = false;

          if (_bulkCustomerPhones.isNotEmpty) {
            _selectedBulkPhone = _bulkCustomerPhones.first;
            wholesalePhoneCtrl.text = _selectedBulkPhone!;
          }
        }
      }
    });
  }

  // --- ساخت کد USSD ---
  String _buildUSSDCode() {
    if (customerType == 'normal') {
      if (_selectedNormalProviderCode == null ||
          phoneCtrl.text.isEmpty ||
          creditCtrl.text.isEmpty) {
        return '';
      }
      return '*${_selectedNormalProviderCode}*${phoneCtrl.text}*${creditCtrl.text}#';
    } else if (customerType == 'bulk') {
      if (_selectedBulkProviderCode == null || creditCtrl.text.isEmpty) {
        return '';
      }

      if (_isOtherProviderSelected) {
        if (wholesalePhoneCtrl.text.isEmpty) return '';
        return '*${_selectedBulkProviderCode}*${wholesalePhoneCtrl.text}*${creditCtrl.text}#';
      } else {
        if (companyCodeCtrl.text.isEmpty) return '';
        return '*${_selectedBulkProviderCode}*${companyCodeCtrl.text}*${creditCtrl.text}#';
      }
    }

    return '';
  }

  // --- UI ویجت‌ها ---
  Widget _buildUSSDCodePreview() {
    String ussdCode = _buildUSSDCode();
    if (ussdCode.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('کد USSD تولید شده'),
        const SizedBox(height: 8),
        _cardWrapper(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.call, color: kPrimaryColor),
                  onPressed: () async {
                    final Uri phoneUri = Uri(scheme: 'tel', path: ussdCode);

                    try {
                      await launchUrl(
                        phoneUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      debugPrint('خطا در باز کردن شماره‌گیر: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: kPrimaryColor,
                          content: Text("خطا در بازکردن شماره گیر"),
                        ),
                      );
                    }
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        textDirection: TextDirection.ltr,
                        ussdCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(context),
            Expanded(child: _content()),
          ],
        ),
      ),
      // استفاده از پنل عملیات بازطراحی شده
      bottomNavigationBar: _buildFixedFooter(),
    );
  }

  // === پنل عملیات پایینی بازطراحی شد
  Widget _buildNetworkResponseSection() {
    return GestureDetector(
      onTap: _showFullNetworkResponse,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'پاسخ شبکه:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ussdResponse,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey,
                    ),
                    maxLines: _isResponseExpanded ? null : 2,
                    overflow: _isResponseExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (_ussdResponse.length > 100)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isResponseExpanded = !_isResponseExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        _isResponseExpanded ? 'نمایش کمتر' : 'نمایش بیشتر',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _ussdResponse = ""),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullNetworkResponse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.network_check, color: Colors.blue),
            SizedBox(width: 8),
            Text('پاسخ کامل شبکه'),
          ],
        ),
        content: SingleChildScrollView(child: SelectableText(_ussdResponse)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _ussdResponse));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('پاسخ کپی شد')));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimButton({
    required int simNumber,
    required int slot,
    required Color color,
    required IconData icon,
  }) {
    return ElevatedButton(
      onPressed: _isUssdLoading ? null : () => _executeUssdOnly(slot),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.9),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: _isUssdLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(
                  "SIM $simNumber",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  // === بقیه ویجت‌های UI (بدون تغییر) ===
  Widget _appBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: bgLight,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B0E0E)),
          ),
          Expanded(
            child: Text(
              "ارسال کریدیت",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1B0E0E),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InventoryScreen()),
            ),
            child: const Icon(Icons.notifications, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompositedTransformTarget(link: _layerLink, child: _customerInputs()),
          const SizedBox(height: 20),
          _customerTypeSection(),
          const SizedBox(height: 20),
          _operatorSection(),
          const SizedBox(height: 20),
          customerType == 'normal'
              ? _phoneInputSection()
              : _bulkCustomerSection(),
          const SizedBox(height: 20),
          _paymentSection(),
          const SizedBox(height: 20),
          _communicationSection(),
          const SizedBox(height: 20),
          _buildUSSDCodePreview(),
          _buildUssdRedesignSection(),
        ],
      ),
    );
  }

  Widget _customerInputs() {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: _input(
            label: 'نام مشتری',
            controller: customerNameCtrl,
            hint: 'جستجو با نام...',
            onChanged: _onSearchChanged,
            focusNode: _searchFocusNode,
          ),
        ),
      ],
    );
  }

  Widget _customerTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('نوع مشتری'),
        const SizedBox(height: 8),
        _cardWrapper(
          Row(
            children: [
              _customerTypeItem(
                keyName: 'normal',
                icon: Icons.person,
                label: 'عادی',
              ),
              _customerTypeItem(
                keyName: 'bulk',
                icon: Icons.inventory_2,
                label: 'عمده',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customerTypeItem({
    required String keyName,
    required IconData icon,
    required String label,
  }) {
    final selected = customerType == keyName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            customerType = keyName;
            isCompanySelectionLocked = false;
            _isOtherProviderSelected = false;
            _normalCustomerPhones.clear();
            _bulkCustomerPhones.clear();
            _selectedPhone = null;
            _selectedBulkPhone = null;
            _filteredProviders.clear();
            wholesalePhoneCtrl.clear();
            _selectedNormalProviderCode = null;
            _selectedBulkProviderCode = null;
            if (keyName == 'normal') {
              companyCodeCtrl.clear();
            }
          });
        },
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? primary.withOpacity(0.08)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? primary : textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? primary : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _operatorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('انتخاب شرکت (سرویس‌دهنده)'),
        const SizedBox(height: 8),
        _cardWrapper(SizedBox(height: 110, child: _buildOperatorList())),
      ],
    );
  }

  Widget _buildOperatorList() {
    if (customerType == 'bulk') {
      if (_filteredProviders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'در حال بارگذاری شرکت‌ها...',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredProviders.length,
        itemBuilder: (context, index) {
          final provider = _filteredProviders[index];
          final name = provider['name']?.toString() ?? '';
          final type = provider['type']?.toString() ?? '';
          return _operatorItem(
            name,
            type,
            provider: provider,
            isOther: name == 'دیگر',
          );
        },
      );
    }

    final providersAsync = ref.watch(providersListProvider);

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطا در بارگذاری')),
      data: (providers) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final p = providers[index];
            return _operatorItem(
              p['name']?.toString() ?? '',
              p['type']?.toString() ?? '',
              provider: p,
            );
          },
        );
      },
    );
  }

  Widget _operatorItem(
    String title,
    String type, {
    Map<String, dynamic>? provider,
    bool isOther = false,
  }) {
    final isSelected = selectedOperator == title;

    return GestureDetector(
      onTap: () {
        if (customerType == 'bulk') {
          if (_filteredProviders.isEmpty) return;

          final provider = _filteredProviders.firstWhere(
            (p) => p['name']?.toString() == title,
            orElse: () => {},
          );

          if (provider.isNotEmpty) {
            _selectProviderForWholesale(provider);
          }
        } else {
          if (isCompanySelectionLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'شرکت بر اساس کد دیلری مشتری انتخاب شده قفل شده است.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          setState(() {
            selectedOperator = title;
            if (provider != null) {
              _selectedNormalProviderCode =
                  provider['ordinary_code']?.toString() ?? '';
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        margin: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOther
                    ? Colors.orange
                    : (isSelected ? primary : const Color(0xFFF3F4F6)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOther ? Icons.add_business : Icons.business_center,
                color: isOther
                    ? Colors.white
                    : (isSelected ? Colors.white : Colors.grey),
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? textMain : textMuted,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle, color: primary, size: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _communicationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('روش ارتباطی مشتری'),
        const SizedBox(height: 8),
        _cardWrapper(
          Row(
            children: [
              _commItem('person', Icons.storefront, 'حضوری'),
              _commItem('phone', Icons.call, 'تلفنی'),
              _commItem('whatsapp', Icons.chat, 'واتساپ'),
              _commItem('telegram', Icons.send, 'تلگرام'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _commItem(String key, IconData icon, String label) {
    final selected = commMethod == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => commMethod = key),
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? primary.withOpacity(0.08)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? primary : textMuted),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? primary : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شماره موبایل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),

        if (_normalCustomerPhones.isNotEmpty)
          _buildPhoneSelectionList()
        else
          _buildPhoneInputField(),
      ],
    );
  }

  Widget _buildPhoneSelectionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: kComponentColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: _normalCustomerPhones.map((phone) {
              return RadioListTile<String>(
                activeColor: kPrimaryColor,
                title: Text(phone, style: const TextStyle(fontSize: 14)),
                value: phone,
                groupValue: _selectedPhone,
                onChanged: (String? value) {
                  setState(() {
                    _selectedPhone = value;
                    phoneCtrl.text = value ?? '';
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        _buildPhoneInputField(isAdditional: true),
      ],
    );
  }

  Widget _buildPhoneInputField({bool isAdditional = false}) {
    return Container(
      decoration: BoxDecoration(
        color: kComponentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        cursorColor: kPrimaryColor,
        controller: phoneCtrl,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.contact_phone, color: kPrimaryColor),
          filled: true,
          fillColor: surfaceLight,
          hintText: isAdditional ? 'شماره جدید (اختیاری)' : 'شماره موبایل',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _bulkCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isOtherProviderSelected) ...[
          const Text(
            'شماره تماس',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          if (_bulkCustomerPhones.isNotEmpty) _buildBulkPhoneInputField(),
        ],

        if (!_isOtherProviderSelected) ...[
          const Text('کد شرکت', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: kComponentColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              cursorColor: kPrimaryColor,
              keyboardType: TextInputType.text,
              controller: companyCodeCtrl,
              readOnly: isCompanySelectionLocked,
              style: TextStyle(
                fontSize: 14,
                color: isCompanySelectionLocked ? Colors.grey : Colors.black,
              ),
              decoration: InputDecoration(
                hoverColor: kPrimaryColor,
                prefixIcon: const Icon(Icons.business, color: kPrimaryColor),
                hintText: 'مثال: 454587',
                filled: true,
                fillColor: isCompanySelectionLocked
                    ? Colors.grey[200]
                    : surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBulkPhoneSelectionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: kComponentColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: _bulkCustomerPhones.map((phone) {
              return RadioListTile<String>(
                activeColor: kPrimaryColor,
                title: Text(phone, style: const TextStyle(fontSize: 14)),
                value: phone,
                groupValue: _selectedBulkPhone,
                onChanged: (String? value) {
                  setState(() {
                    _selectedBulkPhone = value;
                    wholesalePhoneCtrl.text = value ?? '';
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        _buildBulkPhoneInputField(isAdditional: true),
      ],
    );
  }

  Widget _buildBulkPhoneInputField({bool isAdditional = false}) {
    return Container(
      decoration: BoxDecoration(
        color: kComponentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        cursorColor: kPrimaryColor,
        controller: wholesalePhoneCtrl,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.contact_phone, color: kPrimaryColor),
          filled: true,
          fillColor: surfaceLight,
          hintText: isAdditional ? 'شماره جدید (اختیاری)' : 'شماره تماس',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _paymentSection() {
    // ۱. استخراج مقادیر از کنترلرها
    double creditAmount = double.tryParse(creditCtrl.text) ?? 0.0;
    double discount = double.tryParse(discountCtrl.text) ?? 0.0;

    // ۲. محاسبه مبلغ نهایی فاکتور (آنچه مشتری باید پرداخت کند)
    // مثال شما: (10000 * 0.97) - 100 = 9600
    double totalInvoice = (creditAmount * unitSellPrice) - discount;

    // ۳. محاسبه قیمت تمام شده برای شما
    // مثال شما: 10000 * 0.95 = 9500
    double costForMe = creditAmount * unitBuyPrice;

    // ۴. محاسبه سود خالص
    // مثال شما: 9600 - 9500 = 100
    double netProfit = totalInvoice - costForMe;

    // تعیین وضعیت رنگ و متن مانده حساب (بدهکاری/طلبکاری)
    String statusText;
    Color statusColor;
    Color ColorForProfit;
    if (remainingBalance > 0) {
      statusText = "باقیمانده (بدهکار)";
      statusColor = Colors.red;
    } else if (remainingBalance < 0) {
      statusText = "اضافه پرداخت (طلبکار)";
      statusColor = Colors.green;
    } else {
      statusText = "تسویه کامل";
      statusColor = Colors.grey;
    }
    if (netProfit >= 0) {
      ColorForProfit = Colors.green;
    } else {
      ColorForProfit = Colors.red;
    }

    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorForProfit.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: ColorForProfit,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "سود خالص شما: ${netProfit.toStringAsFixed(0)} ؋",
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorForProfit,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _amountInput('مقدار کریدیت', creditCtrl, null),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _amountInput('تخفیف (؋)', discountCtrl, "؋"),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // نمایش مجموع قابل پرداخت (محاسبه شده با ضریب)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.grey, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'مبلغ نهایی فاکتور:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${calculatedTotalPayable.toStringAsFixed(0)} ؋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ورودی مقدار پرداخت شده توسط مشتری
          _amountInput('مقدار دریافتی (نقد)', paidCtrl, "؋"),

          const SizedBox(height: 12),

          // باکس وضعیت مانده حساب (بدهکاری/طلبکاری)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  '${remainingBalance.abs().toStringAsFixed(0)} ؋ ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountInput(
    String label,
    TextEditingController ctrl,
    String? suffixText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // استایل لیبل دقیقاً مشابه متد _input (بدون رنگ خاص)
        Text(label, style: const TextStyle(fontSize: 12)),

        // فاصله مشابه (4 پیکسل)
        const SizedBox(height: 4),

        Container(
          // انتقال دکوراسیون (بوردر و رنگ) به کانتینر والد
          decoration: BoxDecoration(
            color: kComponentColor, // استفاده از متغیر رنگ مشابه
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!), // بوردر خاکستری
          ),
          child: TextField(
            textDirection: TextDirection.ltr,
            cursorColor: kPrimaryColor,
            controller: ctrl,
            keyboardType: TextInputType.number,

            // نکته: textAlign را حذف کردم تا مثل _input از چپ شروع شود (استانداردتر)
            // اگر می‌خواهید وسط‌چین باشد، خط زیر را از کامنت خارج کنید:
            // textAlign: TextAlign.center,
            decoration: InputDecoration(
              // حذف بوردر داخلی چون کانتینر بوردر دارد
              border: InputBorder.none,
              // تنظیم پدینگ برای قرارگیری مرتب متن
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8, // مشابه ورودی _input
              ),
              suffixText: suffixText,
              suffixStyle: const TextStyle(color: Colors.grey),
              hintStyle: const TextStyle(color: Colors.grey),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Widget _cardWrapper(Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: kComponentColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            cursorColor: kPrimaryColor,
            autofocus: true,
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            focusNode: focusNode,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 8,
              ),
              hintText: hint,
              hoverColor: kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }
  // --- بخش جدید بازطراحی شده بر اساس دیزاین شما ---

  Widget _buildUssdRedesignSection() {
    final ussdCode = _buildUSSDCode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),

        // ۲. دکمه‌های انتخاب سیم‌کارت (Grid Layout)
        Row(
          children: [
            Expanded(child: _simButtonDesign("SIM 1", 0)),
            const SizedBox(width: 12),
            Expanded(child: _simButtonDesign("SIM 2", 1)),
          ],
        ),

        const SizedBox(height: 24),

        // ۳. بخش پاسخ سیستم (فقط در صورت وجود پاسخ نمایش داده می‌شود)
        if (_ussdResponse.isNotEmpty || _isUssdLoading)
          _buildSystemResponseSection(),
      ],
    );
  }

  // ویجت دکمه سیم‌کارت طبق دیزاین
  Widget _simButtonDesign(String label, int slot) {
    return InkWell(
      onTap: _isUssdLoading
          ? null
          : () => _executeUssdOnly(slot), // فقط اجرای USSD
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: kPrimaryColor, // خاکستری ملایم (gray-100)
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sim_card_outlined, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ویجت پاسخ سیستم طبق دیزاین
  Widget _buildSystemResponseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('پاسخ سیستم (USSD)'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isUssdLoading ? Colors.blue[50] : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isUssdLoading
                  ? Colors.blue[100]!
                  : const Color(0xFFDCFCE7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نمایش لودینگ چرخان هنگام درخواست و تیک سبز بعد از دریافت پاسخ
              _isUssdLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    )
                  : const Icon(
                      Icons.quickreply_outlined,
                      color: Colors.green,
                      size: 24,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isUssdLoading
                          ? "در حال دریافت پاسخ از شبکه..."
                          : "پاسخ دریافت شده:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isUssdLoading
                            ? Colors.blue[800]
                            : const Color(0xFF166534),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // نمایش دقیق متن USSD که از اپراتور آمده است
                    Text(
                      _ussdResponse,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                        fontFamily:
                            'monospace', // برای خوانایی بهتر کدهای عددی در پیام
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ۴. دکمه فوتر برای ثبت تراکنش (جدا شده از اجرای USSD)
  Widget _buildFixedFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _processAndSaveTransaction();
          ref.invalidate(todaySalesProvider);
          ref.invalidate(salesSummaryProvider);
        }, // فقط ذخیره در دیتابیس
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: kPrimaryColor.withOpacity(0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, color: Colors.white),
            SizedBox(width: 12),
            Text(
              "ثبت تراکنش",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
