import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:top_up_shops/src/presentation/screens/setting/edit_profile_screen.dart';

import '../../../../data/local/app_database.dart';

enum PurchaseType { paperCard, sentCredit }

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  double unitBuyPrice = 0.0;
  double unitSellPrice = 0.0;
  bool _isLoadingUnitRates = false;
  List<Map<String, dynamic>> _digitalProviders = [];
  bool _isLoadingProviders = false;

  Future<void> _loadDigitalProviders() async {
    if (mounted) {
      setState(() => _isLoadingProviders = true);
    }

    try {
      // از DatabaseHelper برای دریافت لیست پروایدرها استفاده کنید
      final providers = await DatabaseHelper.instance.getProviders();

      if (mounted) {
        setState(() {
          _digitalProviders = providers;

          // تنظیم پروایدر پیش‌فرض
          if (providers.isNotEmpty && _selectedProvider.isEmpty) {
            _selectedProvider = providers.first['name']?.toString() ?? '';
          }
        });
      }
    } catch (e) {
      print('خطا در بارگذاری لیست پروایدرها: $e');

      // در صورت خطا، لیست پیش‌فرض از send_credit_screen
      if (mounted) {
        setState(() {
          _digitalProviders = [
            {'name': 'ستارگان متحد'},
            {'name': 'اکتیو سرویس'},
            {'name': 'افغان پی'},
            {'name': 'شاهی ایزیلود'},
            {'name': 'شرکت مخابراتی آریان'}
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProviders = false);
      }
    }
  }
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUnitRates();
    _loadDigitalProviders(); // ← اضافه کردن این خط
    _calculateTotal();
  }

  // متد جدید: بارگذاری unit buy_price و sell_price
  Future<void> _loadUnitRates() async {
    setState(() => _isLoadingUnitRates = true);

    try {
      final unit = await DatabaseHelper.instance.getSingleUnit();
      if (mounted) {
        setState(() {
          unitBuyPrice = unit['buy_price'] ?? 0.95; // پیش‌فرض 0.95
          unitSellPrice = unit['sell_price'] ?? 0.96; // پیش‌فرض 0.96

          // تنظیم پیش‌فرض برای قیمت فی واحد در کریدیت دیجیتال
          if (_selectedType == PurchaseType.sentCredit) {
            _costPerUnitController.text = unitBuyPrice.toStringAsFixed(2);
            _calculateTotal(); // محاسبه مجدد با نرخ جدید
          }
        });
      }
    } catch (e) {
      print('خطا در بارگذاری نرخ‌ها: $e');
      // در صورت خطا، مقادیر پیش‌فرض
      setState(() {
        unitBuyPrice = 0.95;
        unitSellPrice = 0.96;
      });
    } finally {
      setState(() => _isLoadingUnitRates = false);
    }
  }

  PurchaseType _selectedType = PurchaseType.sentCredit;

   final List<String> _providers = [
    'ستارگان متحد',
    'اکتیو سرویس',
    'افغان پی',
    'شاهی ایزیلود',
  ];

  // Selected values
  String _selectedOperator = 'روشن'; // برای نمایش در UI
  String _selectedOperatorValue = 'roshan'; // برای ذخیره در دیتابیس <- این باید اضافه شود
  String _selectedProvider = 'ستارگان متحد';
  int _selectedFaceValue = 100;

  // Controllers
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _costPerUnitController = TextEditingController();
  final TextEditingController _totalPaidController = TextEditingController();
  final TextEditingController _totalCreditController = TextEditingController(text: '10000');

  // Additional controllers for PurchaseScreen UI
  final TextEditingController _unitPriceController = TextEditingController(text: '0.91');
  final TextEditingController _cardAmountController = TextEditingController(text: '100');
  final TextEditingController _cardPriceController = TextEditingController(text: '92');
  final TextEditingController _supplierNameController = TextEditingController();

  // Operator images (for PurchaseScreen UI)
  final List<Map<String, dynamic>> _paperCardOperators = [
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

  // لیست مقادیر کارت از paper_card_screen.dart
  final List<int> _cardDenominations = [50, 100, 150, 200, 250, 500];


  void _initializeControllers() {
    // Set initial values
    _costPerUnitController.text = '92';
    _supplierNameController.text = _selectedProvider;
    _totalPaidController.text = '0';
  }

  // Logic from PurchasePage
  // void _calculateTotal() {
  //   double unitPrice = double.tryParse(_costPerUnitController.text) ?? 0;
  //
  //   if (_selectedType == PurchaseType.paperCard) {
  //     int qty = int.tryParse(_quantityController.text) ?? 0;
  //     _totalPaidController.text = (qty * unitPrice).toStringAsFixed(0);
  //     _cardPriceController.text = unitPrice.toStringAsFixed(0);
  //   } else {
  //     double credit = double.tryParse(_totalCreditController.text) ?? 0;
  //     _totalPaidController.text = (credit * unitPrice).toStringAsFixed(0);
  //     _unitPriceController.text = unitPrice.toStringAsFixed(2);
  //   }
  //
  //   setState(() {});
  // }
  void _calculateTotal() {
    if (_isLoadingUnitRates) return;

    if (_selectedType == PurchaseType.paperCard) {
      // محاسبات کارت کاغذی (بدون تغییر)
      double unitPrice = double.tryParse(_costPerUnitController.text) ?? 0;
      int qty = int.tryParse(_quantityController.text) ?? 0; 
      _totalPaidController.text = (qty * unitPrice).toStringAsFixed(0);
      _cardPriceController.text = unitPrice.toStringAsFixed(0);
    } else {
      // محاسبات کریدیت دیجیتال با unit buy_price
      double credit = double.tryParse(_totalCreditController.text) ?? 0;

      // استفاده از unitBuyPrice به جای ورودی کاربر
      double buyPricePerUnit = unitBuyPrice;

      // مبلغ پرداختی = مقدار کریدیت × unit buy_price
      double totalPaid = credit * buyPricePerUnit;

      // به‌روزرسانی کنترلرها
      _totalPaidController.text = totalPaid.toStringAsFixed(0);
      _costPerUnitController.text = buyPricePerUnit.toStringAsFixed(2);
      _unitPriceController.text = buyPricePerUnit.toStringAsFixed(2);

      // نمایش اطلاعات نرخ
      print('unitBuyPrice: $unitBuyPrice, unitSellPrice: $unitSellPrice');
      print('مقدار کریدیت: $credit, مبلغ پرداختی: $totalPaid');
    }

    setState(() {});
  }
  void _selectOperator(int index) {
    if (index < 0 || index >= _paperCardOperators.length) return;

    setState(() {
      _selectedOperator = _paperCardOperators[index]['title'] as String;
      _selectedOperatorValue = _paperCardOperators[index]['value'] as String; // ذخیره value

      // برای دیباگ
      print('اپراتور انتخاب شد: title=$_selectedOperator, value=$_selectedOperatorValue');
    });
  }
  void _selectFaceValue(int value) {
    setState(() {
      _selectedFaceValue = value;
      _calculateTotal();
    });
  }
  double _getTotalAmount() {
    if (_selectedType == PurchaseType.paperCard) {
      final cardCount = int.tryParse(_quantityController.text) ?? 0;
      final cardPrice = double.tryParse(_costPerUnitController.text) ?? 0;
      return cardCount * cardPrice;
    } else {
      final creditAmount = double.tryParse(_totalCreditController.text) ?? 0;
      final unitPrice = double.tryParse(_costPerUnitController.text) ?? 0;
      return creditAmount * unitPrice;
    }
  }

  void _submitPurchase() async {
    final total = _getTotalAmount();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // آیکون و عنوان
                const Icon(Icons.shopping_basket_outlined, size: 48, color: Color(0xFFEA2A33)),
                const SizedBox(height: 16),
                const Text(
                  'بررسی نهایی خرید',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // بخش جزئیات محصول در یک باکس خاکستری
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDialogRow('نوع محصول:', _selectedType == PurchaseType.paperCard ? 'کارت کاغذی' : 'کریدیت ارسالی'),
                      const Divider(height: 20),
                      if (_selectedType == PurchaseType.paperCard) ...[
                        _buildDialogRow('اپراتور:', _selectedOperator),
                        _buildDialogRow('ارزش کارت:', '$_selectedFaceValue AFN'),
                        _buildDialogRow('تعداد:', '${_quantityController.text} عدد'),
                      ] else ...[
                        _buildDialogRow('تأمین‌کننده:', _selectedProvider),
                        _buildDialogRow('مقدار کریدیت:', '${_totalCreditController.text} AFN'),
                      ],
                      const Divider(height: 20),
                      _buildDialogRow('قیمت خرید (فی):', '${_costPerUnitController.text} AFN'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // بخش قیمت کل
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مجموع قابل پرداخت:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${total.toStringAsFixed(0)} AFN',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEA2A33),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // دکمه‌های عملیاتی
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('اصلاح اطلاعات', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _savePurchase();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA2A33),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('تأیید و ثبت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ویجت کمکی برای ردیف‌های دیالوگ
  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // Save logic from PurchasePage
  Future<void> _savePurchase() async {
    try {
      Map<String, dynamic> purchaseData = {
        'type': _selectedType == PurchaseType.paperCard ? 'PAPER' : 'DIGITAL',
        'provider_name': _selectedProvider,
        'payment_status': _paymentStatus,
        'payment_date': _paymentStatus == 'PENDING' ? null : DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };
      if (_selectedType == PurchaseType.paperCard) {
        // کارت کاغذی
        int quantity = int.tryParse(_quantityController.text) ?? 0;

        // برای دیباگ
        print('در حال افزایش موجودی: operator=$_selectedOperatorValue, faceValue=$_selectedFaceValue, quantity=$quantity');

        await DatabaseHelper.instance.increasePaperStock(
            _selectedOperatorValue, // این مهم است!
            _selectedFaceValue,
            quantity
        );
      } else {
        // کریدیت دیجیتال
        double creditAmount = double.tryParse(_totalCreditController.text) ?? 0;

        await DatabaseHelper.instance.increaseProviderBalance(
            _selectedProvider, // مثلا "افغان پی"
            creditAmount // مثلا 20000
        );
      }
      if (_selectedType == PurchaseType.paperCard) {
        // کارت کاغذی
        double unitPrice = double.tryParse(_costPerUnitController.text) ?? 0;
        int quantity = int.tryParse(_quantityController.text) ?? 0;
        double nominalPrice = unitPrice * quantity;
        double actualPaid = double.tryParse(_actualPaidController.text) ?? nominalPrice;

        purchaseData.addAll({
          'operator_name': _selectedOperator,
          'face_value': _selectedFaceValue,
          'quantity': quantity,
          'cost_per_unit': unitPrice,
          'nominal_price': nominalPrice,
          'actual_paid': actualPaid,
          'discount_amount': nominalPrice - actualPaid,
        });
      } else {
        // کریدیت دیجیتال
        double creditAmount = double.tryParse(_totalCreditController.text) ?? 0;
        double nominalPrice = creditAmount * unitBuyPrice; // مبلغ اسمی
        double actualPaid = double.tryParse(_actualPaidController.text) ?? nominalPrice;

        purchaseData.addAll({
          'total_credit': creditAmount,
          'cost_per_unit': unitBuyPrice,
          'nominal_price': nominalPrice,
          'actual_paid': actualPaid,
          'discount_amount': nominalPrice - actualPaid,
        });
      }

      // ذخیره در دیتابیس با جدول جدید
      final purchaseId = await DatabaseHelper.instance.insertPurchase(purchaseData);

      // نمایش موفقیت
      _showSuccessMessage(purchaseData);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطا: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessMessage(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false, // کاربر حتما باید دکمه تایید را بزند
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // آیکون تایید با پس‌زمینه دایره‌ای سبز
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 60, color: Colors.green),
                ),
                const SizedBox(height: 20),
                const Text(
                  'خرید با موفقیت ثبت شد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'اطلاعات خرید در انبار و سوابق ذخیره گردید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // بخش رسید (Receipt Detail)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (data['type'] == 'DIGITAL') ...[
                        _buildSuccessRow('مقدار کریدیت:', '${data['total_credit']} AFN'),
                        _buildSuccessRow('مبلغ اسمی:', '${data['nominal_price']} AFN'),
                        const Divider(height: 20),
                        _buildSuccessRow('مبلغ پرداختی:', '${data['actual_paid']} AFN', isBold: true),
                      ] else ...[
                        // برای حالت کارت کاغذی (در صورت نیاز)
                        _buildSuccessRow('اپراتور:', _selectedOperator ?? '-'),
                        _buildSuccessRow('تعداد:', '${data['quantity']} عدد'),
                        const Divider(height: 20),
                        _buildSuccessRow('مجموع پرداخت:', '${data['actual_paid']} AFN', isBold: true),
                      ],

                      // نمایش تخفیف به صورت سبز و متمایز
                      if (data['discount_amount'] != null && data['discount_amount'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(top:8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('تخفیف دریافتی:', style: TextStyle(color: Colors.green, fontSize: 13)),
                              Text('${data['discount_amount']} AFN',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // دکمه خروج
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {

                      Navigator.pop(context); // بازگشت به صفحه قبل (اختیاری)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('متوجه شدم', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ویجت کمکی برای ردیف‌های رسید
  Widget _buildSuccessRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
          Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                fontSize: isBold ? 16 : 14,
                color: isBold ? Colors.black : Colors.black87,
              )
          ),
        ],
      ),
    );
  }
  final TextEditingController _actualPaidController = TextEditingController();

  // وضعیت پرداخت
  String _paymentStatus = 'FULL'; // FULL, PARTIAL, PENDING
  void _initializeControllers1() {
    // مقدار پیش‌فرض برای پرداخت واقعی (در ابتدا برابر مبلغ اسمی)
    _actualPaidController.addListener(() {
      _updatePaymentStatus();
    });
  }
  void _updatePaymentStatus() {
    double nominal = double.tryParse(_totalPaidController.text) ?? 0;
    double actual = double.tryParse(_actualPaidController.text) ?? 0;

    setState(() {
      if (actual == 0) {
        _paymentStatus = 'PENDING';
      } else if (actual < nominal) {
        _paymentStatus = 'PARTIAL';
      } else if (actual == nominal) {
        _paymentStatus = 'FULL';
      } else {
        _paymentStatus = 'OVERPAID';
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final totalAmount = _getTotalAmount();
    final nominalValue = _selectedType == PurchaseType.paperCard
        ? (_selectedFaceValue * (int.tryParse(_quantityController.text) ?? 0))
        : (double.tryParse(_totalCreditController.text) ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F8),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('ثبت خرید'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFCF8F8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purchase Type Toggle
            _buildTypeToggle(),
            const SizedBox(height: 24),

            // Dynamic Content based on selected type
            if (_selectedType == PurchaseType.paperCard) ...[
              // Operator Selection (PurchaseScreen style)
              _buildOperatorSelection(),
              const SizedBox(height: 24),

              // Card Denominations
              _buildCardDenominations(),
              const SizedBox(height: 24),

              // Quantity and Price
              Row(
                children: [
                  // Quantity
                  Expanded(
                    child: _buildTextField(
                      'تعداد کارت',
                      _quantityController,
                      onChanged: (_) => _calculateTotal(),
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Price per unit
                  Expanded(
                    child: _buildTextField(
                      'قیمت فی کارت',
                      _costPerUnitController,
                      onChanged: (_) => _calculateTotal(),
                      isNumber: true,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Supplier Dropdown (PurchasePage style)
              _buildDropdown(
                'شرکت تأمین‌کننده',
                _providers,
                _selectedProvider,
                    (value) {
                  setState(() {
                    _selectedProvider = value!;
                    _supplierNameController.text = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Credit Amount
              _buildTextField(
                'مقدار کریدیت',
                _totalCreditController,
                onChanged: (_) => _calculateTotal(),
                isNumber: true,
              ),
              const SizedBox(height: 16),

              // Unit Price
              // _buildTextField(
              //   'قیمت فی واحد',
              //   _costPerUnitController,
              //   onChanged: (_) => _calculateTotal(),
              //   isNumber: true,
              // ),
            ],

            const SizedBox(height: 24),

            // Total Calculation Card (Combined style)
            // Container(
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(color: const Color(0xFFE7D0D1)),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.05),
            //         blurRadius: 10,
            //         offset: const Offset(0, 4),
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     children: [
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           Text(
            //             _selectedType == PurchaseType.paperCard ? 'ارزش اسمی:' : 'کل کریدیت:',
            //             style: const TextStyle(
            //               color: Color(0xFF994D51),
            //               fontSize: 14,
            //             ),
            //           ),
            //           Text(
            //             '${nominalValue.toStringAsFixed(0)} ${_selectedType == PurchaseType.paperCard ? 'افغانی' : 'AFN'}',
            //             style: const TextStyle(
            //               fontWeight: FontWeight.bold,
            //               fontSize: 14,
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 12),
            //
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           Text(
            //             _selectedType == PurchaseType.paperCard ? 'تعداد کل:' : 'نرخ خرید:',
            //             style: const TextStyle(
            //               color: Color(0xFF994D51),
            //               fontSize: 14,
            //             ),
            //           ),
            //           Text(
            //             _selectedType == PurchaseType.paperCard
            //                 ? '${_quantityController.text} عدد'
            //                 : '${((double.tryParse(_costPerUnitController.text) ?? 0) * 100).toStringAsFixed(0)}% (${_costPerUnitController.text})',
            //             style: const TextStyle(
            //               fontWeight: FontWeight.w500,
            //               fontSize: 14,
            //             ),
            //           ),
            //         ],
            //       ),
            //
            //       const SizedBox(height: 16),
            //       const Divider(height: 1, color: Color(0xFFE7D0D1)),
            //       const SizedBox(height: 16),
            //
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           const Text(
            //             'مجموعه پرداختی',
            //             style: TextStyle(
            //               fontWeight: FontWeight.bold,
            //               fontSize: 16,
            //             ),
            //           ),
            //           Column(
            //             crossAxisAlignment: CrossAxisAlignment.end,
            //             children: [
            //               Text(
            //                 totalAmount.toStringAsFixed(0),
            //                 style: const TextStyle(
            //                   fontSize: 28,
            //                   fontWeight: FontWeight.w900,
            //                   color: Color(0xFFEA2A33),
            //                 ),
            //               ),
            //               const SizedBox(height: 4),
            //               const Text(
            //                 'افغانی',
            //                 style: TextStyle(
            //                   fontSize: 12,
            //                   fontWeight: FontWeight.bold,
            //                   color: Color(0xFF994D51),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //       SizedBox(height: 16),
            //
            //       // فیلد جدید: مبلغ واقعی پرداختی
            //       Container(
            //         padding: EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: Colors.white,
            //           borderRadius: BorderRadius.circular(12),
            //           border: Border.all(color: Color(0xFFE7D0D1)),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.black.withOpacity(0.05),
            //               blurRadius: 10,
            //               offset: Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //               children: [
            //                 Text(
            //                   '💰 اطلاعات پرداخت',
            //                   style: TextStyle(
            //                     fontSize: 16,
            //                     fontWeight: FontWeight.bold,
            //                     color: Colors.blue.shade800,
            //                   ),
            //                 ),
            //                 Container(
            //                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            //                   decoration: BoxDecoration(
            //                     color: _getStatusColor(_paymentStatus),
            //                     borderRadius: BorderRadius.circular(20),
            //                   ),
            //                   child: Text(
            //                     _getStatusText(_paymentStatus),
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       fontWeight: FontWeight.bold,
            //                       color: Colors.white,
            //                     ),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //
            //             SizedBox(height: 12),
            //
            //             // مبلغ اسمی (محاسبه شده)
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //               children: [
            //                 Text('مبلغ اسمی:', style: TextStyle(color: Colors.grey)),
            //                 Text(
            //                   '${_totalPaidController.text} AFN',
            //                   style: TextStyle(fontWeight: FontWeight.bold),
            //                 ),
            //               ],
            //             ),
            //
            //             SizedBox(height: 8),
            //
            //             // مبلغ واقعی پرداختی
            //             TextField(
            //               controller: _actualPaidController,
            //               keyboardType: TextInputType.number,
            //               decoration: InputDecoration(
            //                 labelText: 'مبلغ واقعی پرداختی',
            //                 hintText: 'مبلغی که پرداخت کردید',
            //                 prefixIcon: Icon(Icons.payments, color: Colors.green),
            //                 suffixText: 'AFN',
            //                 border: OutlineInputBorder(
            //                   borderRadius: BorderRadius.circular(8),
            //                 ),
            //                 filled: true,
            //                 fillColor: Colors.grey[50],
            //               ),
            //               onChanged: (value) {
            //                 _calculateDiscount();
            //               },
            //             ),
            //
            //             SizedBox(height: 8),
            //
            //             // نمایش تخفیف
            //             if (_paymentStatus == 'PARTIAL')
            //               Container(
            //                 padding: EdgeInsets.all(8),
            //                 decoration: BoxDecoration(
            //                   color: Colors.green[50],
            //                   borderRadius: BorderRadius.circular(8),
            //                 ),
            //                 child: Row(
            //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                   children: [
            //                     Text('🎉 تخفیف دریافتی:', style: TextStyle(color: Colors.green)),
            //                     Text(
            //                       '${_calculateDiscountAmount()} AFN',
            //                       style: TextStyle(
            //                         fontWeight: FontWeight.bold,
            //                         color: Colors.green,
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //           ],
            //         ),
            //       ),
            //
            //     ],
            //   ),
            // ),
            Column(
              children: [
                // --- بخش اول: کارت خلاصه فاکتور (Summary Card) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        _selectedType == PurchaseType.paperCard ? 'ارزش اسمی واحد:' : 'کل کریدیت:',
                        '${nominalValue.toStringAsFixed(0)} AFN',
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        _selectedType == PurchaseType.paperCard ? 'تعداد کل:' : 'نرخ خرید:',
                        _selectedType == PurchaseType.paperCard
                            ? '${_quantityController.text} عدد'
                            : '${((double.tryParse(_costPerUnitController.text) ?? 0) * 100).toStringAsFixed(0)}% (${_costPerUnitController.text})',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFF1F1F1)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'مجموعه پرداختی نهایی',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                totalAmount.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA2A33), // قرمز اصلی
                                  letterSpacing: -1,
                                ),
                              ),
                              const Text(
                                'AFN (افغانی)',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- بخش دوم: کارت عملیات پرداخت (Payment Action) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.blueGrey),
                              SizedBox(width: 8),
                              Text(
                                'جزئیات پرداخت',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          // استایل وضعیت پرداخت مشابه Badge‌های صفحه فروش
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_paymentStatus).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(_paymentStatus),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(_paymentStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // فیلد مبلغ واقعی با استایل جدید
                      TextFormField(
                        controller: _actualPaidController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'مبلغ نقد پرداختی',
                          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          hintText: 'مثلاً: 4500',
                          prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFFEA2A33)),
                          suffixText: 'AFN',
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFFEA2A33), width: 1),
                          ),
                        ),
                        onChanged: (value) => _calculateDiscount(),
                      ),

                      // بخش نمایش تخفیف دریافتی (فقط در صورت وجود)
                      if (_paymentStatus == 'PARTIAL' || (_calculateDiscountAmount() > 0))
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.celebration_outlined, size: 18, color: Colors.green),
                                const SizedBox(width: 8),
                                const Text('تخفیف خرید شما:', style: TextStyle(fontSize: 12, color: Colors.green)),
                                const Spacer(),
                                Text(
                                  '${_calculateDiscountAmount()} AFN',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),

      // Bottom Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF8F8),
          border: const Border(
            top: BorderSide(color: Color(0xFFE7D0D1), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submitPurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA2A33),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: const Color(0xFFEA2A33).withOpacity(0.2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 24),
              SizedBox(width: 8),
              Text(
                'ثبت خرید',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }
  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E4E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = PurchaseType.paperCard;
                  _calculateTotal();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedType == PurchaseType.paperCard
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedType == PurchaseType.paperCard
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  'کارت کاغذی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedType == PurchaseType.paperCard
                        ? const Color(0xFFEA2A33)
                        : const Color(0xFF994D51),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = PurchaseType.sentCredit;
                  _calculateTotal();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedType == PurchaseType.sentCredit
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedType == PurchaseType.sentCredit
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  'کریدیت ارسالی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _selectedType == PurchaseType.sentCredit
                        ? const Color(0xFFEA2A33)
                        : const Color(0xFF994D51),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'انتخاب شبکه',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B0E0E),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _paperCardOperators.length,
            itemBuilder: (context, index) {
              final operator = _paperCardOperators[index];
              final isSelected = _selectedOperator == operator['title'];

              return GestureDetector(
                onTap: () => _selectOperator(index),
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: isSelected
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEA2A33)
                                : Colors.transparent,
                            width: isSelected ? 2 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: const Color(0xFFEA2A33).withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -2),
                            ),
                          ]
                              : null,
                        ),
                        child: ClipOval(
                          child: operator['useSvg'] == true && operator['svgPath'] != null
                              ? SvgPicture.asset(
                            operator['svgPath'] as String,
                            fit: BoxFit.contain,
                          )
                              : Container(
                            color: Colors.white,
                            child: const Icon(Icons.signal_cellular_alt),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        operator['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFEA2A33)
                              : const Color(0xFF994D51),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardDenominations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مقدار کارت (افغانی)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B0E0E),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.5,
          ),
          itemCount: _cardDenominations.length,
          itemBuilder: (context, index) {
            final value = _cardDenominations[index];
            final isSelected = _selectedFaceValue == value;

            return GestureDetector(
              onTap: () => _selectFaceValue(value),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFEA2A33)
                        : const Color(0xFFE7D0D1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: const Color(0xFFEA2A33).withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFFEA2A33)
                          : const Color(0xFF994D51),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // در قسمت کریدیت ارسالی، فیلد قیمت فی واحد را اصلاح کنید
  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        Function(String)? onChanged,
        bool isNumber = false,
        bool isReadOnly = false, // پارامتر جدید
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B0E0E),
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE7D0D1)),
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(left: 16),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFFCF8F8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AFN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF994D51),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: label.contains('قیمت فی واحد') &&
                      _selectedType == PurchaseType.sentCredit,
                  // برای کریدیت دیجیتال، قیمت فی واحد فقط خواندنی است
                  keyboardType: isNumber
                      ? TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: label.contains('قیمت فی واحد')
                        ? unitBuyPrice.toStringAsFixed(2)
                        : '0',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: label.contains('قیمت فی واحد') &&
                        _selectedType == PurchaseType.sentCredit
                        ? Icon(Icons.lock, size: 16, color: Colors.grey)
                        : null,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // نمایش توضیح برای قیمت فی واحد در کریدیت دیجیتال
        if (label.contains('قیمت فی واحد') &&
            _selectedType == PurchaseType.sentCredit)
          Padding(
            padding: EdgeInsets.only(top: 4, right: 8),
            child: Text(
              'قیمت خرید از تنظیمات سیستم (قابل ویرایش نیست)',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF994D51),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> items,
      String value,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B0E0E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7D0D1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
  // رنگ وضعیت پرداخت
  Color _getStatusColor(String status) {
    switch (status) {
      case 'FULL': return Colors.green;
      case 'PARTIAL': return Colors.orange;
      case 'PENDING': return Colors.red;
      case 'OVERPAID': return Colors.blue;
      default: return Colors.grey;
    }
  }

// متن وضعیت پرداخت
  String _getStatusText(String status) {
    switch (status) {
      case 'FULL': return 'پرداخت کامل';
      case 'PARTIAL': return 'پرداخت جزئی';
      case 'PENDING': return 'در انتظار پرداخت';
      case 'OVERPAID': return 'پرداخت اضافی';
      default: return 'نامشخص';
    }
  }

// محاسبه تخفیف
  double _calculateDiscountAmount() {
    double nominal = double.tryParse(_totalPaidController.text) ?? 0;
    double actual = double.tryParse(_actualPaidController.text) ?? 0;
    return nominal - actual;
  }

  void _calculateDiscount() {
    double discount = _calculateDiscountAmount();
    if (discount > 0) {
      print('تخفیف: $discount AFN');
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPerUnitController.dispose();
    _totalPaidController.dispose();
    _totalCreditController.dispose();
    _unitPriceController.dispose();
    _cardAmountController.dispose();
    _cardPriceController.dispose();
    _supplierNameController.dispose();
    super.dispose();
  }
}