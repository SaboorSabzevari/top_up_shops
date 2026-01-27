import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../../../../data/local/app_database.dart';
import '../../../../providers/transaction_provider.dart';
import '../../../theme/colors.dart';

class PaperTopupSalePage extends ConsumerStatefulWidget {
  const PaperTopupSalePage({super.key});
  @override
  ConsumerState<PaperTopupSalePage> createState() => _PaperTopupSalePageState();
}

class _PaperTopupSalePageState extends ConsumerState<PaperTopupSalePage> {  int quantity = 1;
  late TextEditingController quantityController = TextEditingController(text: quantity.toString());
  String operator = 'awcc';
  int amount = 100;
  int price = 100;
  TextEditingController paidCtrl=TextEditingController();

  // ---------- متغیرهای جستجوی مشتری ----------
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  OverlayEntry? _overlayEntry;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCustomerId;
  String? _selectedCustomerName;

  // برای debug
  bool _isSearching = false;
  String _searchError = '';
  GlobalKey _searchBoxKey = GlobalKey();
  // ------------------------------------------

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
    _searchController.dispose();
    super.dispose();
  }
  // Future<void> _processPaperSale() async {
  //   // ۱. ورودی‌ها (این مقادیر از فیلدهای صفحه گرفته می‌شوند)
  //   // quantity: تعداد کارت (مثلاً ۱۰)
  //   // price: قیمت فروش فی کارت (مثلاً ۴۸)
  //   // amount: مقدار کریدیت کارت (مثلاً ۵۰)
  //
  //   // ۲. قیمت خرید فی کارت (این را می‌توانید از یک فیلد جدید یا دیتابیس بگیرید)
  //   // فعلاً فرض می‌کنیم ۴۵ افغانی است
  //   double unitCostPrice = 45.0;
  //
  //   // ۳. محاسبات مالی
  //   double totalSellingPrice = (quantity * price).toDouble(); // ۴۸۰ افغانی
  //   double totalCostPrice = (quantity * unitCostPrice).toDouble(); // ۴۵۰ افغانی
  //   double totalProfit = totalSellingPrice - totalCostPrice; // ۳۰ افغانی سود
  //
  //   // ۴. وضعیت پرداخت و بدهی
  //   // اگر مشتری دائمی باشد، ممکن است بعداً پول بدهد. اگر متفرقه باشد، نقد حساب می‌شود.
  //   double paidAmount = _selectedCustomerId != null ? 0.0 : totalSellingPrice;
  //   double remainingAmount = totalSellingPrice - paidAmount;
  //
  //   Map<String, dynamic> transactionData = {
  //     'customer_id': _selectedCustomerId, // اگر null باشد یعنی متفرقه است
  //     'customer_name': _selectedCustomerId != null ? _selectedCustomerName : "مشتری متفرقه ($operator)",
  //     'customer_type': _selectedCustomerId != null ? 'REGISTERED' : 'WALK_IN',
  //     'operator_name': operator.toUpperCase(),
  //     'phone_number': null, // برای کارت فیزیکی شماره موبایل نداریم
  //     'sent_amount': amount.toDouble(), // مقدار اسمی کارت (مثلاً ۵۰)
  //     'total_price': totalSellingPrice, // مبلغ کل قابل پرداخت (مثلاً ۴۸۰)
  //     'paid_amount': paidAmount,
  //     'remaining_amount': remainingAmount,
  //     'cost_price': totalCostPrice, // قیمت تمام شده برای شما (مثلاً ۴۵۰)
  //     'profit': totalProfit, // سود خالص (مثلاً ۳۰)
  //     'ussd_command': 'PAPER_CARD',
  //     'created_at': DateTime.now().toIso8601String(),
  //   };
  //
  //   try {
  //     await DatabaseHelper.instance.saveDetailedTransaction(transactionData);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(_selectedCustomerId != null
  //             ? 'فروش برای $_selectedCustomerName ثبت و به حساب اضافه شد'
  //             : 'فروش نقدی موفقانه ثبت شد'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //
  //     // ریست کردن فرم بعد از ثبت
  //     setState(() {
  //       _selectedCustomerId = null;
  //       _selectedCustomerName = null;
  //       _searchController.clear();
  //     });
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('خطا در ثبت تراکنش'), backgroundColor: Colors.red),
  //     );
  //   }
  // }
