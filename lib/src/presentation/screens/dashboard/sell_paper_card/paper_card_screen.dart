import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // اضافه کردن این خط
import 'dart:async';
import '../../../../data/local/app_database.dart';
import '../../../../providers/session_provider.dart';
import '../../../../providers/transaction_provider.dart';
import '../../../theme/colors.dart';

class PaperTopupSalePage extends ConsumerStatefulWidget {
  const PaperTopupSalePage({super.key});
  @override
  ConsumerState<PaperTopupSalePage> createState() => _PaperTopupSalePageState();
}

class _PaperTopupSalePageState extends ConsumerState<PaperTopupSalePage> {
  int quantity = 1;
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

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24.sp), // ریسپانسیو
            SizedBox(width: 8.w), // ریسپانسیو
            Text("خطا", style: TextStyle(fontSize: 18.sp)), // ریسپانسیو
          ],
        ),
        content: Text(
          msg,
          style: TextStyle(fontSize: 14.sp, height: 1.5), // ریسپانسیو
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "متوجه شدم",
              style: TextStyle(color: Colors.red, fontSize: 14.sp), // ریسپانسیو
            ),
          )
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), // ریسپانسیو
      ),
    );
  }

  Future<void> _processPaperSale() async {
    String currentOperator = operator;
    print('بررسی موجودی برای: operator=$currentOperator, amount=$amount, quantity=$quantity');
    final user = ref.read(currentUserProvider);
    int currentStock = await DatabaseHelper.instance.getPaperStockCount(currentOperator, amount,user!.shopId);
    if (currentStock < quantity) {
      _showErrorDialog("موجودی کافی نیست! موجودی فعلی کارت $amount ؋ $currentOperator: $currentStock عدد");
      return;
    }

    double totalPrice = (price * quantity).toDouble();
    double cashReceived = double.tryParse(paidCtrl.text) ??
        (_selectedCustomerId == null ? totalPrice : 0.0);
    double remaining = totalPrice - cashReceived;
    double costPerUnit = amount * 0.95;
    double totalCost = costPerUnit * quantity;
    double profit = totalPrice - totalCost;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطا: کاربر وارد نشده است")),
      );
      return;
    }

    final transactionData = {
      'customer_id': _selectedCustomerId,
      'customer_name': _selectedCustomerId != null ? _selectedCustomerName : "مشتری متفرقه (کارت $operator)",
      'customer_type': _selectedCustomerId != null ? 'REGISTERED' : 'WALK_IN',
      'transaction_type': 'PAPER',
      'operator_name': operator.toUpperCase(),
      'sent_amount': amount.toDouble(),
      'quantity': quantity,
      'total_price': totalPrice,
      'paid_amount': cashReceived,
      'remaining_amount': remaining,
      'received_amount': cashReceived,
      'cost_price': totalCost,
      'profit': profit,
      'company_code': '',
      'phone_number': '',
      'ussd_command': 'PAPER_SALE',
      'created_at': DateTime.now().toIso8601String(),
    };

    print("Debug: Searching for Operator: ${operator.toLowerCase()} with Value: $amount");
    try {
      await DatabaseHelper.instance.saveDetailedTransaction(transactionData,user);
      await DatabaseHelper.instance.decreasePaperStock(currentOperator, amount, quantity,user.shopId);
      ref.invalidate(transactionsProvider);
      ref.invalidate(todayProfitProvider);
      ref.invalidate(todayCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(remaining > 0
                ? 'فروش ثبت شد. مانده بدهی: ${remaining.toStringAsFixed(0)}'
                : 'فروش نقدی با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );

        paidCtrl.clear();
        _searchController.clear();
        setState(() { _selectedCustomerId = null; });
      }
    } catch (e) {
      _showErrorDialog('خطا در ثبت فروش: $e');
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
      final user = ref.read(currentUserProvider);
      try {
        print('جستجو برای: $query');

        List<Map<String, dynamic>> results = [];

        try {
          results = await DatabaseHelper.instance.searchCustomers(query,user!.shopId);
          print('تعداد نتایج: ${results.length}');

          if (results.isNotEmpty) {
            print('اولین نتیجه: ${results.first}');
          }
        } catch (e) {
          print('خطا در searchCustomers: $e');

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
            borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
            color: Colors.white,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
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
                    padding: EdgeInsets.all(12.r), // ریسپانسیو
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r), // ریسپانسیو
                        topRight: Radius.circular(12.r), // ریسپانسیو
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_search, color: Colors.red, size: 20.sp), // ریسپانسیو
                        SizedBox(width: 8.w), // ریسپانسیو
                        Text(
                          '${_searchResults.length} مشتری یافت شد',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp, // ریسپانسیو
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 18.sp), // ریسپانسیو
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, // ریسپانسیو
                              vertical: 12.h, // ریسپانسیو
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: Icon(
                                Icons.person,
                                size: 20.sp, // ریسپانسیو
                                color: Colors.red,
                              ),
                            ),
                            title: Text(
                              customer['name']?.toString() ?? 'بدون نام',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp, // ریسپانسیو
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (customer['customer_code'] != null)
                                  Text(
                                    'کد: ${customer['customer_code']}',
                                    style: TextStyle(
                                      fontSize: 12.sp, // ریسپانسیو
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (customer['phone'] != null)
                                  Text(
                                    'تلفن: ${customer['phone']}',
                                    style: TextStyle(
                                      fontSize: 12.sp, // ریسپانسیو
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w, // ریسپانسیو
                                vertical: 4.h, // ریسپانسیو
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6.r), // ریسپانسیو
                              ),
                              child: Text(
                                customer['type'] == 'WHOLESALE' ? 'عمده' : 'عادی',
                                style: TextStyle(
                                  fontSize: 11.sp, // ریسپانسیو
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
      padding: EdgeInsets.all(24.r), // ریسپانسیو
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 50.sp, color: Colors.grey.shade400), // ریسپانسیو
          SizedBox(height: 12.h), // ریسپانسیو
          Text(
            'مشتری با این نام یافت نشد',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14.sp, // ریسپانسیو
            ),
          ),
          SizedBox(height: 16.h), // ریسپانسیو
          ElevatedButton.icon(
            onPressed: () {
              _removeOverlay();
            },
            icon: Icon(Icons.add, size: 18.sp), // ریسپانسیو
            label: Text(
              'افزودن مشتری جدید',
              style: TextStyle(fontSize: 14.sp), // ریسپانسیو
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
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
    // مقداردهی اولیه ScreenUtil
    ScreenUtil.init(context, designSize: const Size(360, 800));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('اپراتور فعلی در paper_card_screen: $operator');
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff8f6f6),
        appBar: _buildAppBar(),
        bottomNavigationBar: _buildBottomBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.r), // ریسپانسیو
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- جستجوی مشتری ----------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h, right: 4.w), // ریسپانسیو
                    child: Text(
                      'اطلاعات خریدار',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp, // ریسپانسیو
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  Container(
                    key: _searchBoxKey,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r), // ریسپانسیو
                      border: Border.all(
                        color: _selectedCustomerId != null ? Colors.green.shade300 : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w), // ریسپانسیو
                              child: _isSearching
                                  ? SizedBox(
                                width: 20.w, // ریسپانسیو
                                height: 20.h, // ریسپانسیو
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA2A33)),
                              )
                                  : Icon(
                                _selectedCustomerId != null ? Icons.person_rounded : Icons.search_rounded,
                                color: _selectedCustomerId != null ? Colors.green : Colors.grey.shade400,
                                size: 24.sp, // ریسپانسیو
                              ),
                            ),

                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'نام مشتری را جستجو کنید...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp), // ریسپانسیو
                                  contentPadding: EdgeInsets.symmetric(vertical: 16.h), // ریسپانسیو
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),

                            if (_searchController.text.isNotEmpty || _selectedCustomerId != null)
                              IconButton(
                                icon: Icon(Icons.close_rounded, size: 18.sp), // ریسپانسیو
                                onPressed: _clearCustomer,
                                color: Colors.grey.shade400,
                              ),
                          ],
                        ),

                        if (_selectedCustomerName != null)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h), // ریسپانسیو
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16.r), // ریسپانسیو
                                bottomRight: Radius.circular(16.r), // ریسپانسیو
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 18.sp), // ریسپانسیو
                                SizedBox(width: 8.w), // ریسپانسیو
                                Text(
                                  'مشتری تایید شد: ',
                                  style: TextStyle(color: Colors.green.shade700, fontSize: 13.sp), // ریسپانسیو
                                ),
                                Text(
                                  _selectedCustomerName!,
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 14.sp, // ریسپانسیو
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // -----------------------------------------------
              SizedBox(height: 24.h), // ریسپانسیو
              _sectionTitle('شرکت مخابراتی'),
              SizedBox(height: 12.h), // ریسپانسیو
              _operatorGrid(),
              SizedBox(height: 24.h), // ریسپانسیو
              _sectionTitle('مقدار کریدیت (؋)'),
              SizedBox(height: 12.h), // ریسپانسیو
              _amountGrid(),
              SizedBox(height: 24.h), // ریسپانسیو
              _priceAndQuantityRow(),
              SizedBox(height: 16.h), // ریسپانسیو
              _amountInput('مقدار دریافتی (نقد)', paidCtrl, "AFN"),

              SizedBox(height: 12.h), // ریسپانسیو
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
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey), // ریسپانسیو
        ),
        SizedBox(height: 6.h), // ریسپانسیو
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
            border: BoxBorder.all(color: Colors.red.shade200),
          ),
          child: TextField(
            textDirection: TextDirection.ltr,
            cursorColor: kPrimaryColor,
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp), // ریسپانسیو
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              suffixText: suffixText,
              suffixStyle: TextStyle(fontSize: 14.sp), // ریسپانسیو
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w, // ریسپانسیو
                vertical: 14.h, // ریسپانسیو
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      title: Text(
        'فروش کارت کاغذی',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp), // ریسپانسیو
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 24.sp), // ریسپانسیو
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w), // ریسپانسیو
      child: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold), // ریسپانسیو
      ),
    );
  }

  Widget _operatorGrid() {
    final List<Map<String, dynamic>> operators = [
      {
        'title': 'افغان بیسیم',
        'value': 'awcc',
        'svgPath': 'assets/svg/awcc.svg',
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
      height: 120.h, // ریسپانسیو
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 4.w), // ریسپانسیو
        itemCount: operators.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w), // ریسپانسیو
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
        width: 110.w, // ریسپانسیو
        decoration: BoxDecoration(
          color: active ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16.r), // ریسپانسیو
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
              width: 50.w, // ریسپانسیو
              height: 50.h, // ریسپانسیو
              decoration: BoxDecoration(
                color: active ? Colors.white70 : Colors.white70,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: useSvg && svgPath != null
                    ? SizedBox(
                  width: 32.w, // ریسپانسیو
                  height: 32.h, // ریسپانسیو
                  child: SvgPicture.asset(svgPath),
                )
                    : Icon(
                  icon ?? Icons.sim_card,
                  size: 28.sp, // ریسپانسیو
                  color: active ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 10.h), // ریسپانسیو
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w), // ریسپانسیو
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp, // ریسپانسیو
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12.h, // ریسپانسیو
        crossAxisSpacing: 12.w, // ریسپانسیو
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
              borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
              border: Border.all(
                color: active ? Colors.red : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              v.toString(),
              style: TextStyle(
                fontSize: 18.sp, // ریسپانسیو
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
      padding: EdgeInsets.all(16.r), // ریسپانسیو
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قیمت فی کارت',
                  style: TextStyle(
                    fontSize: 14.sp, // ریسپانسیو
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4.h), // ریسپانسیو
                TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp, // ریسپانسیو
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'AFN',
                    suffixStyle: TextStyle(fontSize: 14.sp), // ریسپانسیو
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.h, // ریسپانسیو
                      horizontal: 8.w, // ریسپانسیو
                    ),
                  ),
                  onChanged: (v) => setState(() => price = int.tryParse(v) ?? price),
                ),
              ],
            ),
          ),

          SizedBox(width: 16.w), // ریسپانسیو

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعداد',
                  style: TextStyle(
                    fontSize: 14.sp, // ریسپانسیو
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4.h), // ریسپانسیو
                SizedBox(
                  height: 50.h, // ریسپانسیو
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp, // ریسپانسیو
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12.h, // ریسپانسیو
                        horizontal: 8.w, // ریسپانسیو
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
      padding: EdgeInsets.all(16.r), // ریسپانسیو
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
              Text(
                'مجموع قابل پرداخت',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey), // ریسپانسیو
              ),
              Text(
                '$total ؋ ',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold), // ریسپانسیو
              ),
            ],
          ),
          SizedBox(width: 16.w), // ریسپانسیو
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14.h), // ریسپانسیو
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
                ),
              ),
              icon: Icon(Icons.check_circle, size: 24.sp, color: Colors.white), // ریسپانسیو
              label: Text(
                'ثبت فروش',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp, // ریسپانسیو
                    fontWeight: FontWeight.bold
                ),
              ),
              onPressed: () {
                if (_selectedCustomerId == null) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)), // ریسپانسیو
                      titlePadding: EdgeInsets.only(top: 25.h, right: 20.w, left: 20.w), // ریسپانسیو
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h), // ریسپانسیو
                      actionsPadding: EdgeInsets.only(bottom: 15.h, left: 10.w, right: 10.w), // ریسپانسیو
                      title: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, color: const Color(0xFFEA2A33), size: 24.sp), // ریسپانسیو
                          SizedBox(width: 10.w), // ریسپانسیو
                          Text(
                            "فروش به مشتری ناشناس",
                            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold), // ریسپانسیو
                          ),
                        ],
                      ),
                      content: Text(
                        "آیا این فروش به صورت نقد و متفرقه ثبت شود؟",
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey, height: 1.5), // ریسپانسیو
                      ),
                      actions: [
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  padding: EdgeInsets.symmetric(vertical: 12.h), // ریسپانسیو
                                ),
                                child: Text(
                                  "خیر، بازگشت",
                                  style: TextStyle(fontSize: 14.sp), // ریسپانسیو
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w), // ریسپانسیو
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _processPaperSale();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEA2A33),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), // ریسپانسیو
                                  padding: EdgeInsets.symmetric(vertical: 12.h), // ریسپانسیو
                                ),
                                child: Text(
                                  "بله، ثبت شود",
                                  style: TextStyle(fontSize: 14.sp), // ریسپانسیو
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
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