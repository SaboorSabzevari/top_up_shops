import 'package:flutter/material.dart';

class DigitalTopupSalePage extends StatefulWidget {
  const DigitalTopupSalePage({super.key});

  @override
  State<DigitalTopupSalePage> createState() => _DigitalTopupSalePageState();
}

class _DigitalTopupSalePageState extends State<DigitalTopupSalePage> {
  // 🎨 Colors
  static const Color primary = Color(0xFFEA2A33);
  static const Color bgLight = Color(0xFFFCF8F8);
  static const Color surfaceLight = Colors.white;
  static const Color textMain = Color(0xFF1B0E0E);
  static const Color textMuted = Color(0xFF6B7280);

  // ---------------- State ----------------

  String customerType = 'normal'; // normal | bulk
  String selectedOperator = 'mtn';
  String commMethod = 'person';

  final customerCodeCtrl = TextEditingController();
  final customerNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final creditCtrl = TextEditingController(text: '100');
  final discountCtrl = TextEditingController(text: '0');
  final paidCtrl = TextEditingController();
  final companyCodeCtrl = TextEditingController();

  int get total =>
      (int.tryParse(creditCtrl.text) ?? 0) -
          (int.tryParse(discountCtrl.text) ?? 0);

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

  // ---------------- App Bar ----------------

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
            child: Text(
              'فروش شارژ دیجیتال',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textMain,
              ),
            ),
          ),
          const Icon(Icons.notifications, color: Colors.grey),
        ],
      ),
    );
  }

  // ---------------- Content ----------------

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _customerInputs(),
          const SizedBox(height: 20),
          _customerTypeSection(),
          const SizedBox(height: 20),
          _operatorSection(),
          const SizedBox(height: 20),
          _communicationSection(),
          const SizedBox(height: 20),
          customerType == 'normal'
              ? _phoneInput()
              : _companyCodeInput(),

          const SizedBox(height: 20),
          _paymentSection(),
        ],
      ),
    );
  }

  // ---------------- Customer ----------------

  Widget _customerInputs() {
    return Row(
      children: [
        Expanded(
          child: _input(
            label: 'کد مشتری',
            controller: customerCodeCtrl,
            keyboardType: TextInputType.number,
            hint: '1023',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _input(
            label: 'نام مشتری',
            controller: customerNameCtrl,
            hint: 'نام وارد کنید',
          ),
        ),
      ],
    );
  }

  // ---------------- Customer Type ----------------

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
        onTap: () => setState(() => customerType = keyName),
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

  // ---------------- Operators ----------------

  Widget _operatorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('انتخاب شرکت'),
        const SizedBox(height: 8),
        _cardWrapper(
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _operatorItem('afghan-pay', "Afghan-pay", Colors.yellow),
                _operatorItem('boloro', 'Boloro', Colors.red),
                _operatorItem('hesab-pay', 'Hesab-pay', Colors.green),
                _operatorItem('ستارگان متحد', 'ستارگان متحد', Colors.blue),
                _operatorItem('ام-پیسه', 'ام-پیسه', Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _operatorItem(String key, String title, Color color) {
    final selected = selectedOperator == key;
    return GestureDetector(
      onTap: () => setState(() => selectedOperator = key),
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.08) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Text(
                title.characters.first,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? textMain : textMuted,
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: primary, size: 18),
          ],
        ),
      ),
    );
  }

  // ---------------- Communication ----------------

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

  // ---------------- Phone ----------------

  Widget _phoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('شماره موبایل',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.contact_phone),
            suffixText: '+93',
            filled: true,
            fillColor: surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Payment ----------------

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
                  Text('مجموع (قابل پرداخت)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              //ببین من میخواهم یک اپلیکیشن برای ارسال شارژ دیجیتال و ثبت  تراکنش ها را در بر داشته باشد بسازم؛ قسمت لاگین اش با فایربیس را ساختم با استفاده از riverpod؛ بخش اول: ثبت مشتری دو نوع مشتری داریم ۱ـ مشتری معمولی:( نام؛ کد مشتری؛ شماره تماس ها(میتونه چندین شماره تماس داشته باشه) ۲ـ  مشتری عمده:(   نام؛ کد مشتری؛ شماره تماس؛ کد شرکت (میتونه چندین شرکت داشته باشد) و ذخیره شود. بخش دوم: ذخیره شرکت ها: دارای نام؛ کد خاص(متفاوت برای عمده و پرچون) بخش سوم: ارسال کریدیت: دو نوع مشتری( عادی و پرچون)در اینجا کد  مشتری؛ نام مشتری؛ شماره تماس مشتری اگر عمده  بود کد شرکت؛ مقدار کریدیت؛‌ تخفیف؛ مجموع؛ مقدار پرداخت شده؛ شرکت ها که در بخش دوم آمده؛ بخش چهارم: گزارشات: جستجو بر اساس نام مشتری و اینکه تراکنش های هر روز را به شکل جدول ببیند و روی هر کدام که کلیک میکند اطلاعات به شکل Read-only داشته باشم( شرکت که از طریق آن تراکنش انجام شده؛ شبکه که تراکنش به آن صورت گرفته؛ کد مشتری؛ نام؛ شماره تماس؛ مقدار؛ تخفیف؛ مجموع کریدیت؛ محاسبه باقیات؛ ساعت تراکنش؛ تاریخ تراکنش؛ بخش پنجم: نمایش لیست تراکنش ها بر اساس بازه زمانی و شرکن
              Text(
                '$total AFN',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _amountInput('مقدار پرداخت شده', paidCtrl),
        ],
      ),
    );
  }

  // ---------------- Bottom ----------------

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
        onPressed: () {},
        icon: const Icon(Icons.sim_card),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBtn ? primary : surfaceLight,
          foregroundColor: primaryBtn ? Colors.white : primary,
          side: primaryBtn ? null : const BorderSide(color: primary, width: 2),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ---------------- Shared ----------------

  Widget _input({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _amountInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            suffixText: 'AFN',
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
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

Widget _companyCodeInput() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'کد شرکت',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: companyCodeCtrl,
        keyboardType: TextInputType.text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.business),
          hintText: 'مثال: CO-4587',
          filled: true,
          fillColor: surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    ],
  );
}}
