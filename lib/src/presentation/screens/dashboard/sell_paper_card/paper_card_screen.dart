import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/local/app_database.dart';
import '../../../../providers/session_provider.dart';
import '../../../../providers/transaction_provider.dart';

import '../../customer/add_customer.dart';

class PaperTopupSalePage extends ConsumerStatefulWidget {
  const PaperTopupSalePage({super.key});

  @override
  ConsumerState<PaperTopupSalePage> createState() => _PaperTopupSalePageState();
}

class _PaperTopupSalePageState extends ConsumerState<PaperTopupSalePage> {
  // متغیرهای محاسبه فروش
  int quantity = 1;
  late TextEditingController quantityController = TextEditingController(text: quantity.toString());
  String operator = 'awcc';
  int amount = 100;
  int price = 100;
  final TextEditingController paidCtrl = TextEditingController();

  // ---------- متغیرهای جدید جستجوی مشتری (الهام گرفته از send_credit_screen) ----------
  final TextEditingController customerNameCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink(); // کلید اصلی برای چسباندن لیست به فیلد

  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  OverlayEntry? _overlayEntry;
  int? selectedCustomerId;

  // رنگ‌ها (برای هماهنگی با تم)
  static const Color primary = Color(0xFFEA2A33);
  static const Color textMuted = Color(0xFF6B7280);
  // ------------------------------------------

  @override
  void initState() {
    super.initState();
    // لیسنر برای بستن لیست جستجو وقتی فوکوس از دست می‌رود
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
    customerNameCtrl.dispose();
    paidCtrl.dispose();
    quantityController.dispose();
    super.dispose();
  }

  // ---------- منطق جستجو و Overlay (مشابه send_credit_screen) ----------

