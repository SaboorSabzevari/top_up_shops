import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/local/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/transaction_provider.dart';
import '../../../../utils/colors.dart';
import '../../../theme/colors.dart';
import '../../customer/add_customer.dart';

class DigitalTopupSalePage extends ConsumerStatefulWidget {
  const DigitalTopupSalePage({super.key});

  @override
  ConsumerState<DigitalTopupSalePage> createState() =>
      _DigitalTopupSalePageState();
}

class _DigitalTopupSalePageState extends ConsumerState<DigitalTopupSalePage> {
  int? selectedCustomerId;

  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController customerNameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController companyCodeCtrl = TextEditingController();

  //---------------- State ----------------
  void _showSelectionDialog({
    required String title,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) => ListTile(
              title: Text(items[index], textAlign: TextAlign.center),
              onTap: () {
                onSelected(items[index]);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  // لیست کدهای دیلری مشتری انتخاب شده
  List<dynamic> _currentCustomerWholesaleCodes = [];

  // لیست شرکت‌های فیلتر شده برای مشتری عمده
  List<Map<String, dynamic>> _filteredProviders = [];

  // آیا شرکت "دیگر" انتخاب شده است؟
  bool _isOtherProviderSelected = false;

  // لیست شماره‌های مشتری عادی
  List<String> _normalCustomerPhones = [];
  String? _selectedPhone;

  // لیست شماره‌های مشتری عمده
  List<String> _bulkCustomerPhones = [];
  String? _selectedBulkPhone;

  // 🎨 Colors
  static const Color primary = Color(0xFFEA2A33);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Colors.white;
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textMuted = Color(0xFF6B7280);

  String customerType = 'normal';
  String selectedOperator = '';
  String commMethod = 'person';
  bool isCompanySelectionLocked = false;

  // کنترلرها
  final customerCodeCtrl = TextEditingController();
  final creditCtrl = TextEditingController(text: '100');
  final discountCtrl = TextEditingController(text: '0');
  final paidCtrl = TextEditingController();
  final wholesalePhoneCtrl =
  TextEditingController(); // شماره تماس برای مشتری عمده

  // برای جستجوی لایو
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _searchFocusNode = FocusNode();

  // متغیرهای ذخیره کد شرکت برای تولید USSD
  String? _selectedNormalProviderCode; // کد شرکت برای مشتری عادی
  String? _selectedBulkProviderCode; // کد شرکت برای مشتری عمده

  int get total =>
      (int.tryParse(creditCtrl.text) ?? 0) -
          (int.tryParse(discountCtrl.text) ?? 0);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _removeOverlay();
      }
    });
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

  // --- Logic جستجو و نمایش Overlay ---

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await DatabaseHelper.instance.searchCustomers(query);
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
  Future<void> _processAndSaveTransaction() async {
    String finalPhone = (customerType == 'normal') ? phoneCtrl.text : wholesalePhoneCtrl.text;

// سپس در مپ دیتا:

    try {
      // ۱. پاکسازی متن ورودی از فاصله‌های احتمالی
      String amountText = creditCtrl.text.trim();

      // ۲. بررسی خالی نبودن فیلد
      if (amountText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً مبلغ را وارد کنید'), backgroundColor: Colors.orange),
        );
        return;
      }

      // ۳. تبدیل امن متن به عدد (جلوگیری از کرش و خطای FormatException)
      double? sentAmount = double.tryParse(amountText);

      if (sentAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مبلغ وارد شده معتبر نیست (فقط عدد وارد کنید)'), backgroundColor: Colors.red),
        );
        return;
      }