Future<void> _processPaperSale() async {
  // ۱. محاسبات پایه
  double totalPrice = (price * quantity).toDouble();

  // ۲. منطق مبلغ دریافتی (اگر فیلد خالی بود، برای ناشناس فرض می‌کنیم کل پول را داده)
  double cashReceived = double.tryParse(paidCtrl.text) ??
      (_selectedCustomerId == null ? totalPrice : 0.0);

  // ۳. محاسبه بدهی (مانده)
  double remaining = totalPrice - cashReceived;

  // ۴. محاسبه سود (فرض بر ۹۵٪ قیمت اسمی به عنوان خرید)
  double costPerUnit = amount * 0.95;
  double totalCost = costPerUnit * quantity;
  double profit = totalPrice - totalCost;

  final transactionData = {
    'customer_id': _selectedCustomerId,
    'customer_name': _selectedCustomerId != null ? _selectedCustomerName : "مشتری متفرقه (کارت $operator)",
    'customer_type': _selectedCustomerId != null ? 'REGISTERED' : 'WALK_IN',
    'transaction_type': 'PAPER',
    'operator_name': operator.toUpperCase(),
    'sent_amount': amount.toDouble(),
    'quantity': quantity,

    // --- بخش مالی اصلاح شده ---
    'total_price': totalPrice,
    'paid_amount': cashReceived,     // مبلغی که واقعاً دریافت شده
    'remaining_amount': remaining,   // مانده حساب (بدهی)
    'received_amount': cashReceived, // برای هماهنگی با کدهای قدیمی آمار

    'cost_price': totalCost,
    'profit': profit,
    'company_code': '',
    'phone_number': '',
    'ussd_command': 'PAPER_SALE',
  };

  try {
    await DatabaseHelper.instance.saveDetailedTransaction(transactionData);

    // بروزرسانی استیت‌ها (Riverpod)
    ref.invalidate(transactionsProvider);
    ref.invalidate(todayProfitProvider);
    ref.invalidate(todayCountProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(remaining > 0
              ? 'ذخیره شد. مانده بدهی: $remaining'
              : 'فروش نقدی با موفقیت ثبت شد'),
          backgroundColor: Colors.green,
        ),
      );
      // پاک کردن فرم بعد از موفقیت
      paidCtrl.clear();
      _searchController.clear();
      setState(() { _selectedCustomerId = null; });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطا در ذخیره: $e'), backgroundColor: Colors.red),
    );
  }
}
  // ---------- متدهای جستجوی مشتری ----------
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _removeOverlay();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        print('جستجو برای: $query');

        List<Map<String, dynamic>> results = [];

        // استفاده از متد searchCustomers
        try {
          results = await DatabaseHelper.instance.searchCustomers(query);
          print('تعداد نتایج: ${results.length}');

          // برای debug: نمایش اولین نتیجه
          if (results.isNotEmpty) {
            print('اولین نتیجه: ${results.first}');
          }
        } catch (e) {
          print('خطا در searchCustomers: $e');

          // روش جایگزین
          try {
            final db = await DatabaseHelper.instance.database;
            results = await db.query(
              'customers',
              where: 'name LIKE ?',
              whereArgs: ['%$query%'],
              limit: 10,
            );
            print('نتایج rawQuery: ${results.length}');
          } catch (e2) {
            print('خطا در rawQuery: $e2');
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });

          if (results.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showOverlay();
            });
          } else {
            _removeOverlay();
          }
        }
      } catch (e) {
        print('خطا در جستجو: $e');
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchError = 'خطا در جستجو: $e';
          });
        }
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();

    // استفاده از GlobalKey برای موقعیت‌یابی صحیح
    final renderBox = _searchBoxKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      print('خطا: renderBox null است');
      return;
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    print('Overlay موقعیت: $offset, اندازه: $size');

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height,
          width: size.width,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // هدر
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_search, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${_searchResults.length} مشتری یافت شد',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 18),
                          onPressed: _removeOverlay,
                        ),
                      ],
                    ),
                  ),

                  // لیست نتایج
                  Expanded(
                    child: _searchResults.isEmpty
                        ? _buildNotFoundWidget()
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final customer = _searchResults[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.red,
                              ),
                            ),
                            title: Text(
                              customer['name']?.toString() ?? 'بدون نام',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (customer['customer_code'] != null)
                                  Text(
                                    'کد: ${customer['customer_code']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (customer['phone'] != null)
                                  Text(
                                    'تلفن: ${customer['phone']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                customer['type'] == 'WHOLESALE' ? 'عمده' : 'عادی',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () => _selectCustomer(customer),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      Overlay.of(context).insert(_overlayEntry!);
      print('Overlay نمایش داده شد');
    } catch (e) {
      print('خطا در نمایش Overlay: $e');
    }
  }

  Widget _buildNotFoundWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 50, color: Colors.grey.shade400),
          SizedBox(height: 12),
          Text(
            'مشتری با این نام یافت نشد',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _removeOverlay();
              // Navigation به صفحه اضافه کردن مشتری
            },
            icon: Icon(Icons.add, size: 18),
            label: Text('افزودن مشتری جدید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      print('Overlay حذف شد');
    }
  }

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedCustomerId = customer['id'];
      _selectedCustomerName = customer['name'];
      _searchController.text = customer['name'];
      _searchController.selection = TextSelection.collapsed(
        offset: customer['name'].length,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${customer['name']}" انتخاب شد'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _searchController.clear();
    });
    _searchFocusNode.requestFocus();
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff8f6f6),
        appBar: _buildAppBar(),
        bottomNavigationBar: _buildBottomBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- جستجوی مشتری ----------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // برچسب
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 4),
                    child: Text(
                      'جستجوی مشتری',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                  // باکس جستجو با GlobalKey
                  Container(
                    key: _searchBoxKey,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // آیکون جستجو
                        Padding(
                          padding: const EdgeInsets.only(right: 12, left: 16),
                          child: Icon(
                            _isSearching ? Icons.search : Icons.person_search,
                            color: _isSearching ? Colors.blue : Colors.red,
                            size: 22,
                          ),
                        ),

                        // فیلد جستجو
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'نام مشتری را وارد کنید...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              suffixIcon: _selectedCustomerId != null
                                  ? IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: _clearCustomer,
                                tooltip: 'پاک کردن انتخاب',
                              )
                                  : null,
                            ),
                            onChanged: _onSearchChanged,
                            onTap: () {
                              if (_selectedCustomerId != null && _searchController.text.isNotEmpty) {
                                _searchController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _searchController.text.length),
                                );
                              }
                            },
                          ),
                        ),

                        // نشانگر انتخاب
                        if (_selectedCustomerId != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check, size: 16, color: Colors.green.shade800),
                                  SizedBox(width: 4),
                                  Text(
                                    'انتخاب',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // وضعیت جستجو
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'در حال جستجو...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // نمایش نام مشتری انتخاب شده
                  if (_selectedCustomerName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.green.shade800, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مشتری انتخاب شده:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    _selectedCustomerName!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
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
              ),
              // -----------------------------------------------
              SizedBox(height: 24),
              _sectionTitle('شرکت مخابراتی'),
              _operatorGrid(),
              SizedBox(height: 24),
              _sectionTitle('مقدار کریدیت (افغانی)'),
              _amountGrid(),
              SizedBox(height: 24),
              _priceAndQuantityRow(),
              SizedBox(height: 16),
              _amountInput('مقدار دریافتی (نقد)', paidCtrl, "AFN"),

              const SizedBox(height: 12),
            ],
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
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: BoxBorder.all(color: Colors.red.shade200),
        ),
        child: TextField(
          textDirection: TextDirection.ltr,
          cursorColor: kPrimaryColor,
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            suffixText: suffixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    ],
  );
}
  // ---------- بقیه ویجت‌ها بدون تغییر ----------

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      title: const Text(
        'فروش کارت کاغذی',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }


  Widget _operatorGrid() {
    final List<Map<String, dynamic>> operators = [
      {
        'title': 'افغان بیسیم',
        'value': 'awcc',
        'svgPath': 'assets/svg/awcc.svg', // ذخیره مسیر SVG به صورت string
        'useSvg': true,
      },
      {
        'title': 'روشن',
        'value': 'roshan',
        'svgPath': 'assets/svg/roshan.svg',
        'useSvg': true,
      },
      {
        'title': 'اتصالات',
        'value': 'etisalat',
        'svgPath': 'assets/svg/etisalat.svg',
        'useSvg': true,
      },
      {
        'title': 'اتوما',
        'value': 'mtn',
        'svgPath': 'assets/svg/atoma.svg',

        'useSvg': true,
      },
      {
        'title': 'سلام',
        'value': 'salaam',
        'svgPath': 'assets/svg/salaam.svg',

        'useSvg': true,
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: operators.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final op = operators[index];
          return _operatorItem(
            title: op['title'] as String,
            value: op['value'] as String,
            useSvg: op['useSvg'] as bool,
            svgPath: op['svgPath'] as String?,

          );
        },
      ),
    );
  }

  Widget _operatorItem({
    required String title,
    required String value,
    required bool useSvg,
    String? svgPath,
    IconData? icon,
  }) {
    final active = operator == value;
    return GestureDetector(
      onTap: () => setState(() => operator = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 110,
        decoration: BoxDecoration(
          color: active ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Colors.red : Colors.grey.shade300,
            width: active ? 2 : 1,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: active ? Colors.white70 : Colors.white70,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: useSvg && svgPath != null
                    ? SizedBox(
                  width: 32,
                  height: 32,
                  child: SvgPicture.asset(
                    svgPath,
                    // colorFilter: ColorFilter.mode(
                    //   // active ? Colors.white : Colors.grey.shade600,
                    //   // BlendMode.srcIn,
                    // ),
                  ),
                )
                    : Icon(
                  icon ?? Icons.sim_card,
                  size: 28,
                  color: active ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: active ? Colors.red.shade800 : Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          ],
        ),
      ),
    );
  }
  Widget _amountGrid() {
    final values = [50, 100, 150, 200, 250, 500];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (_, i) {
        final v = values[i];
        final active = amount == v;
        return GestureDetector(
          onTap: () => setState(() => amount = v),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? Colors.red : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              v.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: active ? Colors.red : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _priceAndQuantityRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // قیمت فروش فی کارت
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'قیمت فی کارت',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'AFN',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                  onChanged: (v) => setState(() => price = int.tryParse(v) ?? price),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // تعداد
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعداد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        int parsedValue = int.tryParse(value) ?? 1;
                        if (parsedValue > 0) {
                          setState(() {
                            quantity = parsedValue;
                          });
                        }
                      }
                    },
                    onSubmitted: (value) {
                      if (value.isEmpty) {
                        setState(() => quantity = 1);
                      } else {
                        int parsedValue = int.tryParse(value) ?? 1;
                        if (parsedValue < 1) parsedValue = 1;
                        setState(() => quantity = parsedValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = price * quantity;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('مجموع قابل پرداخت',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                '$total افغانی',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(color: Colors.white, Icons.check_circle),
              label: const Text(
                'ثبت فروش',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (_selectedCustomerId == null) {
                  // مشتری انتخاب نشده -> فروش متفرقه
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("فروش به مشتری ناشناس"),
                      content: const Text("آیا این فروش به صورت نقد و متفرقه ثبت شود؟"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("خیر")),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _processPaperSale(); // فراخوانی تابع ذخیره
                            },
                            child: const Text("بله، ثبت شود")
                        ),
                      ],
                    ),
                  );
                } else {
                  // مشتری انتخاب شده -> ثبت مستقیم
                  _processPaperSale();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}