  void _onSearchChanged(String query) {
    final user = ref.read(currentUserProvider);
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _removeOverlay();
      setState(() {
        selectedCustomerId = null; // اگر متن پاک شد، انتخاب مشتری هم لغو شود
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      // جستجو در دیتابیس
      final results = await DatabaseHelper.instance.searchCustomers(query, user!.shopId);

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
        _showOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size; // استفاده از سایز صفحه یا کانتینر والد

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32.w, // تنظیم عرض متناسب با پدینگ صفحه (16 چپ + 16 راست)
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50), // فاصله عمودی از فیلد ورودی
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12.r),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250.h),
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: Icon(Icons.person, color: primary, size: 20.sp),
                    ),
                    title: Text(
                      customer['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    subtitle: Text(
                      "کد: ${customer['customer_code'] ?? '---'}",
                      style: TextStyle(fontSize: 12.sp, color: textMuted),
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

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    setState(() {
      selectedCustomerId = customer['id'];
      customerNameCtrl.text = customer['name']?.toString() ?? '';
    });
  }

  Widget _buildNotFoundWidget() {
    return Container(
      padding: EdgeInsets.all(16.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40.sp, color: Colors.grey),
          SizedBox(height: 8.h),
          Text('مشتری یافت نشد', style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 12.h),
          ElevatedButton.icon(
            onPressed: () {
              _removeOverlay();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AddCustomerPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('افزودن مشتری جدید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text("خطا", style: TextStyle(fontSize: 18.sp)),
          ],
        ),
        content: Text(msg, style: TextStyle(fontSize: 14.sp, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("متوجه شدم", style: TextStyle(color: Colors.red, fontSize: 14.sp)),
          )
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Future<void> _processPaperSale() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // بررسی موجودی
    int currentStock = await DatabaseHelper.instance.getPaperStockCount(operator, amount, user.shopId);
    if (currentStock < quantity) {
      _showErrorDialog("موجودی کافی نیست! موجودی فعلی کارت $amount ؋ $operator: $currentStock عدد");
      return;
    }

    double totalPrice = (price * quantity).toDouble();

    // اگر مشتری انتخاب شده باشد و فیلد پرداخت خالی باشد، یعنی نسیه است (پرداختی 0)
    // اگر مشتری انتخاب نشده باشد، پیش‌فرض نقد است (پرداختی = کل مبلغ)
    double defaultPaid = (selectedCustomerId == null) ? totalPrice : 0.0;

    // خواندن مبلغ پرداختی از ورودی (اگر کاربر وارد کرده باشد)
    double cashReceived = double.tryParse(paidCtrl.text) ?? defaultPaid;

    double remaining = totalPrice - cashReceived;
    double costPerUnit = amount * 0.95; // فرضی: قیمت خرید
    double totalCost = costPerUnit * quantity;
    double profit = totalPrice - totalCost;

    final transactionData = {
      'customer_id': selectedCustomerId,
      'customer_name': customerNameCtrl.text.isNotEmpty ? customerNameCtrl.text : "مشتری متفرقه (کارت $operator)",
      'customer_type': selectedCustomerId != null ? 'REGISTERED' : 'WALK_IN',
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

    try {
      await DatabaseHelper.instance.saveDetailedTransaction(transactionData, user);
      await DatabaseHelper.instance.decreasePaperStock(operator, amount, quantity, user.shopId);

      ref.invalidate(transactionsProvider);
      ref.invalidate(todayProfitProvider);
      ref.invalidate(todayCountProvider);
      ref.invalidate(todaySalesProvider);

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
        customerNameCtrl.clear();
        setState(() { selectedCustomerId = null; });
      }
    } catch (e) {
      _showErrorDialog('خطا در ثبت فروش: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 800));

    return Scaffold(

      backgroundColor: const Color(0xfff8f6f6),
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 100.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('انتخاب مشتری', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(height: 8.h),

            CompositedTransformTarget(
              link: _layerLink,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: customerNameCtrl,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'جستجوی نام مشتری...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
                    prefixIcon: Icon(
                      selectedCustomerId != null ? Icons.person_search_outlined : Icons.search,
                      color: selectedCustomerId != null ? Colors.green : primary,
                    ),
                    suffixIcon: customerNameCtrl.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        customerNameCtrl.clear();
                        setState(() {
                          selectedCustomerId = null;
                        });
                        _removeOverlay();
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                  ),
                ),
              ),
            ),
            // -----------------------------------------------------

            SizedBox(height: 24.h),
            _sectionTitle('شرکت مخابراتی'),
            SizedBox(height: 12.h),
            _operatorGrid(),
            SizedBox(height: 24.h),
            _sectionTitle('مقدار کریدیت (؋)'),
            SizedBox(height: 12.h),
            _amountGrid(),
            SizedBox(height: 24.h),
            _priceAndQuantityRow(),
            SizedBox(height: 16.h),
            _amountInput('مقدار دریافتی (نقد)', paidCtrl, "؋"),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  // --- سایر ویجت‌های UI (بدون تغییر عمده، فقط تمیزکاری) ---

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Text(
        'فروش کارت کاغذی',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.black),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 24.sp, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
    );
  }

  Widget _amountInput(String label, TextEditingController ctrl, String? suffixText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color:Colors.black,fontWeight: FontWeight.w600)),

        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: TextField(
            scrollPadding: EdgeInsets.only(bottom: 120.h),
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              suffixText: suffixText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _operatorGrid() {
    final List<Map<String, dynamic>> operators = [
      {'title': 'افغان بیسیم', 'value': 'awcc', 'svgPath': 'assets/svg/awcc.svg'},
      {'title': 'روشن', 'value': 'roshan', 'svgPath': 'assets/svg/roshan.svg'},
      {'title': 'اتصالات', 'value': 'etisalat', 'svgPath': 'assets/svg/etisalat.svg'},
      {'title': 'اتوما', 'value': 'mtn', 'svgPath': 'assets/svg/atoma.svg'},
      {'title': 'سلام', 'value': 'salaam', 'svgPath': 'assets/svg/salaam.svg'},
    ];

    return SizedBox(
      height: 110.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: operators.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final op = operators[index];
          return _operatorItem(
            title: op['title'] as String,
            value: op['value'] as String,
            svgPath: op['svgPath'] as String?,
          );
        },
      ),
    );
  }

  Widget _operatorItem({required String title, required String value, String? svgPath}) {
    final active = operator == value;
    return GestureDetector(
      onTap: () => setState(() => operator = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100.w,
        decoration: BoxDecoration(
          color: active ? primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: active ? primary : Colors.grey.shade300, width: active ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45.w,
              height: 45.h,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Center(
                child: svgPath != null
                    ? SvgPicture.asset(svgPath, width: 28.w)
                    : Icon(Icons.sim_card, size: 28.sp, color: Colors.grey),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.sp,
                color: active ? primary : Colors.grey.shade700,
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
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
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
              color: active ? primary : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: active ? primary : Colors.grey.shade300),
              boxShadow: active ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
            ),
            child: Text(
              v.toString(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _priceAndQuantityRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('قیمت فی کارت', style: TextStyle(fontSize: 12.sp, color:Colors.black,fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: '؋',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onChanged: (v) => setState(() => price = int.tryParse(v) ?? price),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تعداد', style: TextStyle(fontSize: 12.sp, color:Colors.black,fontWeight: FontWeight.w600)),

              SizedBox(height: 4.h),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() => quantity = int.tryParse(value) ?? 1);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final total = price * quantity;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('مجموع قابل پرداخت:', style: TextStyle(fontSize: 12.sp, color: Colors.black,fontWeight: FontWeight.w600)),
              SizedBox(width: 4.w),
              Text('$total ؋', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: primary)),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: Icon(Icons.check_circle, size: 16.sp, color: Colors.white),
              label: Text('ثبت فروش', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (selectedCustomerId == null) {
                  _showAnonymousSaleDialog();
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

  void _showAnonymousSaleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("فروش به مشتری ناشناس؟"),
        content: const Text("مشتری انتخاب نشده است. آیا به صورت فروش آزاد ثبت شود؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("خیر")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processPaperSale();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
            child: const Text("بله، ثبت کن"),
          ),
        ],
      ),
    );
  }
}