      if (selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً مشتری را انتخاب کنید'), backgroundColor: Colors.orange),
        );
        return;
      }

      final unitSettings = await DatabaseHelper.instance.getSingleUnit();
      double buyRate = unitSettings['buy_price'] ?? 0.0;
      double sellRate = unitSettings['sell_price'] ?? 0.0;

      double costPrice = sentAmount * buyRate;
      double receivedAmount = sentAmount * sellRate;
      double profit = receivedAmount - costPrice;
      String finalCode = "*${companyCodeCtrl.text}*${phoneCtrl.text}*${sentAmount.toInt()}#";

      await DatabaseHelper.instance.saveDetailedTransaction({
        'customer_id': selectedCustomerId,
        'customer_name': customerNameCtrl.text,
        'customer_type': customerType,
        'operator_name': selectedOperator,
        'company_code': companyCodeCtrl.text,
        'sent_amount': sentAmount,
        'received_amount': receivedAmount,
        'cost_price': costPrice,
        'profit': profit,
        'ussd_command': finalCode,
        'phone_number': finalPhone,
      });

      if (mounted) {
        _showSuccessDialog(receivedAmount, profit, finalCode);
        ref.invalidate(transactionsProvider);
        ref.invalidate(todayProfitProvider);
        ref.invalidate(todayCountProvider);
        amountCtrl.clear();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطای غیرمنتظره: $e'), backgroundColor: Colors.red),
      );
    }
  }
  void _showSuccessDialog(double received, double profit, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تراکنش با موفقیت ثبت شد', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text('مبلغ دریافتی: $received AFN'),
            Text('سود شما: $profit AFN'),
            const Divider(),
            Text('کد: $code', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('تایید'))
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('مشتری با این مشخصات یافت نشد'),
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
            label: const Text('ثبت مشتری جدید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic انتخاب مشتری ---

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    // دریافت اطلاعات کامل از دیتابیس
    final fullDetails = await DatabaseHelper.instance.getCustomerFullDetails(
      customer['id'],
    );

    print('جزئیات کامل مشتری: $fullDetails'); // برای دیباگ

    setState(() {
      selectedCustomerId = customer['id'];
      customerNameCtrl.text = customer['name']?.toString() ?? '';
      customerCodeCtrl.text = customer['customer_code']?.toString() ?? '';
      customerType = (customer['type'] == 'WHOLESALE') ? 'bulk' : 'normal';
      isCompanySelectionLocked = false;
      _currentCustomerWholesaleCodes = fullDetails['wholesale_codes'] ?? [];

      // ریست کردن متغیرهای USSD
      _selectedNormalProviderCode = null;
      _selectedBulkProviderCode = null;

      print('کدهای عمده فروشی: $_currentCustomerWholesaleCodes'); // برای دیباگ

      // ریست کردن سایر فیلدها
      _normalCustomerPhones = [];
      _selectedPhone = null;
      _bulkCustomerPhones = [];
      _selectedBulkPhone = null;
      _isOtherProviderSelected = false;
      _filteredProviders = [];
      wholesalePhoneCtrl.clear();
      companyCodeCtrl.clear();
      selectedOperator = '';
    });

    // منطق مشتری عادی
    if (customerType == 'normal') {
      final List phonesList = fullDetails['phones'] ?? [];
      if (phonesList.isNotEmpty) {
        setState(() {
          _normalCustomerPhones = phonesList
              .map((p) => p['phone_number'].toString())
              .toList();
          if (_normalCustomerPhones.length == 1) {
            _selectedPhone = _normalCustomerPhones[0];
            phoneCtrl.text = _selectedPhone!;
          }
        });
      }
    }
    // منطق مشتری عمده
    else if (customerType == 'bulk') {
      final List phonesList = fullDetails['phones'] ?? [];
      if (phonesList.isNotEmpty) {
        setState(() {
          _bulkCustomerPhones = phonesList
              .map((p) => p['phone_number'].toString())
              .toList();
          if (_bulkCustomerPhones.length == 1) {
            _selectedBulkPhone = _bulkCustomerPhones[0];
            wholesalePhoneCtrl.text = _selectedBulkPhone!;
          }
        });
      }

      // فراخوانی آماده‌سازی لیست شرکت‌ها
      _prepareFilteredProviders();
    }
  }

  // --- آماده‌سازی لیست شرکت‌های فیلتر شده ---
  void _prepareFilteredProviders() async {
    try {
      // دریافت لیست کامل شرکت‌ها به صورت صحیح
      final providersAsync = ref.read(providersListProvider);

      providersAsync.when(
        data: (providersData) {
          if (!mounted) return;

          // استخراج نام شرکت‌های ثبت شده برای این مشتری
          final customerCompanyNames = _currentCustomerWholesaleCodes
              .map((e) => e['company_name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toSet();

          print('Customer Company Names: $customerCompanyNames'); // برای دیباگ

          List<Map<String, dynamic>> filtered;
          if (customerCompanyNames.isEmpty) {
            // اگر مشتری هیچ شرکتی ثبت نکرده، تمام شرکت‌ها را نشان بده
            filtered = List<Map<String, dynamic>>.from(providersData);
          } else {
            // فیلتر کردن شرکت‌ها
            filtered = providersData.where((provider) {
              final providerName = provider['name']?.toString().trim() ?? '';
              return customerCompanyNames.contains(providerName);
            }).toList();

            print('Filtered Providers Count: ${filtered.length}'); // برای دیباگ
          }

          // اضافه کردن گزینه "دیگر" به لیست
          final otherProvider = {
            'name': 'دیگر',
            'type': 'other',
            'id': -1,
            'ordinary_code': '*999*',
            'wholesale_code': '*999*',
          };
          final allProviders = [...filtered, otherProvider];

          print(
            'All Providers to show: ${allProviders.map((p) => p['name'])}',
          ); // برای دیباگ

          if (mounted) {
            setState(() {
              _filteredProviders = allProviders;
            });
          }
        },
        loading: () {
          if (mounted) {
            setState(() {
              _filteredProviders = [];
            });
          }
        },
        error: (error, stackTrace) {
          print('خطا در بارگذاری شرکت‌ها: $error');
          if (mounted) {
            setState(() {
              _filteredProviders = [];
            });
          }
        },
      );
    } catch (error) {
      print('خطا در prepareFilteredProviders: $error');
    }
  }

  // --- انتخاب شرکت برای مشتری عمده ---
  void _selectProviderForWholesale(Map<String, dynamic> provider) {
    final providerName = provider['name']?.toString().trim() ?? '';
    final providerCode = provider['wholesale_code']?.toString().trim() ?? '';

    print('انتخاب شرکت: $providerName');
    print('کدهای دیلری مشتری: $_currentCustomerWholesaleCodes');
    print('شماره‌های ذخیره شده مشتری: $_bulkCustomerPhones');

    setState(() {
      selectedOperator = providerName;
      _selectedBulkProviderCode = providerCode; // ذخیره کد شرکت برای مشتری عمده
      _isOtherProviderSelected = (providerName == 'دیگر');

      if (_isOtherProviderSelected) {
        // 🟢 منطق انتخاب "دیگر":
        // 1. قفل فیلد کد شرکت باز شود
        isCompanySelectionLocked = false;

        // 2. فیلد کد شرکت پاک شود (تا کاربر کد جدید وارد کند)
        companyCodeCtrl.clear();

        // 3. شماره تماس ذخیره شده مشتری را به صورت خودکار در فیلد قرار بده
        if (_bulkCustomerPhones.isNotEmpty) {
          // روش 1: اولین شماره را انتخاب کن
          _selectedBulkPhone = _bulkCustomerPhones.first;
          wholesalePhoneCtrl.text = _selectedBulkPhone!;

          print('شماره تماس به صورت خودکار تنظیم شد: ${_selectedBulkPhone}');

          // روش 2: اگر می‌خواهید کاربر انتخاب کند، می‌توانید اینجا Dialog نشان دهید
          // _showPhoneSelectionDialog();
        } else {
          // اگر شماره‌ای ذخیره نشده، فیلد را خالی کن
          _selectedBulkPhone = null;
          wholesalePhoneCtrl.clear();
          print('هیچ شماره تماسی برای این مشتری ذخیره نشده است.');
        }

        // 4. لاگ برای دیباگ
        print(
          'شرکت "دیگر" انتخاب شد. فیلد کد شرکت باز شد و شماره تماس تنظیم شد.',
        );
      } else {
        // 🔵 منطق انتخاب شرکت از لیست:
        // پیدا کردن کد شرکت برای این مشتری
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

          print('کد شرکت یافت شد: $companyCode');

          // 1. کد شرکت را در فیلد قرار بده
          companyCodeCtrl.text = companyCode;

          // 2. فیلد کد شرکت را قفل کن (کاربر نتواند تغییر دهد)
          isCompanySelectionLocked = true;

          // 3. شماره تماس از کد دیلری را تنظیم کن (اگر وجود دارد)
          final customerPhone =
              foundCompanyData['phone']?.toString() ??
                  foundCompanyData['contact_number']?.toString();
          if (customerPhone != null && customerPhone.isNotEmpty) {
            wholesalePhoneCtrl.text = customerPhone;
            _selectedBulkPhone = customerPhone;
            print('شماره تماس از کد دیلری تنظیم شد: $customerPhone');
          } else if (_bulkCustomerPhones.isNotEmpty) {
            // اگر شماره در کد دیلری نبود، شماره ذخیره شده مشتری را قرار بده
            _selectedBulkPhone = _bulkCustomerPhones.first;
            wholesalePhoneCtrl.text = _selectedBulkPhone!;
            print(
              'شماره تماس از پروفایل مشتری تنظیم شد: ${_selectedBulkPhone}',
            );
          }
        } else {
          print('کد شرکت یافت نشد!');
          companyCodeCtrl.clear();
          isCompanySelectionLocked = false;

          // اگر کد شرکت یافت نشد، شماره تماس ذخیره شده مشتری را قرار بده
          if (_bulkCustomerPhones.isNotEmpty) {
            _selectedBulkPhone = _bulkCustomerPhones.first;
            wholesalePhoneCtrl.text = _selectedBulkPhone!;
            print('کد شرکت یافت نشد، شماره تماس از پروفایل مشتری تنظیم شد.');
          }
        }
      }
    });
  }

  void _setCompanyData(Map<String, dynamic> companyData) {
    setState(() {
      String name =
      (companyData['company'] ?? companyData['company_name'] ?? '')
          .toString();
      String code = (companyData['code'] ?? companyData['dealer_code'] ?? '')
          .toString();

      selectedOperator = name;
      companyCodeCtrl.text = code;
      isCompanySelectionLocked = true;
    });
  }

  // --- تابع ساخت کد USSD ---
  String _buildUSSDCode() {
    if (customerType == 'normal') {
      // برای مشتری عادی
      if (_selectedNormalProviderCode == null ||
          phoneCtrl.text.isEmpty ||
          creditCtrl.text.isEmpty) {
        return '';
      }

      // شکل: *کد شرکت*شماره تماس*مقدار#
      return '*${_selectedNormalProviderCode}*${phoneCtrl.text}*${creditCtrl.text}#';
    } else if (customerType == 'bulk') {
      // برای مشتری عمده
      if (_selectedBulkProviderCode == null || creditCtrl.text.isEmpty) {
        return '';
      }

      if (_isOtherProviderSelected) {
        // اگر گزینه "دیگر" انتخاب شده
        if (wholesalePhoneCtrl.text.isEmpty) return '';
        // شکل: *کد شرکت*شماره تماس*مقدار#
        return '*${_selectedBulkProviderCode}*${wholesalePhoneCtrl.text}*${creditCtrl.text}#';
      } else {
        // اگر شرکت مشخص انتخاب شده
        if (companyCodeCtrl.text.isEmpty) return '';
        // شکل: *کد شرکت*کد مشتری*مقدار#
        return '*${_selectedBulkProviderCode}*${companyCodeCtrl.text}*${creditCtrl.text}#';
      }
    }

    return '';
  }

  // --- ویجت نمایش کد USSD ---
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
                    final Uri phoneUri = Uri(
                      scheme: 'tel',
                      path: ussdCode, // شماره تلفن
                    );

                    try {
                      await launchUrl(
                        phoneUri,
                        mode: LaunchMode.externalApplication, // خیلی مهم
                      );
                    } catch (e) {
                      debugPrint('خطا در باز کردن شماره‌گیر: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
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
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(context),
            Expanded(child: _content()),
            // در انتهای لیست ویجت‌های Column در body
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _processAndSaveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'ذخیره و ثبت تراکنش',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      //bottomNavigationBar: _bottomButtons(),
    );
  }

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
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF1B0E0E)),
          ),
          const Expanded(
            child: Text(
              'فروش شارژ دیجیتال',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1B0E0E),
              ),
            ),
          ),
          const Icon(Icons.notifications, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
            // ریست کردن متغیرهای USSD
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
                ? primary.withValues(alpha: 0.08)
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

  // --- Operator Section ---

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
    // اگر مشتری عمده است
    print('Customer Type: $customerType'); // برای دیباگ
    print(
      'Filtered Providers Count: ${_filteredProviders.length}',
    ); // برای دیباگ

    // اگر مشتری عمده است
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
          print('Provider $index: $name'); //
          return _operatorItem(
            name,
            type,
            provider: provider,
            isOther: name == 'دیگر',
          );
        },
      );
    }

    // برای مشتری عادی
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
          // برای مشتری عمده
          if (_filteredProviders.isEmpty) return;

          // پیدا کردن provider کامل از لیست فیلتر شده
          final provider = _filteredProviders.firstWhere(
                (p) => p['name']?.toString() == title,
            orElse: () => {},
          );

          if (provider.isNotEmpty) {
            _selectProviderForWholesale(provider);
          }
        } else {
          // برای مشتری عادی
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
            // ذخیره کد شرکت برای مشتری عادی
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
  // --- Communication Section ---

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

  // --- Phone Input Section برای مشتری عادی ---

  Widget _phoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شماره موبایل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),

        // اگر شماره‌های مشتری ذخیره شده‌اند، لیست را نمایش بده
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
        // امکان وارد کردن شماره جدید
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
        controller: phoneCtrl,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.contact_phone, color: kPrimaryColor),
          suffixText: '93+',
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

  // --- بخش مشتری عمده ---
  Widget _bulkCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اگر شرکت "دیگر" انتخاب شده، فقط فیلد شماره تماس نمایش داده شود
        if (_isOtherProviderSelected) ...[
          const Text(
            'شماره تماس',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          // اگر شماره‌های مشتری ذخیره شده‌اند، لیست را نمایش بده
          if (_bulkCustomerPhones.isNotEmpty) _buildBulkPhoneInputField(),
        ],

        // فیلد کد شرکت فقط وقتی نمایش داده شود که شرکت "دیگر" انتخاب نشده باشد
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
        // امکان وارد کردن شماره جدید
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
        controller: wholesalePhoneCtrl,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.contact_phone, color: kPrimaryColor),
          suffixText: '93+',
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
    return _cardWrapper(
      Column(
        children: [
          Row(
            children: [
              Expanded(child: _amountInput('مقدار کریدیت', creditCtrl, null)),
              const SizedBox(width: 12),
              Expanded(child: _amountInput(' تخفیف %', discountCtrl, "AFN")),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.calculate, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'مجموع (قابل پرداخت)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '$total AFN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _amountInput('مقدار پرداخت شده', paidCtrl, null),
        ],
      ),
    );
  }

  // Widget _bottomButtons() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: const BoxDecoration(
  //       color: surfaceLight,
  //       border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(child: _simButton('SIM 1', true)),
  //         const SizedBox(width: 12),
  //         Expanded(child: _simButton('SIM 2', false)),
  //       ],
  //     ),
  //   );
  // }

  Widget _simButton(String label, bool primaryBtn) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Implement Transaction Save
        },
        icon: const Icon(Icons.sim_card),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBtn ? primary : surfaceLight,
          foregroundColor: primaryBtn ? Colors.white : primary,
          side: primaryBtn ? null : const BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
        Text(label, style: const TextStyle(fontSize: 12, color: textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            suffixText: suffixText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
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
              prefixIcon: Icon(Icons.search, color: kPrimaryColor),
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
}