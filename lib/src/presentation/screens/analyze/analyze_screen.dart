import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // اضافه کردن این خط
import '../../../data/local/app_database.dart';
import '../../../domain/entity/transaction.dart';
import '../../../providers/session_provider.dart';
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
        statusText = "${intl.NumberFormat('#,###').format(remaining)} افغانی ";
        statusColor = PdfColors.red900;
      } else if (remaining < 0) {
        statusLabel = "وضعیت: طلبکار";
        statusText =
            "${intl.NumberFormat('#,###').format(remaining.abs())} افغانی ";
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
                    style: pw.TextStyle(
                      font: ttfFont,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
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
                'دریافتی (افغانی)',
                'مبلغ فاکتور (افغانی)',
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
                    formattedDate =
                        "${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
                  } catch (e) {
                    formattedDate = t.createdAt;
                  }

                  final description =
                      (t.companyCode.isNotEmpty && t.companyCode != '—')
                      ? "${t.operator} (کد: ${t.companyCode})"
                      : t.operator;

                  return [
                    formattedDate,
                    intl.NumberFormat('#,###').format(t.paidAmount),
                    intl.NumberFormat('#,###').format(t.totalPrice),
                    description,
                    index + 1,
                  ];
                }),
                // ردیف جمع کل
                [
                  '',
                  intl.NumberFormat('#,###').format(totalPaid),
                  intl.NumberFormat('#,###').format(totalInvoice),
                  'مجموع کل',
                  '',
                ],
              ],
            ),
            pw.SizedBox(height: 15),

            // بخش وضعیت حساب نهایی
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
        xl.TextCellValue('مبلغ فاکتور (؋)'),
        xl.TextCellValue('مبلغ دریافتی (؋)'),
        xl.TextCellValue('تاریخ'),
      ]);

      double totalInvoice = 0;
      double totalPaid = 0;

      for (int i = 0; i < transactions.length; i++) {
        final t = transactions[i];
        totalInvoice += t.totalPrice;
        totalPaid += t.paidAmount;

        final contact = (t.companyCode.isNotEmpty && t.companyCode != '—')
            ? "کد: ${t.companyCode}"
            : _cleanPhone(t.phoneNumber);

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
      final String fileName =
          "Report_${customerName}_${DateTime.now().millisecondsSinceEpoch}.xlsx";
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
          style: TextStyle(fontFamily: 'Noto Sans Arabic', fontSize: 14.sp),
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

    final user = ref.read(currentUserProvider);

    if (user != null) {
      final results = await DatabaseHelper.instance.ajaxSearch(
        query,
        user.shopId,
      );

      if (mounted) {
        setState(() => _searchResults = results);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // مقداردهی اولیه ScreenUtil
    ScreenUtil.init(context, designSize: const Size(360, 800));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportTransactions = ref.watch(customerReportTransactionsProvider);
    final dateRange = ref.watch(reportDateRangeProvider);

    return Scaffold(
      backgroundColor: isDark ? backgroundDarkColor : backgroundLightColor,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(0),
        child: Column(
          children: [
            if (_searchResults.isNotEmpty) _buildSearchResults(isDark),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                children: [
                  if (_selectedCustomer != null) ...[
                    reportTransactions.when(
                      data: (transactions) =>
                          _buildCustomerHeader(isDark, transactions),
                      loading: () => _buildCustomerHeader(isDark, []),
                      error: (e, st) => _buildCustomerHeader(isDark, []),
                    ),
                    SizedBox(height: 8.h),
                    _buildDatePicker(context, isDark, dateRange),
                    SizedBox(height: 8.h),
                    _buildTransactionsTable(isDark, reportTransactions),
                  ] else
                    _buildEmptyState(isDark),
                ],
              ),
            ),
          ],
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
          fontSize: 18.sp,
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
                    icon: Icon(
                      Icons.ios_share,
                      color: primaryColor,
                      size: 24.w,
                    ),
                    onSelected: (value) {
                      if (value == 'pdf') {
                        _generatePdfReport(list, _selectedCustomer!['name']);
                      } else {
                        _generateExcelReport(list, _selectedCustomer!['name']);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text(
                          "خروجی PDF",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'excel',
                        child: Text(
                          "خروجی Excel",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    Center(child: CircularProgressIndicator(strokeWidth: 2.w)),
                error: (e, st) =>
                    Icon(Icons.error_outline, color: Colors.orange, size: 24.w),
              );
            },
          ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: _buildSearchBar(isDark),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        autofocus: true,
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(fontSize: 14.sp, fontFamily: 'Noto Sans Arabic'),
        decoration: InputDecoration(
          hintText: "جستجوی مشتری (نام یا کد)...",
          hintStyle: TextStyle(fontFamily: 'Noto Sans Arabic', fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, color: primaryColor, size: 24.w),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 12.h,
            horizontal: 16.w,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
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
              style: TextStyle(fontFamily: 'Noto Sans Arabic', fontSize: 14.sp),
            ),
            subtitle: Text(
              customer['customer_code'] ?? '',
              style: TextStyle(fontFamily: 'Manrope', fontSize: 12.sp),
            ),
            onTap: () {
              setState(() {
                _selectedCustomer = customer;
                _searchResults = [];
                _searchController.text = customer['name'];
              });

              ref.read(selectedCustomerIdProvider.notifier).state =
                  customer['id'];
              customer['name'];

              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomerHeader(
    bool isDark,
    List<TransactionModel> transactions,
  ) {
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30.h,
            left: -30.w,
            child: Container(
              width: 96.w,
              height: 96.h,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(100.r),
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
                        radius: 28.r,
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
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "نام مشتری",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                          Text(
                            _selectedCustomer!['name'],
                            style: TextStyle(
                              fontSize: 18.sp,
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
                      Text(
                        "کد مشتری",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        "#${_selectedCustomer!['customer_code'] ?? '---'}",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16.h),
              Divider(color: Colors.grey.withOpacity(0.3)),
              SizedBox(height: 12.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "مجموع فاکتورها",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        "${intl.NumberFormat('#,###').format(totalInvoiceAmount)} ؋ ",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "مجموع دریافتی‌ها",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        "${intl.NumberFormat('#,###').format(totalPaidAmount)} ؋ ",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
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
                            fontSize: 12.sp,
                            color: Colors.grey,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${totalRemaining.abs().toStringAsFixed(0)} ؋ ",
                      style: TextStyle(
                        fontSize: 18.sp,
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

  Widget _buildDatePicker(
    BuildContext context,
    bool isDark,
    DateTimeRange? range,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
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
              size: 24.w,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),

          SizedBox(width: 8.w),

          if (range != null) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? surfaceDarkColor.withOpacity(0.5)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 14.w,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        "${intl.DateFormat('yyyy/MM/dd').format(range.start)} - ${intl.DateFormat('yyyy/MM/dd').format(range.end)}",
                        style: TextStyle(
                          fontSize: 12.sp,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        child: Text(
                          "لغو",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFFEA2A33),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? surfaceDarkColor.withOpacity(0.5)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16.w,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "انتخاب بازه زمانی",
                        style: TextStyle(
                          fontSize: 12.sp,
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

  Widget _buildTransactionsTable(
    bool isDark,
    AsyncValue<List<TransactionModel>> transactionsAsync,
  ) {
    return transactionsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (e, _) => Center(child: Text("خطا: $e")),
      data: (list) {
        if (list.isEmpty) return _buildEmptyState(isDark);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? surfaceDarkColor : surfaceLightColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              _buildTableHeader(isDark, list.length),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  constraints: BoxConstraints(minWidth: 336.w),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5), // شماره موبایل
                      1: FlexColumnWidth(2), // فاکتور
                      2: FlexColumnWidth(2), // دریافتی
                      3: FlexColumnWidth(1.5), // تاریخ
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade50,
                        ),
                        children: [
                          _buildHeaderCell("شماره موبایل", isLeft: true),
                          _buildHeaderCell("فاکتور"),
                          _buildHeaderCell("دریافتی"),
                          _buildHeaderCell("تاریخ", hasIcon: false),
                        ],
                      ),
                      ...list.map(
                        (t) => TableRow(
                          children: [
                            _buildDataCell(
                              _cleanPhone(t.phoneNumber),
                              isLeft: true,
                              isBold: false,
                            ),
                            _buildDataCell(
                              intl.NumberFormat('#,###').format(t.totalPrice),
                            ),
                            _buildDataCell(
                              intl.NumberFormat('#,###').format(t.paidAmount),
                              color: Colors.green,
                            ),
                            _buildDataCell(
                              t.createdAt.split('T')[0],
                              isGrey: true,
                              fontSize: 10,
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
        );
      },
    );
  }

  Widget _buildTableHeader(bool isDark, int count) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "لیست تراکنش‌ها",
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              "$count مورد",
              style: TextStyle(
                fontSize: 10.sp,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label, {
    bool hasIcon = true,
    bool isLeft = false,
  }) {
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        child: Row(
          mainAxisAlignment: isLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon)
              Icon(Icons.unfold_more, size: 12.w, color: primaryColor),
            if (hasIcon) SizedBox(width: 2.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    bool isLeft = false,
    bool isBold = true,
    Color? color,
    bool isGrey = false,
    double fontSize = 11,
  }) {
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        alignment: isLeft ? Alignment.centerRight : Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isGrey ? Colors.grey : null),
              fontFamily: 'Manrope',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTable(List<TransactionModel> transactions, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width - 32.w,
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 0.5.w,
          ),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1.4), // افزایش از 1.1 به 1.4
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
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 6.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FittedBox(
                          // <--- متن را مقیاس‌بندی می‌کند تا جا شود
                          fit: BoxFit.scaleDown,
                          child: Text('شماره موبایل'),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.swap_vert, size: 14.w, color: primaryColor),
                    ],
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 6.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'مبلغ فاکتور',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.unfold_more, size: 14.w, color: primaryColor),
                    ],
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 6.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'مبلغ دریافتی',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.unfold_more, size: 14.w, color: primaryColor),
                    ],
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 6.w,
                  ),
                  child: Text(
                    'تاریخ',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;

            final bool isEvenRow = index % 2 == 0;
            final Color rowColor = isEvenRow
                ? (isDark
                      ? Colors.white.withOpacity(0.02)
                      : const Color(0xFFF9FAFB))
                : Colors.transparent;

            return TableRow(
              decoration: BoxDecoration(color: rowColor),
              children: [
                TableCell(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 6.w,
                      ),
                      child: Text(
                        _cleanPhone(transaction.phoneNumber),
                        style: TextStyle(
                          fontSize: 12.sp,
                          letterSpacing: 1.0,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 16.w,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: intl.NumberFormat(
                                '#,###',
                              ).format(transaction.totalPrice),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                                fontSize: 12.sp,
                              ),
                            ),
                            TextSpan(
                              text: ' ؋ ',
                              style: TextStyle(
                                fontSize: 10.sp,
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
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 16.w,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: intl.NumberFormat(
                                '#,###',
                              ).format(transaction.paidAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                                fontSize: 12.sp,
                              ),
                            ),
                            TextSpan(
                              text: ' ؋ ',
                              style: TextStyle(
                                fontSize: 10.sp,
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
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 2.w,
                      ),
                      child: Text(
                        transaction.createdAt.split('T')[0],
                        style: TextStyle(
                          fontSize: 11.sp,
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

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? surfaceDarkColor : surfaceLightColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_graph_rounded,
            size: 48.w,
            color: Colors.grey.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            "برای دیدن گزارش ها, نام مشتری مورد نظر را وارد کنید!",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Noto Sans Arabic',
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanPhone(String phone) {
    if (phone.contains('{') || phone.contains('phone_number')) {
      return phone.replaceAll(RegExp(r'[^0-9]'), '');
    }
    return phone;
  }
}
