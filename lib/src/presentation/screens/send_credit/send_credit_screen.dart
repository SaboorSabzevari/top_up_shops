import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../providers/app_providers.dart'; // اطمینان حاصل کنید این ایمپورت وجود دارد
import '../customer/add_customer.dart';

class DigitalTopupSalePage extends ConsumerStatefulWidget {
  const DigitalTopupSalePage({super.key});

  @override
  ConsumerState<DigitalTopupSalePage> createState() => _DigitalTopupSalePageState();
}

class _DigitalTopupSalePageState extends ConsumerState<DigitalTopupSalePage> {
  // ---------------- State ----------------
  void _showSelectionDialog({required String title, required List<String> items, required Function(String) onSelected}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  // لیست کدهای دیلری مشتری انتخاب شده (برای استفاده در انتخاب شرکت)
  List<dynamic> _currentCustomerWholesaleCodes = [];

  // 🎨 Colors
  static const Color primary = Color(0xFFEA2A33);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Colors.white;
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textMuted = Color(0xFF6B7280);

  String customerType = 'normal'; // normal | bulk
  String selectedOperator = ''; // خالی بگذارید تا کاربر انتخاب کند یا اتوماتیک ست شود
  String commMethod = 'person';
  bool isCompanySelectionLocked = false; // قفل کردن فیلد کد شرکت

  // کنترلرها
  final customerCodeCtrl = TextEditingController();
  final customerNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final creditCtrl = TextEditingController(text: '100');
  final discountCtrl = TextEditingController(text: '0');
  final paidCtrl = TextEditingController();
  final companyCodeCtrl = TextEditingController();

  // برای جستجوی لایو
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _searchFocusNode = FocusNode();

  int get total =>
      (int.tryParse(creditCtrl.text) ?? 0) - (int.tryParse(discountCtrl.text) ?? 0);

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
                    leading: const Icon(Icons.person_search, color: textMuted),
                    title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("کد: ${customer['customer_code']} | ${customer['type'] == 'WHOLESALE' ? 'عمده' : 'عادی'}"),
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
          const Text('مشتری با این مشخصات یافت نشد'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _removeOverlay();
              Navigator.push(context, MaterialPageRoute(builder: (c) => const AddCustomerPage()));
            },
            icon: const Icon(Icons.add),
            label: const Text('ثبت مشتری جدید'),
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
          )
        ],
      ),
    );
  }

  // --- Logic انتخاب مشتری (Autofill & Selection) ---

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    // ۱. دریافت اطلاعات کامل از دیتابیس
    final fullDetails = await DatabaseHelper.instance.getCustomerFullDetails(customer['id']);

    setState(() {
      customerNameCtrl.text = customer['name']?.toString() ?? '';
      customerCodeCtrl.text = customer['customer_code']?.toString() ?? '';
      customerType = (customer['type'] == 'WHOLESALE') ? 'bulk' : 'normal';
      isCompanySelectionLocked = false;
      _currentCustomerWholesaleCodes = fullDetails['wholesale_codes'] ?? [];
    });

    // ۲. منطق مشتری عادی: انتخاب شماره تماس
    if (customerType == 'normal') {
      final List phonesList = fullDetails['phones'] ?? [];
      if (phonesList.isNotEmpty) {
        if (phonesList.length == 1) {
          phoneCtrl.text = phonesList[0]['phone_number'].toString();
        } else {
          _showSelectionDialog(
            title: 'انتخاب شماره تماس',
            items: phonesList.map((p) => p['phone_number'].toString()).toList(),
            onSelected: (val) => setState(() => phoneCtrl.text = val),
          );
        }
      }
    }
    // ۳. منطق مشتری عمده: انتخاب شرکت و کد
    else if (customerType == 'bulk') {
      _handleWholesaleSelection();
    }
  }
  void _handleWholesaleSelection() {
    if (_currentCustomerWholesaleCodes.isEmpty) return;

    _showSelectionDialog(
      title: 'انتخاب شرکت و کد دیلری',
      items: _currentCustomerWholesaleCodes.map((e) {
        // استفاده از نام دقیق ستون‌ها: company_name و company_code
        final name = e['company_name'] ?? 'نامشخص';
        final code = e['company_code'] ?? 'بدون کد';
        return "$name (کد: $code)";
      }).toList(),
      onSelected: (selectedString) {
        final selectedItem = _currentCustomerWholesaleCodes.firstWhere((e) {
          final name = e['company_name'] ?? '';
          final code = e['company_code'] ?? '';
          return "$name (کد: $code)" == selectedString;
        });

        setState(() {
          selectedOperator = selectedItem['company_name'].toString();
          companyCodeCtrl.text = selectedItem['company_code'].toString();
          isCompanySelectionLocked = true;
        });
      },
    );
  }


  // void _setCompanyData(Map<String, dynamic> companyData) {
  //   setState(() {
  //     String name = (companyData['company'] ?? '').toString();
  //     String code = (companyData['code'] ?? '').toString();
  //
  //     selectedOperator = name; // هایلایت شدن اپراتور در لیست افقی
  //     companyCodeCtrl.text = code; // پر شدن فیلد کد شرکت
  //     isCompanySelectionLocked = true; // قفل شدن انتخاب اپراتور
  //   });
  // }
  // // ---------------- UI Build ----------------
  void _setCompanyData(Map<String, dynamic> companyData) {
    setState(() {
      // چک کردن هر دو حالت نام گذاری برای اطمینان
      String name = (companyData['company'] ?? companyData['company_name'] ?? '').toString();
      String code = (companyData['code'] ?? companyData['dealer_code'] ?? '').toString();

      selectedOperator = name;
      companyCodeCtrl.text = code; // حالا کد در TextField قرار می‌گیرد
      isCompanySelectionLocked = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgLight,
        body: SafeArea(
          child: Column(
            children: [
              _appBar(context),
              Expanded(child: _content()),
            ],
          ),
        ),
        bottomNavigationBar: _bottomButtons(),
      ),
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
            icon: const Icon(Icons.arrow_forward, color: textMain),
          ),
          const Expanded(
            child: Text('فروش شارژ دیجیتال', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textMain)),
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
          CompositedTransformTarget(
            link: _layerLink,
            child: _customerInputs(),
          ),
          const SizedBox(height: 20),
          _customerTypeSection(),
          const SizedBox(height: 20),
          _operatorSection(), // بخش تغییر یافته
          const SizedBox(height: 20),
          _communicationSection(),
          const SizedBox(height: 20),
          customerType == 'normal' ? _phoneInput() : _companyCodeInput(),
          const SizedBox(height: 20),
          _paymentSection(),
        ],
      ),
    );
  }

  Widget _customerInputs() {
    return Row(
      children: [
        Expanded(
          child: _input(
            label: 'کد مشتری',
            controller: customerCodeCtrl,
            keyboardType: TextInputType.number,
            hint: 'جستجو...',
            onChanged: _onSearchChanged,
          ),
        ),
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
              _customerTypeItem(keyName: 'normal', icon: Icons.person, label: 'عادی'),
              _customerTypeItem(keyName: 'bulk', icon: Icons.inventory_2, label: 'عمده'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customerTypeItem({required String keyName, required IconData icon, required String label}) {
    final selected = customerType == keyName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            customerType = keyName;
            isCompanySelectionLocked = false;
            // اگر به حالت عادی برگشتیم، فیلد کد شرکت پاک شود
            if (keyName == 'normal') companyCodeCtrl.clear();
          });
        },
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.08) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? primary : Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? primary : textMuted),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? primary : textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Operator Section (DB Connected) ---

  Widget _operatorSection() {
    final providersAsync = ref.watch(providersListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('انتخاب شرکت (سرویس‌دهنده)'),
        const SizedBox(height: 8),
        _cardWrapper(
          SizedBox(
            height: 110,
            child: providersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('خطا در بارگذاری')),
              data: (providers) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // برای اسکرول بهتر
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final p = providers[index];
                    return _operatorItem(
                      p['name']?.toString() ?? '',
                      p['type']?.toString() ?? '',
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _operatorItem(String title, String type) {
    // بررسی اینکه آیا این شرکت (مثلاً افغان پی) انتخاب شده است یا خیر
    final isSelected = selectedOperator == title;

    return GestureDetector(
      // در بخش onTap ویجت _operatorItem
      onTap: () {
        if (isCompanySelectionLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('شرکت بر اساس کد دیلری مشتری انتخاب شده قفل شده است.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        setState(() {
          selectedOperator = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110, // عرض کمی بیشتر برای جا شدن نام شرکت‌های طولانی
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
              ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // آیکون یا لوگوی نمادین شرکت
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primary : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_center, // یا هر آیکونی که برای شرکت‌ها مناسب می‌بینید
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            // نام شرکت (افغان پی، شاهی ایزیلود و ...)
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
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle, color: primary, size: 16),
              ),
          ],
        ),
      ),
    );
  }
  // --- Other Sections ---

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
            color: selected ? primary.withOpacity(0.08) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? primary : Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? primary : textMuted),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? primary : textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('شماره موبایل', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.contact_phone),
            suffixText: '93+',
            filled: true,
            fillColor: surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
        ),
      ],
    );
  }

  Widget _companyCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('کد شرکت', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: companyCodeCtrl,
          readOnly: isCompanySelectionLocked,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isCompanySelectionLocked ? Colors.grey : Colors.black),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.business),
            hintText: 'مثال: CO-4587',
            filled: true,
            fillColor: isCompanySelectionLocked ? Colors.grey[200] : surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
        ),
      ],
    );
  }

  Widget _paymentSection() {
    return _cardWrapper(
      Column(
        children: [
          Row(
            children: [
              Expanded(child: _amountInput('مقدار کریدیت', creditCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _amountInput(' تخفیف %', discountCtrl)),
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
                  Text('مجموع (قابل پرداخت)', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text('$total AFN', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
            ],
          ),
          const SizedBox(height: 16),
          _amountInput('مقدار پرداخت شده', paidCtrl),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: surfaceLight,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(child: _simButton('SIM 1', true)),
          const SizedBox(width: 12),
          Expanded(child: _simButton('SIM 2', false)),
        ],
      ),
    );
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _amountInput(String label, TextEditingController ctrl) {
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
            suffixText: 'AFN',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}