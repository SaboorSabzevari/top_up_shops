import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../l10n/app_localizations.dart';
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
  late final l10n = AppLocalizations.of(context)!;
  static const platform = MethodChannel('com.example.top_up_shops/ussd');

  // متغیرهای USSD
  String _ussdResponse = "";
  bool _isUssdLoading = false;
  bool _isResponseExpanded = false;

  // کنترلرها
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController customerNameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController companyCodeCtrl = TextEditingController();
  final TextEditingController creditCtrl = TextEditingController(text: '100');
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

  // --- متدهای USSD ---
  Future<void> _executeUssdAndSave(int simSlot) async {
    String ussdCode = _buildUSSDCode();

    if (ussdCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد USSD معتبر تولید نشد! فیلدها را چک کنید.')),
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

  Future<void> _executeUssdOnly(int simSlot) async {
    String ussdCode = _buildUSSDCode(); // تولید کد بر اساس فیلدها

    if (ussdCode.isEmpty || ussdCode == "*#") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لطفاً اطلاعات را کامل وارد کنید")),
      );
      return;
    }

    setState(() {
      _isUssdLoading = true;
      _ussdResponse = ""; // پاک کردن پاسخ قبلی
    });

    try {
      // فراخوانی متد کاتلین و دریافت پاسخ واقعی از اپراتور
      final String? result = await platform.invokeMethod('sendUssd', {
        "code": ussdCode,
        "slot": simSlot,
      });

      setState(() {
        // قرار دادن پاسخ مستقیم سیستم در متغیر
        _ussdResponse = result ?? "پاسخی از شبکه دریافت نشد";
      });

    } on PlatformException catch (e) {
      setState(() {
        _ussdResponse = "خطای سیستم: ${e.message}";
      });
    } catch (e) {
      setState(() {
        _ussdResponse = "خطای نامشخص رخ داد";
      });
    } finally {
      setState(() => _isUssdLoading = false);
    }
  }
  void _showUssdResponseDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("پاسخ شبکه"),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("بستن"),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('پاسخ کپی شد')),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- متدهای ذخیره تراکنش ---
  Future<void> _processAndSaveTransaction() async {
    String finalPhone = (customerType == 'normal') ? phoneCtrl.text : wholesalePhoneCtrl.text;

    try {
      String amountText = creditCtrl.text.trim();

      if (amountText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً مبلغ را وارد کنید'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      double? sentAmount = double.tryParse(amountText);

      if (sentAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مبلغ وارد شده معتبر نیست (فقط عدد وارد کنید)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً مشتری را انتخاب کنید'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final unitSettings = await DatabaseHelper.instance.getSingleUnit();
      double buyRate = unitSettings['buy_price'] ?? 0.0;
      double sellRate = unitSettings['sell_price'] ?? 0.0;

      int discount=discountCtrl.text.trim() as int;

      double costPrice = sentAmount * buyRate - discount;
      double receivedAmount = sentAmount * sellRate;
      double profit = receivedAmount - costPrice;
      String finalCode = _buildUSSDCode();

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
        await ref.refresh(transactionsProvider.future);

        ref.invalidate(todayProfitProvider);
        ref.invalidate(todayCountProvider);
        _showSuccessDialog(receivedAmount, profit, finalCode);
        ref.invalidate(transactionsProvider);
        ref.invalidate(todayProfitProvider);
        ref.invalidate(todayCountProvider);
        ref.invalidate(todaySalesProvider);      // مجموع فروش کل
        ref.invalidate(salesGrowthProvider);     // درصد افزایش نسبت به دیروز
        ref.invalidate(recentTransactionsProvider); // لیست تراکنش‌های اخیر داشبورد

        // پاکسازی فیلدها
        creditCtrl.clear();
        amountCtrl.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطای غیرمنتظره: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(double received, double profit, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(backgroundColor: Colors.white,
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
            Text('مبلغ دریافتی: $received AFN'),
            Divider(),
            Text('سود شما: ${profit.toStringAsFixed(2)} AFN'),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تایید',style: TextStyle(color: kPrimaryColor),),
          ),
        ],
      ),
    );
  }

  // --- جستجو و انتخاب مشتری ---
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

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    final fullDetails = await DatabaseHelper.instance.getCustomerFullDetails(
      customer['id'],
    );

    setState(() {
      selectedCustomerId = customer['id'];
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
    });

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
    } else if (customerType == 'bulk') {
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

      _prepareFilteredProviders();
    }
  }

  void _prepareFilteredProviders() async {
    try {
      final providersAsync = ref.read(providersListProvider);

      providersAsync.when(
        data: (providersData) {
          if (!mounted) return;

          final customerCompanyNames = _currentCustomerWholesaleCodes
              .map((e) => e['company_name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toSet();

          List<Map<String, dynamic>> filtered;
          if (customerCompanyNames.isEmpty) {
            filtered = List<Map<String, dynamic>>.from(providersData);
          } else {
            filtered = providersData.where((provider) {
              final providerName = provider['name']?.toString().trim() ?? '';
              return customerCompanyNames.contains(providerName);
            }).toList();
          }

          final otherProvider = {
            'name': 'دیگر',
            'type': 'other',
            'id': -1,
            'ordinary_code': '*999*',
            'wholesale_code': '*999*',
          };
          final allProviders = [...filtered, otherProvider];

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
          final companyCode = foundCompanyData['company_code']?.toString() ??
              foundCompanyData['dealer_code']?.toString() ??
              foundCompanyData['code']?.toString() ??
              '';

          companyCodeCtrl.text = companyCode;
          isCompanySelectionLocked = true;

          final customerPhone = foundCompanyData['phone']?.toString() ??
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
                    final Uri phoneUri = Uri(
                      scheme: 'tel',
                      path: ussdCode,
                    );

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

  // === پنل عملیات پایینی بازطراحی شده ===
  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // بخش پاسخ شبکه (فقط وقتی پاسخ وجود دارد)
          if (_ussdResponse.isNotEmpty) _buildNetworkResponseSection(),

          // دکمه ثبت تراکنش
          ElevatedButton(
            onPressed: _processAndSaveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.transactionSaveAndSubmit,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // دکمه‌های اجرای USSD در یک ردیف فشرده
          Row(
            children: [
              Expanded(
                child: _buildSimButton(
                  simNumber: 1,
                  slot: 0,
                  color: Colors.green,
                  icon: Icons.sim_card,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSimButton(
                  simNumber: 2,
                  slot: 1,
                  color: Colors.blue,
                  icon: Icons.sim_card_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        content: SingleChildScrollView(
          child: SelectableText(_ussdResponse),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _ussdResponse));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('پاسخ کپی شد')),
              );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
              l10n.transactionHistory,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
          _buildUssdRedesignSection()
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
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
            border: BoxBorder.all(
                
                color: Colors.red.shade200)
          ),
          child: TextField(textDirection: TextDirection.ltr,
            cursorColor: kPrimaryColor,
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              suffixText: suffixText,
              border:OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none
              )
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
      onTap: _isUssdLoading ? null : () => _executeUssdOnly(slot), // فقط اجرای USSD
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
                  color: Colors.white
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
              color: _isUssdLoading ? Colors.blue[100]! : const Color(0xFFDCFCE7),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
              )
                  : const Icon(Icons.quickreply_outlined, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isUssdLoading ? "در حال دریافت پاسخ از شبکه..." : "پاسخ دریافت شده:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isUssdLoading ? Colors.blue[800] : const Color(0xFF166534),
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
                        fontFamily: 'monospace', // برای خوانایی بهتر کدهای عددی در پیام
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
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _processAndSaveTransaction, // فقط ذخیره در دیتابیس
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}