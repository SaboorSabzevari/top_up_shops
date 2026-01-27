import 'dart:io';

import 'package:flutter/services.dart';

import '../../../data/local/app_database.dart';
import '../../../domain/entity/transaction.dart';
import '../../../providers/transaction_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerReportScreen extends ConsumerStatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  ConsumerState<CustomerReportScreen> createState() =>
      _CustomerReportScreenState();
}

class _CustomerReportScreenState extends ConsumerState<CustomerReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedCustomer;

  // Colors from HTML
  static const Color primaryColor = Color(0xFFEA2A33);
  static const Color primaryDarkColor = Color(0xFFC41E26);
  static const Color backgroundLightColor = Color(0xFFF8F6F6);
  static const Color backgroundDarkColor = Color(0xFF121212);
  static const Color surfaceDarkColor = Color(0xFF1E1E1E);
  static const Color surfaceLightColor = Color(0xFFFFFFFF);

  Future<void> _generatePdfReport(
      List<TransactionModel> transactions,
      String customerName,
      ) async {
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load(
        "assets/fonts/Vazirmatn-Regular.ttf",
      );
      final ttfFont = pw.Font.ttf(fontData);

       double totalInvoice = transactions.fold(
        0,
            (sum, item) => sum + item.totalPrice,
      );
      double totalPaid = transactions.fold(
        0,
            (sum, item) => sum + item.paidAmount,
      );

      double remaining = totalInvoice - totalPaid;
      String statusText = "";
      String statusLabel = "";
      PdfColor statusColor = PdfColors.black;

       if (remaining > 0) {
        statusLabel = "وضعیت: بدهکار";
        statusText = "${intl.NumberFormat('#,###').format(remaining)} AFN";
        statusColor = PdfColors.red900;
      } else if (remaining < 0) {
        statusLabel = "وضعیت: طلبکار";
        statusText = "${intl.NumberFormat('#,###').format(remaining.abs())} AFN";
        statusColor = PdfColors.green900;
      } else {
        statusLabel = "وضعیت:";
        statusText = "تسویه شده";
        statusColor = PdfColors.blue900;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) => [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    "گزارش صورت‌حساب $customerName",
                    style: pw.TextStyle(
                      font: ttfFont,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "تاریخ گزارش: ${intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}",
                    style: pw.TextStyle(font: ttfFont, fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

             pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                font: ttfFont,
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEA2A33),
              ),
              cellStyle: pw.TextStyle(font: ttfFont, fontSize: 9),
              cellAlignment: pw.Alignment.center,
              headers: [
                'تاریخ',
                'دریافتی (AFN)', // ستون دریافتی
                'مبلغ فاکتور (AFN)', // ستون فاکتور
                'شرح / اپراتور',
                'ردیف',
              ],
              data: [
                ...transactions.asMap().entries.map((entry) {
                  int index = entry.key;
                  var t = entry.value;

                  String formattedDate;
                  try {
                    DateTime dt = DateTime.parse(t.createdAt);
                    formattedDate = "${dt.year}/${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}";
                  } catch (e) {
                    formattedDate = t.createdAt;
                  }

                  final description = (t.companyCode.isNotEmpty && t.companyCode != '—')
                      ? "${t.operator} (کد: ${t.companyCode})"
                      : t.operator;

                  return [
                    formattedDate,
                    intl.NumberFormat('#,###').format(t.paidAmount),
                    intl.NumberFormat('#,###').format(t.totalPrice), // استفاده از totalPrice
                    description,
                    index + 1,
                  ];
                }),
                // ردیف جمع کل
                [
                  '',
                  intl.NumberFormat('#,###').format(totalPaid), // جمع دریافتی
                  intl.NumberFormat('#,###').format(totalInvoice), // جمع فاکتور
                  'مجموع کل',
                  '',
                ],
              ],
            ),
            pw.SizedBox(height: 15),

            // بخش وضعیت حساب نهایی (پایین فاکتور)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "تعداد تراکنش: ${transactions.length}",
                    style: pw.TextStyle(font: ttfFont, fontSize: 10),
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        statusText,
                        style: pw.TextStyle(
                          font: ttfFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text(
                        statusLabel,
                        style: pw.TextStyle(font: ttfFont, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final directory = Directory('/storage/emulated/0/Download');
      final file = File("${directory.path}/Report_$customerName.pdf");
      await file.writeAsBytes(await pdf.save());

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      _showSnackBar("PDF ذخیره شد", Colors.green);
    } catch (e) {
      _showSnackBar("خطا در PDF: $e", Colors.red);
    }
  }

  Future<void> _generateExcelReport(
      List<TransactionModel> transactions,
      String customerName,
      ) async {
    try {
      var excel = xl.Excel.createExcel();
      xl.Sheet sheetObject = excel['Report'];

      // تنظیم راست به چپ برای اکسل
      sheetObject.isRTL = true;

      // هدر جدول
      sheetObject.appendRow([
        xl.TextCellValue('ردیف'),
        xl.TextCellValue('اپراتور'),
        xl.TextCellValue('شماره/کد شرکت'),
        xl.TextCellValue('مبلغ فاکتور (AFN)'),
        xl.TextCellValue('مبلغ دریافتی (AFN)'),
        xl.TextCellValue('تاریخ'),
      ]);

      double totalInvoice = 0;
      double totalPaid = 0;

      for (int i = 0; i < transactions.length; i++) {
        final t = transactions[i];
        totalInvoice += t.totalPrice; // جمع مبلغ فاکتور
        totalPaid += t.paidAmount;    // جمع مبلغ دریافتی

        final contact = (t.companyCode.isNotEmpty && t.companyCode != '—')
            ? "کد: ${t.companyCode}"
            : t.phoneNumber;

        sheetObject.appendRow([
          xl.IntCellValue(i + 1),
          xl.TextCellValue(t.operator),
          xl.TextCellValue(contact),
          xl.DoubleCellValue(t.totalPrice),
          xl.DoubleCellValue(t.paidAmount),
          xl.TextCellValue(t.createdAt),
        ]);
      }

      // ردیف خالی جهت فاصله
      sheetObject.appendRow([xl.TextCellValue('')]);

      // ردیف مجموع کل
      sheetObject.appendRow([
        xl.TextCellValue(''),
        xl.TextCellValue(''),
        xl.TextCellValue('مجموع کل:'),
        xl.DoubleCellValue(totalInvoice),
        xl.DoubleCellValue(totalPaid),
        xl.TextCellValue(''),
      ]);

      // محاسبه وضعیت مانده
      double remaining = totalInvoice - totalPaid;
      String statusLabel;
      double displayAmount;

      if (remaining > 0) {
        statusLabel = "وضعیت نهایی: بدهکار";
        displayAmount = remaining;
      } else if (remaining < 0) {
        statusLabel = "وضعیت نهایی: طلبکار";
        displayAmount = remaining.abs();
      } else {
        statusLabel = "وضعیت نهایی: تسویه";
        displayAmount = 0;
      }

      // ردیف وضعیت نهایی
      sheetObject.appendRow([
        xl.TextCellValue(''),
        xl.TextCellValue(''),
        xl.TextCellValue(statusLabel),
        xl.DoubleCellValue(displayAmount),
        xl.TextCellValue(''),
        xl.TextCellValue(''),
      ]);

      final directory = Directory('/storage/emulated/0/Download');
      final String fileName = "Report_${customerName}_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final File file = File("${directory.path}/$fileName");

      await file.writeAsBytes(excel.save()!);
      _showSnackBar("فایل اکسل در پوشه Download ها ذخیره شد", Colors.green);
    } catch (e) {
      _showSnackBar("خطا در ذخیره اکسل: $e", Colors.red);
    }
  }
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await DatabaseHelper.instance.ajaxSearch(query);
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportTransactions = ref.watch(customerReportTransactionsProvider);
    final dateRange = ref.watch(reportDateRangeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? backgroundDarkColor : backgroundLightColor,
        appBar: _buildAppBar(isDark),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              if (_searchResults.isNotEmpty) _buildSearchResults(isDark),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    if (_selectedCustomer != null) ...[
                      reportTransactions.when(
                        data: (transactions) =>
                            _buildCustomerHeader(isDark, transactions),
                        loading: () => _buildCustomerHeader(isDark, []),
                        error: (e, st) => _buildCustomerHeader(isDark, []),
                      ),
                      const SizedBox(height: 8),
                      _buildDatePicker(context, isDark, dateRange),
                      const SizedBox(height: 8),
                      _buildTransactionsTable(isDark, reportTransactions),
                    ] else
                      _buildEmptyState(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: (isDark ? backgroundDarkColor : backgroundLightColor)
          .withOpacity(0.8),
      elevation: 0,

      title: Text(
        "گزارش تراکنش‌های مشتری",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Noto Sans Arabic',
        ),
      ),
      centerTitle: true,
      actions: [
        if (_selectedCustomer != null)
          Consumer(
            builder: (context, ref, child) {
              final transactionsAsync = ref.watch(
                customerReportTransactionsProvider,
              );

              return transactionsAsync.when(
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.ios_share, color: primaryColor),
                    onSelected: (value) {
                      if (value == 'pdf') {
                        _generatePdfReport(list, _selectedCustomer!['name']);
                      } else {
                        _generateExcelReport(list, _selectedCustomer!['name']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Text("خروجی PDF"),
                      ),
                      const PopupMenuItem(
                        value: 'excel',
                        child: Text("خروجی Excel"),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, st) =>
                    const Icon(Icons.error_outline, color: Colors.orange),
              );
            },
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildSearchBar(isDark),
        ),
      ),
    );
  }

  // Search Bar - Exact match to HTML
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        textDirection: TextDirection.ltr,
        autofocus: true,
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 14, fontFamily: 'Noto Sans Arabic'),
        decoration: const InputDecoration(
          hintText: "جستجوی مشتری (نام یا کد)...",
          hintStyle: TextStyle(fontFamily: 'Noto Sans Arabic'),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  // Search Results
  Widget _buildSearchResults(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final customer = _searchResults[index];
          return ListTile(
            title: Text(
              customer['name'],
              style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
            ),
            subtitle: Text(
              customer['customer_code'] ?? '',
              style: const TextStyle(fontFamily: 'Manrope'),
            ),
            onTap: () {
              setState(() {
                _selectedCustomer = customer;
                _searchResults = [];
                _searchController.text = customer['name'];
              });

              // اصلاح ریشه‌ای: به جای نام، آیدی را در پروایدر ست می‌کنیم
              // توجه: فیلد id باید در خروجی ajaxSearch وجود داشته باشد
              ref.read(selectedCustomerIdProvider.notifier).state =
                  customer['id'];
              customer['name'];

              // ۲. بستن کیبورد برای باز شدن فضای جدول
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  // Customer Header - Exact match to HTML with circle background
  // در تابع _buildCustomerHeader، بعد از کد موجود، اطلاعات مالی اضافه کنید:

  Widget _buildCustomerHeader(
    bool isDark,
    List<TransactionModel> transactions,
  ) {
    // محاسبه مجموع‌ها
    double totalInvoiceAmount = transactions.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    double totalPaidAmount = transactions.fold(
      0,
      (sum, item) => sum + item.paidAmount,
    );
    double totalRemaining = totalInvoiceAmount - totalPaidAmount;

    String statusText = totalRemaining > 0
        ? "بدهکار"
        : (totalRemaining < 0 ? "طلبکار" : "تسویه شده");
    Color statusColor = totalRemaining > 0
        ? Colors.red
        : (totalRemaining < 0 ? Colors.green : Colors.grey);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Circle background از قبل موجود
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFE5E7EB),
                        backgroundImage:
                            _selectedCustomer!['profile_image'] != null
                            ? FileImage(
                                File(_selectedCustomer!['profile_image']),
                              )
                            : null,
                        child: _selectedCustomer!['profile_image'] == null
                            ? Text(
                                _selectedCustomer!['name'].isNotEmpty
                                    ? _selectedCustomer!['name'][0]
                                          .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "نام مشتری",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                          Text(
                            _selectedCustomer!['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "کد مشتری",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        "#${_selectedCustomer!['customer_code'] ?? '---'}",
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // بخش جدید: اطلاعات مالی
              const SizedBox(height: 16),
              Divider(color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "مجموع فاکتورها",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        "${intl.NumberFormat('#,###').format(totalInvoiceAmount)} AFN",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "مجموع دریافتی‌ها",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        "${intl.NumberFormat('#,###').format(totalPaidAmount)} AFN",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // وضعیت بدهکاری/طلبکاری
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "وضعیت حساب",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${totalRemaining.abs().toStringAsFixed(0)} AFN",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Date Picker - Exact match to HTML
  // حذف متد _buildDatePicker فعلی و جایگزینی با این کد:

  Widget _buildDatePicker(
    BuildContext context,
    bool isDark,
    DateTimeRange? range,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // آیکون تقویم (همانند صفحه تراکنش)
          IconButton(
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                initialDateRange: range,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFFEA2A33),
                        onPrimary: Colors.white,
                        onSurface: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(reportDateRangeProvider.notifier).state = picked;
              }
            },
            icon: Icon(
              Icons.date_range_rounded,
              color: range != null ? primaryColor : Colors.grey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // نمایش تاریخ انتخاب شده (اگر وجود داشته باشد)
          if (range != null) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? surfaceDarkColor.withOpacity(0.5)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_toggle_off,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${intl.DateFormat('yyyy/MM/dd').format(range.start)} - ${intl.DateFormat('yyyy/MM/dd').format(range.end)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref.read(reportDateRangeProvider.notifier).state =
                              null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: const Text(
                          "لغو",
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFEA2A33),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // اگر تاریخی انتخاب نشده
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    ref.read(reportDateRangeProvider.notifier).state = picked;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? surfaceDarkColor.withOpacity(0.5)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        "انتخاب بازه زمانی",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Transactions Table - Exact match to HTML with independent scroll
  Widget _buildTransactionsTable(
    bool isDark,
    AsyncValue<List<TransactionModel>> transactionsAsync,
  ) {
    return transactionsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (e, stack) => Center(
        child: Text(
          "خطا در بارگذاری: $e",
          style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _buildEmptyState(isDark);
        }

        final totalAmount = list.fold<int>(
          0,
          (sum, item) => sum + item.sentAmount,
        );

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? surfaceDarkColor : surfaceLightColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "همه تراکنش‌ها",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        Text(
                          "نمایش کل سوابق دیتابیس",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "${list.length} مورد",
                        style: TextStyle(
                          fontSize: 10,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Table with Zebra Stripes
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildCustomTable(list, isDark),
                    ),
                  ),
                ),
              ),

              // Total footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  border: Border(
                    top: BorderSide(
                      color: primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "مجموع تراکنش‌ها",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFD1D5DB)
                                    : const Color(0xFF374151),
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ],
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: intl.NumberFormat(
                                  '#,###',
                                ).format(totalAmount),
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const WidgetSpan(child: SizedBox(width: 4)),
                              TextSpan(
                                text: 'AFN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ],
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "این مبلغ نمایانگر مجموع کل تراکنش‌های ثبت شده برای این کاربر در تمام دوران است.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Custom Table with Zebra Stripes
  Widget _buildCustomTable(List<TransactionModel> transactions, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width - 32,
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1.1),
          1: FlexColumnWidth(1.1),
          2: FlexColumnWidth(1.1),
          3: FlexColumnWidth(1),
        },
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
            ),
            children: [
              TableCell(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'شماره موبایل',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.swap_vert, size: 14, color: primaryColor),
                    ],
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'مبلغ فاکتور', // تغییر از 'مقدار کریدیت'
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.unfold_more, size: 14, color: primaryColor),
                    ],
                  ),
                ),
              ),
              TableCell(
                // ستون جدید برای مبلغ دریافتی
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'مبلغ دریافتی',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.unfold_more, size: 14, color: primaryColor),
                    ],
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 6,
                  ),
                  child: const Text(
                    'تاریخ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Data rows with Zebra Stripes
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;

            // Zebra Stripes effect
            final bool isEvenRow = index % 2 == 0;
            final Color rowColor = isEvenRow
                ? (isDark
                      ? Colors.white.withOpacity(0.02)
                      : const Color(0xFFF9FAFB))
                : Colors.transparent;

            // در قسمت داده‌های جدول - ردیف‌های تراکنش
            return TableRow(
              decoration: BoxDecoration(color: rowColor),
              children: [
                TableCell(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 6,
                      ),
                      child: Text(
                        transaction.phoneNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.0,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  // سلول مبلغ فاکتور
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: intl.NumberFormat(
                                '#,###',
                              ).format(transaction.totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const TextSpan(
                              text: ' AFN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  // سلول مبلغ دریافتی
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: intl.NumberFormat(
                                '#,###',
                              ).format(transaction.paidAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const TextSpan(
                              text: ' AFN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 2,
                      ),
                      child: Text(
                        transaction.createdAt.split('T')[0],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_graph_rounded,
            size: 48,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "برای دیدن گزارش ها, نام مشتری مورد نظر را وارد کنید!",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Noto Sans Arabic',
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "در این بازه زمانی هیچ فعالیتی ثبت نشده است",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontFamily: 'Noto Sans Arabic',
            ),
          ),
        ],
      ),
    );
  }
}
