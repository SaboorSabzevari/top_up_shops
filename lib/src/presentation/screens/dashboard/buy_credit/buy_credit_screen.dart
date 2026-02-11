import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/local/app_database.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/session_provider.dart';
import '../../../theme/colors.dart';

enum PurchaseType { paperCard, sentCredit }

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  double unitBuyPrice = 0.0;
  double unitSellPrice = 0.0;
  bool _isLoadingUnitRates = false;
  List<Map<String, dynamic>> _digitalProviders = [];
  bool _isLoadingProviders = false;

  Future<void> _loadDigitalProviders() async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      print('❌ [ERROR] User is null in _loadDigitalProviders - Cannot load providers');

      final authState = ref.read(authProvider);
      print('  Auth isLoggedIn: ${authState.isLoggedIn}');
      print('  Auth user UID: ${authState.user?.uid}');

      if (mounted) {
        setState(() {
          _isLoadingProviders = false;
          _digitalProviders = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لطفاً دوباره وارد شوید'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (user.shopId.isEmpty) {
      print('⚠️ [WARNING] shopId is empty for user: ${user.uid}');
    }

    print('✅ [DEBUG] Loading providers for user: ${user.uid}, shop: ${user.shopId}');

    if (mounted) {
      setState(() => _isLoadingProviders = true);
    }

    try {
      final providers = await DatabaseHelper.instance.getProviders();

      print('📦 [DEBUG] Loaded ${providers.length} providers from database');

      if (mounted) {
        setState(() {
          _digitalProviders = providers;

          if (providers.isNotEmpty && _selectedProvider.isEmpty) {
            _selectedProvider = providers.first['name']?.toString() ?? '';
            print('🎯 [DEBUG] Set default provider to: $_selectedProvider');
          }
        });
      }
    } catch (e, stackTrace) {
      print('❌ [ERROR] خطا در بارگذاری لیست پروایدرها: $e');
      print('📝 [STACK TRACE] $stackTrace');

      if (mounted) {
        setState(() {
          _digitalProviders = [
            {'name': 'ستارگان متحد'},
            {'name': 'اکتیو سرویس'},
            {'name': 'افغان پی'},
            {'name': 'شاهی ایزیلود'},
            {'name': 'شرکت مخابراتی آریان'}
          ];
          print('🔄 [DEBUG] Using fallback providers list');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProviders = false;
          print('✅ [DEBUG] Finished loading providers');
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUnitRates();
    _loadDigitalProviders();
    _calculateTotal();
  }

  Future<void> _loadUnitRates() async {
    setState(() => _isLoadingUnitRates = true);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final unit = await DatabaseHelper.instance.getSingleUnit(user.shopId);
      if (mounted) {
        setState(() {
          unitBuyPrice = unit['buy_price'] ?? 0.95;
          unitSellPrice = unit['sell_price'] ?? 0.96;

          if (_selectedType == PurchaseType.sentCredit) {
            _costPerUnitController.text = unitBuyPrice.toStringAsFixed(2);
            _calculateTotal();
          }
        });
      }
    } catch (e) {
      print('خطا در بارگذاری نرخ‌ها: $e');
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

  String _selectedOperator = 'روشن';
  String _selectedOperatorValue = 'roshan';
  String _selectedProvider = 'ستارگان متحد';
  int _selectedFaceValue = 100;

  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _costPerUnitController = TextEditingController();
  final TextEditingController _totalPaidController = TextEditingController();
  final TextEditingController _totalCreditController = TextEditingController(text: '10000');
  final TextEditingController _unitPriceController = TextEditingController(text: '0.91');
  final TextEditingController _cardAmountController = TextEditingController(text: '100');
  final TextEditingController _cardPriceController = TextEditingController(text: '92');
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _actualPaidController = TextEditingController();

  String _paymentStatus = 'FULL';

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

  final List<int> _cardDenominations = [50, 100, 150, 200, 250, 500];

  void _initializeControllers() {
    _costPerUnitController.text = '92';
    _supplierNameController.text = _selectedProvider;
    _totalPaidController.text = '0';

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

  void _calculateTotal() {
    if (_isLoadingUnitRates) return;

    if (_selectedType == PurchaseType.paperCard) {
      double unitPrice = double.tryParse(_costPerUnitController.text) ?? 0;
      int qty = int.tryParse(_quantityController.text) ?? 0;
      _totalPaidController.text = (qty * unitPrice).toStringAsFixed(0);
      _cardPriceController.text = unitPrice.toStringAsFixed(0);
    } else {
      double credit = double.tryParse(_totalCreditController.text) ?? 0;
      double buyPricePerUnit = unitBuyPrice;
      double totalPaid = credit * buyPricePerUnit;

      _totalPaidController.text = totalPaid.toStringAsFixed(0);
      _costPerUnitController.text = buyPricePerUnit.toStringAsFixed(2);
      _unitPriceController.text = buyPricePerUnit.toStringAsFixed(2);

      print('unitBuyPrice: $unitBuyPrice, unitSellPrice: $unitSellPrice');
      print('مقدار کریدیت: $credit, مبلغ پرداختی: $totalPaid');
    }

    setState(() {});
  }

  void _selectOperator(int index) {
    if (index < 0 || index >= _paperCardOperators.length) return;

    setState(() {
      _selectedOperator = _paperCardOperators[index]['title'] as String;
      _selectedOperatorValue = _paperCardOperators[index]['value'] as String;
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)), // ریسپانسیو
        child: Container(
          padding: EdgeInsets.all(24.r), // ریسپانسیو
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r), // ریسپانسیو
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_basket_outlined, size: 48.sp, color: const Color(0xFFEA2A33)),
              Text(
                'بررسی نهایی خرید',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),

              Container(
                padding: EdgeInsets.symmetric(vertical:10.h,horizontal: 10.w), // ریسپانسیو
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16.r), // ریسپانسیو
                ),
                child: Column(
                  children: [
                    _buildDialogRow('نوع محصول:', _selectedType == PurchaseType.paperCard ? 'کارت کاغذی' : 'کریدیت ارسالی'),
                    Divider(height: 20.h), // ریسپانسیو
                    if (_selectedType == PurchaseType.paperCard) ...[
                      _buildDialogRow('اپراتور:', _selectedOperator),
                      _buildDialogRow('ارزش کارت:', '$_selectedFaceValue ؋ '),
                      _buildDialogRow('تعداد:', '${_quantityController.text} عدد'),
                    ] else ...[
                      _buildDialogRow('تأمین‌کننده:', _selectedProvider),
                      _buildDialogRow('مقدار کریدیت:', '${_totalCreditController.text} ؋ '),
                    ],
                    Divider(height: 20.h), // ریسپانسیو
                    _buildDialogRow('قیمت خرید (فی):', '${_costPerUnitController.text} ؋ '),
                  ],
                ),
              ),

              SizedBox(height: 5.h), // ریسپانسیو

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('مجموع قابل پرداخت:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)), // ریسپانسیو
                  Text(
                    '${total.toStringAsFixed(0)}؋',
                    style: TextStyle(
                      fontSize: 22.sp, // ریسپانسیو
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFEA2A33),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 5.h), // ریسپانسیو

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h), // ریسپانسیو
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), // ریسپانسیو
                      ),
                      child: Text('اصلاح اطلاعات', style: TextStyle(color: Colors.grey, fontSize: 14.sp)), // ریسپانسیو
                    ),
                  ),
                  SizedBox(width: 12.w), // ریسپانسیو
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _savePurchase();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA2A33),
                        padding: EdgeInsets.symmetric(vertical: 4.h), // ریسپانسیو
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), // ریسپانسیو
                        elevation: 0,
                      ),
                      child: Text('تأیید و ثبت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)), // ریسپانسیو
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h), // ریسپانسیو
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blueGrey, fontSize: 13.sp)), // ریسپانسیو
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)), // ریسپانسیو
        ],
      ),
    );
  }

  Future<void> _savePurchase() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception("کاربر یافت نشد. لطفاً دوباره وارد شوید.");
      }

      Map<String, dynamic> purchaseData = {
        'type': _selectedType == PurchaseType.paperCard ? 'PAPER' : 'DIGITAL',
        'provider_name': _selectedProvider,
        'payment_status': _paymentStatus,
        'payment_date': _paymentStatus == 'PENDING' ? null : DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'shop_id': user.shopId,
      };

      if (_selectedType == PurchaseType.paperCard) {
        int quantity = int.tryParse(_quantityController.text) ?? 0;

        await DatabaseHelper.instance.increasePaperStock(
            _selectedOperatorValue,
            _selectedFaceValue,
            quantity,
            user.shopId
        );

        double unitPrice = double.tryParse(_costPerUnitController.text) ?? 0;
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
        double creditAmount = double.tryParse(_totalCreditController.text) ?? 0;

        await DatabaseHelper.instance.increaseProviderBalance(
            _selectedProvider,
            creditAmount,
            user.shopId
        );

        double nominalPrice = creditAmount * unitBuyPrice;
        double actualPaid = double.tryParse(_actualPaidController.text) ?? nominalPrice;

        purchaseData.addAll({
          'total_credit': creditAmount,
          'cost_per_unit': unitBuyPrice,
          'nominal_price': nominalPrice,
          'actual_paid': actualPaid,
          'discount_amount': nominalPrice - actualPaid,
        });
      }

      await DatabaseHelper.instance.insertPurchase(purchaseData, user);

      if (mounted) {
        _showSuccessMessage(purchaseData);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ خطا در ثبت: ${e.toString()}'),
              backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  void _showSuccessMessage(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)), // ریسپانسیو
          child: Container(
            padding: EdgeInsets.all(24.r), // ریسپانسیو
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r), // ریسپانسیو
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, size: 60.sp, color: Colors.green), // ریسپانسیو
                ),
                SizedBox(height: 20.h), // ریسپانسیو
                Text(
                  'خرید با موفقیت ثبت شد',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.black87), // ریسپانسیو
                ),
                SizedBox(height: 8.h), // ریسپانسیو
                Text(
                  'اطلاعات خرید در انبار و سوابق ذخیره گردید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey), // ریسپانسیو
                ),
                SizedBox(height: 24.h), // ریسپانسیو

                Container(
                  padding: EdgeInsets.all(16.r), // ریسپانسیو
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16.r), // ریسپانسیو
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (data['type'] == 'DIGITAL') ...[
                        _buildSuccessRow('مقدار کریدیت:', '${data['total_credit']}؋'),
                        _buildSuccessRow('مبلغ اسمی:', '${data['nominal_price']} ؋'),
                        Divider(height: 20.h), // ریسپانسیو
                        _buildSuccessRow('مبلغ پرداختی:', '${data['actual_paid']} ؋', isBold: true),
                      ] else ...[
                        _buildSuccessRow('اپراتور:', _selectedOperator),
                        _buildSuccessRow('تعداد:', '${data['quantity']} عدد'),
                        Divider(height: 20.h), // ریسپانسیو
                        _buildSuccessRow('مجموع پرداخت:', '${data['actual_paid']} ؋', isBold: true),
                      ],

                      if (data['discount_amount'] != null && data['discount_amount'] > 0)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h), // ریسپانسیو
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('تخفیف دریافتی:', style: TextStyle(color: Colors.green, fontSize: 13.sp)), // ریسپانسیو
                              Text('${data['discount_amount']} ؋',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14.sp)), // ریسپانسیو
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h), // ریسپانسیو

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h), // ریسپانسیو
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)), // ریسپانسیو
                      elevation: 0,
                    ),
                    child: Text('متوجه شدم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)), // ریسپانسیو
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h), // ریسپانسیو
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blueGrey, fontSize: 13.sp)), // ریسپانسیو
          Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                fontSize: isBold ? 16.sp : 14.sp, // ریسپانسیو
                color: isBold ? Colors.black : Colors.black87,
              )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // مقداردهی اولیه ScreenUtil
    ScreenUtil.init(context, designSize: const Size(360, 800));

    final totalAmount = _getTotalAmount();
    final nominalValue = _selectedType == PurchaseType.paperCard
        ? (_selectedFaceValue * (int.tryParse(_quantityController.text) ?? 0))
        : (double.tryParse(_totalCreditController.text) ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F8),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, size: 24.sp), // ریسپانسیو
        ),
        title: Text(
          'ثبت خرید',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold), // ریسپانسیو
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFCF8F8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r), // ریسپانسیو
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeToggle(),
            SizedBox(height: 24.h), // ریسپانسیو

            if (_selectedType == PurchaseType.paperCard) ...[
              _buildOperatorSelection(),
              SizedBox(height: 24.h), // ریسپانسیو
              _buildCardDenominations(),
              SizedBox(height: 24.h), // ریسپانسیو
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'تعداد کارت',
                      _quantityController,
                      onChanged: (_) => _calculateTotal(),
                      isNumber: true,
                    ),
                  ),
                  SizedBox(width: 16.w), // ریسپانسیو
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
              SizedBox(height: 16.h), // ریسپانسیو
              _buildTextField(
                'مقدار کریدیت',
                _totalCreditController,
                onChanged: (_) => _calculateTotal(),
                isNumber: true,
              ),
              SizedBox(height: 16.h), // ریسپانسیو
            ],

            SizedBox(height: 24.h), // ریسپانسیو

            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20.r), // ریسپانسیو
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r), // ریسپانسیو
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
                        '${nominalValue.toStringAsFixed(0)} ؋ ',
                      ),
                      SizedBox(height: 12.h), // ریسپانسیو
                      _buildSummaryRow(
                        _selectedType == PurchaseType.paperCard ? 'تعداد کل:' : 'نرخ خرید:',
                        _selectedType == PurchaseType.paperCard
                            ? '${_quantityController.text} عدد'
                            : '${((double.tryParse(_costPerUnitController.text) ?? 0) * 100).toStringAsFixed(0)}% (${_costPerUnitController.text})',
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h), // ریسپانسیو
                        child: Divider(height: 1, color: const Color(0xFFF1F1F1)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مجموعه پرداختی نهایی',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black87), // ریسپانسیو
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                totalAmount.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 32.sp, // ریسپانسیو
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFEA2A33),
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                'AFN (افغانی)',
                                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey), // ریسپانسیو
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h), // ریسپانسیو

                Container(
                  padding: EdgeInsets.all(20.r), // ریسپانسیو
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r), // ریسپانسیو
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
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 20.sp, color: Colors.blueGrey), // ریسپانسیو
                              SizedBox(width: 8.w), // ریسپانسیو
                              Text(
                                'جزئیات پرداخت',
                                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold), // ریسپانسیو
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), // ریسپانسیو
                            decoration: BoxDecoration(
                              color: _getStatusColor(_paymentStatus).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
                            ),
                            child: Text(
                              _getStatusText(_paymentStatus),
                              style: TextStyle(
                                fontSize: 11.sp, // ریسپانسیو
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(_paymentStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h), // ریسپانسیو

                      TextFormField(
                        controller: _actualPaidController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp), // ریسپانسیو
                        decoration: InputDecoration(
                          labelText: 'مبلغ نقد پرداختی',
                          labelStyle: TextStyle(fontSize: 12.sp, color: Colors.grey), // ریسپانسیو
                          hintText: '',
                          prefixIcon: Icon(Icons.payments_rounded, color: const Color(0xFFEA2A33), size: 20.sp), // ریسپانسیو
                          suffixText: '؋',
                          suffixStyle: TextStyle(fontSize: 14.sp), // ریسپانسیو
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.r), // ریسپانسیو
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.r), // ریسپانسیو
                            borderSide: const BorderSide(color: Color(0xFFEA2A33), width: 1),
                          ),
                        ),
                        onChanged: (value) => _calculateDiscount(),
                      ),

                      if (_paymentStatus == 'PARTIAL' || (_calculateDiscountAmount() > 0))
                        Padding(
                          padding: EdgeInsets.only(top: 16.h), // ریسپانسیو
                          child: Container(
                            padding: EdgeInsets.all(12.r), // ریسپانسیو
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.celebration_outlined, size: 18.sp, color: Colors.green), // ریسپانسیو
                                SizedBox(width: 8.w), // ریسپانسیو
                                Text('تخفیف خرید شما:', style: TextStyle(fontSize: 12.sp, color: Colors.green)), // ریسپانسیو
                                const Spacer(),
                                Text(
                                  '${_calculateDiscountAmount()} ؋',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14.sp), // ریسپانسیو
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

      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.r), // ریسپانسیو
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
            minimumSize: Size(double.infinity, 56.h), // ریسپانسیو
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
            ),
            elevation: 4,
            shadowColor: const Color(0xFFEA2A33).withOpacity(0.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 24.sp), // ریسپانسیو
              SizedBox(width: 8.w), // ریسپانسیو
              Text(
                'ثبت خرید',
                style: TextStyle(
                  fontSize: 18.sp, // ریسپانسیو
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
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 13.sp)), // ریسپانسیو
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87)), // ریسپانسیو
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: EdgeInsets.all(4.r), // ریسپانسیو
      decoration: BoxDecoration(
        color: const Color(0xFFF0E4E5),
        borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
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
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w), // ریسپانسیو
                decoration: BoxDecoration(
                  color: _selectedType == PurchaseType.paperCard
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
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
                    fontSize: 14.sp, // ریسپانسیو
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
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w), // ریسپانسیو
                decoration: BoxDecoration(
                  color: _selectedType == PurchaseType.sentCredit
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
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
                    fontSize: 14.sp, // ریسپانسیو
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
        Text(
          'انتخاب شبکه',
          style: TextStyle(
            fontSize: 16.sp, // ریسپانسیو
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B0E0E),
          ),
        ),
        SizedBox(height: 12.h), // ریسپانسیو
        SizedBox(
          height: 100.h, // ریسپانسیو
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _paperCardOperators.length,
            itemBuilder: (context, index) {
              final operator = _paperCardOperators[index];
              final isSelected = _selectedOperator == operator['title'];

              return GestureDetector(
                onTap: () => _selectOperator(index),
                child: Container(
                  margin: EdgeInsets.only(left: 16.w), // ریسپانسیو
                  child: Column(
                    children: [
                      Container(
                        width: 64.w, // ریسپانسیو
                        height: 64.h, // ریسپانسیو
                        padding: isSelected
                            ? EdgeInsets.all(4.r) // ریسپانسیو
                            : EdgeInsets.all(2.r), // ریسپانسیو
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
                      SizedBox(height: 8.h), // ریسپانسیو
                      Text(
                        operator['title'] as String,
                        style: TextStyle(
                          fontSize: 12.sp, // ریسپانسیو
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
        Text(
          'مقدار کارت (افغانی)',
          style: TextStyle(
            fontSize: 16.sp, // ریسپانسیو
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B0E0E),
          ),
        ),
        SizedBox(height: 12.h), // ریسپانسیو
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8.w, // ریسپانسیو
            mainAxisSpacing: 8.h, // ریسپانسیو
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
                  borderRadius: BorderRadius.circular(8.r), // ریسپانسیو
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
                      fontSize: 16.sp, // ریسپانسیو
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

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        Function(String)? onChanged,
        bool isNumber = false,
        bool isReadOnly = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp, // ریسپانسیو
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B0E0E),
          ),
        ),
        SizedBox(height: 8.h), // ریسپانسیو
        Container(
          height: 56.h, // ریسپانسیو
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
            border: Border.all(color: const Color(0xFFE7D0D1)),
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(left: 16.w), // ریسپانسیو
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), // ریسپانسیو
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF8F8),
                  borderRadius: BorderRadius.circular(4.r), // ریسپانسیو
                ),
                child: Text(
                  '؋',
                  style: TextStyle(
                    fontSize: 12.sp, // ریسپانسیو
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF994D51),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: label.contains('قیمت فی واحد') &&
                      _selectedType == PurchaseType.sentCredit,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w), // ریسپانسیو
                    suffixIcon: label.contains('قیمت فی واحد') &&
                        _selectedType == PurchaseType.sentCredit
                        ? Icon(Icons.lock, size: 16.sp, color: Colors.grey) // ریسپانسیو
                        : null,
                  ),
                  style: TextStyle(
                    fontSize: 16.sp, // ریسپانسیو
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label.contains('قیمت فی واحد') &&
            _selectedType == PurchaseType.sentCredit)
          Padding(
            padding: EdgeInsets.only(top: 4.h, right: 8.w), // ریسپانسیو
            child: Text(
              'قیمت خرید از تنظیمات سیستم (قابل ویرایش نیست)',
              style: TextStyle(
                fontSize: 10.sp, // ریسپانسیو
                color: const Color(0xFF994D51),
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
          style: TextStyle(
            fontSize: 14.sp, // ریسپانسیو
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B0E0E),
          ),
        ),
        SizedBox(height: 8.h), // ریسپانسیو
        Container(
          height: 56.h, // ریسپانسیو
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r), // ریسپانسیو
            border: Border.all(color: const Color(0xFFE7D0D1)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w), // ریسپانسیو
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      fontSize: 16.sp, // ریسپانسیو
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'FULL': return Colors.green;
      case 'PARTIAL': return Colors.orange;
      case 'PENDING': return Colors.red;
      case 'OVERPAID': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'FULL': return 'پرداخت کامل';
      case 'PARTIAL': return 'پرداخت جزئی';
      case 'PENDING': return 'در انتظار پرداخت';
      case 'OVERPAID': return 'پرداخت اضافی';
      default: return 'نامشخص';
    }
  }

  double _calculateDiscountAmount() {
    double nominal = double.tryParse(_totalPaidController.text) ?? 0;
    double actual = double.tryParse(_actualPaidController.text) ?? 0;
    return nominal - actual;
  }

  void _calculateDiscount() {
    double discount = _calculateDiscountAmount();
    if (discount > 0) {
      print('تخفیف: $discount ؋ ');
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