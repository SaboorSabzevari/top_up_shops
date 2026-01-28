// import 'package:flutter/material.dart';
//
// class PurchaseScreen extends StatefulWidget {
//   const PurchaseScreen({super.key});
//
//   @override
//   _PurchaseScreenState createState() => _PurchaseScreenState();
// }
//
// class _PurchaseScreenState extends State<PurchaseScreen> {
//   String purchaseType = 'PAPER';
//
//   String selectedOperator = 'AWCC';
//   String selectedProvider = 'ستارگان متحد';
//   int selectedFaceValue = 100;
//
//   final TextEditingController _quantityController =
//   TextEditingController(text: '1');
//   final TextEditingController _costPerUnitController =
//   TextEditingController();
//   final TextEditingController _totalPaidController =
//   TextEditingController();
//   final TextEditingController _totalCreditController =
//   TextEditingController();
//
//   List<int> faceValues = [50, 100, 150, 200, 250, 500];
//   List<String> operators = ['AWCC', 'Roshan', 'Etisalat', 'MTN', 'Salaam'];
//   List<String> providers = [
//     'ستارگان متحد',
//     'اکتیو سرویس',
//     'افغان پی',
//     'شاهی ایزیلود'
//   ];
//
//   void _calculateTotal() {
//     double unitPrice =
//         double.tryParse(_costPerUnitController.text) ?? 0;
//     if (purchaseType == 'PAPER') {
//       int qty = int.tryParse(_quantityController.text) ?? 0;
//       _totalPaidController.text = (qty * unitPrice).toString();
//     } else {
//       double credit =
//           double.tryParse(_totalCreditController.text) ?? 0;
//       _totalPaidController.text = (credit * unitPrice).toString();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7F9),
//       appBar: AppBar(
//         title: const Text("ثبت خرید کریدیت"),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _headerCard(),
//             const SizedBox(height: 16),
//
//             _sectionCard(
//               child: SegmentedButton<String>(
//                 segments: const [
//                   ButtonSegment(
//                       value: 'PAPER', label: Text("کارت کاغذی")),
//                   ButtonSegment(
//                       value: 'DIGITAL', label: Text("کریدیت دیجیتال")),
//                 ],
//                 selected: {purchaseType},
//                 onSelectionChanged: (val) => setState(() {
//                   purchaseType = val.first;
//                   _totalPaidController.clear();
//                 }),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             _sectionCard(
//               child: Column(
//                 children: [
//                   if (purchaseType == 'PAPER') ...[
//                     _buildDropdown(
//                         "اپراتور", operators, selectedOperator,
//                             (v) => setState(() => selectedOperator = v!)),
//                     _buildDropdown(
//                         "مقدار کارت",
//                         faceValues.map((e) => e.toString()).toList(),
//                         selectedFaceValue.toString(),
//                             (v) => setState(
//                                 () => selectedFaceValue = int.parse(v!))),
//                     _buildTextField("تعداد کارت", _quantityController,
//                         isNumber: true),
//                   ] else ...[
//                     _buildDropdown(
//                         "شرکت تامین‌کننده",
//                         providers,
//                         selectedProvider,
//                             (v) =>
//                             setState(() => selectedProvider = v!)),
//                     _buildTextField(
//                         "مقدار کریدیت", _totalCreditController,
//                         isNumber: true,
//                         onChanged: (_) => _calculateTotal()),
//                   ],
//
//                   const Divider(height: 32),
//
//                   _buildTextField(
//                       "قیمت فی واحد", _costPerUnitController,
//                       isNumber: true,
//                       onChanged: (_) => _calculateTotal()),
//
//                   _buildTextField(
//                     "مبلغ کل پرداختی",
//                     _totalPaidController,
//                     isNumber: true,
//                     isReadOnly: true,
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             ElevatedButton(
//               onPressed: _savePurchase,
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 54),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14)),
//                 backgroundColor: theme.colorScheme.primary,
//               ),
//               child: const Text(
//                 "ثبت خرید",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _headerCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: const [
//           Icon(Icons.flash_on, color: Colors.white, size: 32),
//           SizedBox(width: 12),
//           Text(
//             "خرید و ثبت کریدیت",
//             style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _sectionCard({required Widget child}) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: child,
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller,
//       {bool isNumber = false,
//         Function(String)? onChanged,
//         bool isReadOnly = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextField(
//         controller: controller,
//         readOnly: isReadOnly,
//         keyboardType:
//         isNumber ? TextInputType.number : TextInputType.text,
//         onChanged: onChanged,
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: const Color(0xFFF1F3F6),
//           border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDropdown(String label, List<String> items, String value,
//       Function(String?) onChanged) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: DropdownButtonFormField<String>(
//         value: value,
//         items: items
//             .map((e) =>
//             DropdownMenuItem(value: e, child: Text(e)))
//             .toList(),
//         onChanged: onChanged,
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: const Color(0xFFF1F3F6),
//           border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none),
//         ),
//       ),
//     );
//   }
//
//   void _savePurchase() async {
//     // ← دقیقاً همان کد خودت (بدون تغییر)
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// enum PurchaseType { paperCard, sentCredit }
//
// class PurchaseScreen extends StatefulWidget {
//   const PurchaseScreen({super.key});
//
//   @override
//   State<PurchaseScreen> createState() => _PurchaseScreenState();
// }
//
// class _PurchaseScreenState extends State<PurchaseScreen> {
//   PurchaseType _selectedType = PurchaseType.sentCredit;
//   String _supplierName = 'شرکت مخابراتی آریان';
//   String _selectedOperator = 'روشن';
//   final TextEditingController _creditAmountController = TextEditingController(
//     text: '10000',
//   );
//   final TextEditingController _unitPriceController = TextEditingController(
//     text: '0.91',
//   );
//   final TextEditingController _cardAmountController = TextEditingController(
//     text: '100',
//   );
//   final TextEditingController _cardCountController = TextEditingController(
//     text: '50',
//   );
//   final TextEditingController _cardPriceController = TextEditingController(
//     text: '92',
//   );
//
//   final List<Map<String, dynamic>> _operators = [
//     {
//       'name': 'روشن',
//       'image':
//           'https://lh3.googleusercontent.com/aida-public/AB6AXuB2aVbakyNRbZ991Ix5u4YhychxInA3a-RDQCreeQE07UACnoetIgoHXYARwdfGoyuCV4Xu9BTJ3Kh5VPlOm8wrWrv8WZ6wXaiEtT-fmtz-AhTzTBWRmf7g_Dp5wOIZonXcmG96rM_OpFCpJ_dYmbj-XXPEo3YdAiCDXZLOFIBQqxNNQ3E_cOYX8nEI3frEHp7yR50Mrtz1N6auIHI63F1vCNPxRoD_7I7jYE8U3Bc130gA0gGpWmWtPMRhepDMYZuXUn_5m12iLqk',
//       'selected': true,
//     },
//     {
//       'name': 'اتصالات',
//       'image':
//           'https://lh3.googleusercontent.com/aida-public/AB6AXuDuQPPzD5qNdaoAYFHqQm_hA-B9eiPne7Uac0wx4UfjwoP-EAU6JB86LgPe_KQSHu_BQuDCr0W6yCV4f3yfHVDxnpzzrDaI34S0YwztNkEBLQZCo4I4IOkLrDAhUb95NXoAhIKYT9G5mn97ghRniD_BNJBj_fD4w9IIgpp9vR0FVIxfKAzy9HL6OmwdGgt3p8isqGweXBgwG-9zAVboU-ODH2HgdTk_S7YDiaQPFQnCQnvSFNq7j1oqtS-1xSM2jvDiDHofy8Tr_k0',
//       'selected': false,
//     },
//     {
//       'name': 'ام‌تی‌ان',
//       'image':
//           'https://lh3.googleusercontent.com/aida-public/AB6AXuDc4xo1u419xwUbcmWHn2mNIe76DOXE5gSY4i2H-tRhF90xUFXctRJYmSyQ9FNpUM2ff5Mu5yIZvnlUiUqQ6ig1L30oG1jkjrLxKfN8SJ5KQXDroh4u1Qc33W5f2LLpkUEVG4YiFb8TSOdRCdAId-3yIUro3rJJnkBv6A99m3VWpIP0vUqVeTcO34fX0WNkDDZ7ziqbxH2-q87whF5aXHsnIC4sra3Op32pS-QpqoQ7G2KnKMjrKPmGkY5J3pReRy9K0KgnKV_jMp0',
//       'selected': false,
//     },
//     {
//       'name': 'سلام',
//       'image':
//           'https://lh3.googleusercontent.com/aida-public/AB6AXuBTz4fLJCD0PBYimuThLxbm-v_mCm_svTC4vZhNkVXDKGgrRrngVr5ZBypmRZNJsMeUjm-JkGj1678rftZ1ReVFXMp_10Jtskx2vgfZwDAjZiPKqu2yfahMDRckZPYfbhg10qU4hpkxW8fzBbV8A0FdWOXTqam4i5GozVIPnRkpi7KKpEGFJtSBXXSVrtLm00uii-X24iWFGjkGWTcDBpam4edDG_L94vCdSLQPHbPnYVSDGMHKfTFkn8vhCmT7FOINiKsdiyT_k08',
//       'selected': false,
//     },
//     {
//       'name': 'افغان بیسیم',
//       'image':
//           'https://lh3.googleusercontent.com/aida-public/AB6AXuAmZh4jJ9nZHi0txiyvF-a6dRQJhtZ9O033KE8thz4pACGdlEmTJeo_6QMttf-bm9oKyvt0NukJA80cfZf3fz7C-QrLxqCLMxlzIdxZdLvfymneUwkQHP6R-HzX2DicXSOWOcPBOckH155m155gjfIhyC_F6iufL4cRszPFngJNf1kdj--R1FdDQ-g3o43-OcdDzveE0RGKe_OOUo1nWvjqDLBG8MwP3995SPxBHxX0K2IT7acSAyNYClMsLk3-qYbmG003I0Fmn0I',
//       'selected': false,
//     },
//   ];
//
//   final List<int> _cardDenominations = [50, 100, 250, 500];
//   int _selectedDenomination = 100;
//
//   @override
//   void initState() {
//     super.initState();
//     _calculateTotal();
//   }
//
//   void _calculateTotal() {
//     setState(() {
//       // محاسبه بر اساس نوع انتخاب شده
//     });
//   }
//
//   void _selectOperator(int index) {
//     setState(() {
//       for (var i = 0; i < _operators.length; i++) {
//         _operators[i]['selected'] = i == index;
//       }
//       _selectedOperator = _operators[index]['name'];
//     });
//   }
//
//   void _selectDenomination(int value) {
//     setState(() {
//       _selectedDenomination = value;
//       _cardAmountController.text = value.toString();
//     });
//   }
//
//   double _getTotalAmount() {
//     if (_selectedType == PurchaseType.sentCredit) {
//       final creditAmount = double.tryParse(_creditAmountController.text) ?? 0;
//       final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
//       return creditAmount * unitPrice;
//     } else {
//       final cardCount = int.tryParse(_cardCountController.text) ?? 0;
//       final cardPrice = double.tryParse(_cardPriceController.text) ?? 0;
//       return cardCount * cardPrice;
//     }
//   }
//
//   void _submitPurchase() {
//     // منطق ثبت خرید
//     final total = _getTotalAmount();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('تأیید خرید'),
//         content: Text(
//           'آیا از ثبت خرید به مبلغ ${total.toStringAsFixed(0)} افغانی اطمینان دارید؟',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('لغو'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                     'خرید با موفقیت ثبت شد. مبلغ: ${total.toStringAsFixed(0)} افغانی',
//                   ),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             child: const Text('تأیید'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalAmount = _getTotalAmount();
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFCF8F8),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // AppBar
//             Container(
//               height: 56,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFCF8F8).withOpacity(0.95),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Color(0x0A000000),
//                     blurRadius: 2,
//                     offset: Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.arrow_forward),
//                   ),
//                   Expanded(
//                     child: Center(
//                       child: Text(
//                         'ثبت خرید',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: const Color(0xFF1B0E0E),
//                           fontFamily: 'NotoSansArabic',
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 48), // Spacer for balance
//                 ],
//               ),
//             ),
//
//             // Main Content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Supplier Input
//                     _buildSupplierInput(),
//
//                     const SizedBox(height: 16),
//
//                     // Purchase Type Toggle
//                     _buildTypeToggle(),
//
//                     const SizedBox(height: 24),
//
//                     // Operator Selection
//                     _buildOperatorSelection(),
//
//                     const SizedBox(height: 24),
//
//                     // Dynamic Content based on selected type
//                     if (_selectedType == PurchaseType.sentCredit)
//                       _buildSentCreditForm()
//                     else
//                       _buildPaperCardForm(),
//
//                     const SizedBox(height: 24),
//
//                     // Total Calculation Card
//                     _buildTotalCard(totalAmount),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//
//       // Bottom Button
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFFFCF8F8).withOpacity(0.95),
//           border: const Border(
//             top: BorderSide(color: Color(0xFFE7D0D1), width: 1),
//           ),
//         ),
//         child: ElevatedButton(
//           onPressed: _submitPurchase,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFFEA2A33),
//             foregroundColor: Colors.white,
//             minimumSize: const Size(double.infinity, 56),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             elevation: 4,
//             shadowColor: const Color(0xFFEA2A33).withValues(alpha: 0.2),
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.check_circle, size: 24),
//               SizedBox(width: 8),
//               Text(
//                 'ثبت خرید',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'NotoSansArabic',
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSupplierInput() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'نام تأمین‌کننده',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: const Color(0xFF1B0E0E),
//             fontFamily: 'NotoSansArabic',
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 56,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: const Color(0xFFE7D0D1)),
//           ),
//           child: Row(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16),
//                 child: Icon(Icons.person_search, color: Color(0xFF994D51)),
//               ),
//               Expanded(
//                 child: TextField(
//                   controller: TextEditingController(text: _supplierName),
//                   decoration: const InputDecoration(
//                     hintText: 'جستجو یا وارد کردن نام',
//                     border: InputBorder.none,
//                     hintStyle: TextStyle(
//                       color: Color(0x99994D51),
//                       fontFamily: 'NotoSansArabic',
//                     ),
//                   ),
//                   style: const TextStyle(
//                     fontFamily: 'NotoSansArabic',
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textDirection: TextDirection.rtl,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTypeToggle() {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF0E4E5),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _selectedType = PurchaseType.paperCard;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 10,
//                   horizontal: 16,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _selectedType == PurchaseType.paperCard
//                       ? Colors.white
//                       : Colors.transparent,
//                   borderRadius: BorderRadius.circular(8),
//                   boxShadow: _selectedType == PurchaseType.paperCard
//                       ? [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.05),
//                             blurRadius: 2,
//                             offset: const Offset(0, 1),
//                           ),
//                         ]
//                       : null,
//                 ),
//                 child: Text(
//                   'کارت کاغذی',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: _selectedType == PurchaseType.paperCard
//                         ? const Color(0xFFEA2A33)
//                         : const Color(0xFF994D51),
//                     fontFamily: 'NotoSansArabic',
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _selectedType = PurchaseType.sentCredit;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 10,
//                   horizontal: 16,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _selectedType == PurchaseType.sentCredit
//                       ? Colors.white
//                       : Colors.transparent,
//                   borderRadius: BorderRadius.circular(8),
//                   boxShadow: _selectedType == PurchaseType.sentCredit
//                       ? [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 2,
//                             offset: const Offset(0, 1),
//                           ),
//                         ]
//                       : null,
//                 ),
//                 child: Text(
//                   'کریدیت ارسالی',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: _selectedType == PurchaseType.sentCredit
//                         ? const Color(0xFFEA2A33)
//                         : const Color(0xFF994D51),
//                     fontFamily: 'NotoSansArabic',
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOperatorSelection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'انتخاب شبکه',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: const Color(0xFF1B0E0E),
//             fontFamily: 'NotoSansArabic',
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 100,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: _operators.length,
//             itemBuilder: (context, index) {
//               final operator = _operators[index];
//               return GestureDetector(
//                 onTap: () => _selectOperator(index),
//                 child: Container(
//                   margin: const EdgeInsets.only(left: 16),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 64,
//                         height: 64,
//                         padding: operator['selected']
//                             ? const EdgeInsets.all(4)
//                             : const EdgeInsets.all(2),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white,
//                           border: Border.all(
//                             color: operator['selected']
//                                 ? const Color(0xFFEA2A33)
//                                 : Colors.transparent,
//                             width: operator['selected'] ? 2 : 0,
//                           ),
//                           boxShadow: operator['selected']
//                               ? [
//                                   BoxShadow(
//                                     color: const Color(
//                                       0xFFEA2A33,
//                                     ).withOpacity(0.05),
//                                     blurRadius: 20,
//                                     offset: const Offset(0, -2),
//                                   ),
//                                 ]
//                               : null,
//                         ),
//                         child: ClipOval(
//                           child: Image.network(
//                             operator['image'],
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(
//                                 color: Colors.white,
//                                 child: const Icon(Icons.signal_cellular_alt),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         operator['name'],
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: operator['selected']
//                               ? FontWeight.bold
//                               : FontWeight.w500,
//                           color: operator['selected']
//                               ? const Color(0xFFEA2A33)
//                               : const Color(0xFF994D51),
//                           fontFamily: 'NotoSansArabic',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSentCreditForm() {
//     return Column(
//       children: [
//         // Credit Amount
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'مقدار کریدیت (افغانی)',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF1B0E0E),
//                 fontFamily: 'NotoSansArabic',
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               height: 56,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: const Color(0xFFE7D0D1)),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(left: 16),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFCF8F8),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: const Text(
//                       'AFN',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF994D51),
//                         fontFamily: 'NotoSansArabic',
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: TextField(
//                       controller: _creditAmountController,
//                       keyboardType: TextInputType.number,
//                       textAlign: TextAlign.left,
//                       textDirection: TextDirection.ltr,
//                       decoration: const InputDecoration(
//                         hintText: '0',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                       ),
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'NotoSansArabic',
//                       ),
//                       onChanged: (value) => _calculateTotal(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 20),
//
//         // Unit Price
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'قیمت فی واحد',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF1B0E0E),
//                 fontFamily: 'NotoSansArabic',
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               height: 56,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: const Color(0xFFE7D0D1)),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(left: 16),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFCF8F8),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: const Text(
//                       'AFN',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF994D51),
//                         fontFamily: 'NotoSansArabic',
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: TextField(
//                       controller: _unitPriceController,
//                       keyboardType: const TextInputType.numberWithOptions(
//                         decimal: true,
//                       ),
//                       textAlign: TextAlign.left,
//                       textDirection: TextDirection.ltr,
//                       decoration: const InputDecoration(
//                         hintText: '0.00',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                       ),
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'NotoSansArabic',
//                       ),
//                       onChanged: (value) => _calculateTotal(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'مبلغ پرداختی برای هر یک افغانی کریدیت',
//               style: TextStyle(
//                 fontSize: 10,
//                 color: const Color(0xFF994D51),
//                 fontFamily: 'NotoSansArabic',
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPaperCardForm() {
//     return Column(
//       children: [
//         // Card Denominations
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'مقدار کارت (افغانی)',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF1B0E0E),
//                 fontFamily: 'NotoSansArabic',
//               ),
//             ),
//             const SizedBox(height: 12),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 4,
//                 crossAxisSpacing: 8,
//                 mainAxisSpacing: 8,
//                 childAspectRatio: 1.5,
//               ),
//               itemCount: _cardDenominations.length,
//               itemBuilder: (context, index) {
//                 final value = _cardDenominations[index];
//                 final isSelected = _selectedDenomination == value;
//
//                 return GestureDetector(
//                   onTap: () => _selectDenomination(value),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: isSelected
//                             ? const Color(0xFFEA2A33)
//                             : const Color(0xFFE7D0D1),
//                         width: isSelected ? 2 : 1,
//                       ),
//                       boxShadow: isSelected
//                           ? [
//                               BoxShadow(
//                                 color: const Color(0xFFEA2A33).withOpacity(0.1),
//                                 blurRadius: 4,
//                                 spreadRadius: 1,
//                               ),
//                             ]
//                           : null,
//                     ),
//                     child: Center(
//                       child: Text(
//                         value.toString(),
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isSelected
//                               ? const Color(0xFFEA2A33)
//                               : const Color(0xFF994D51),
//                           fontFamily: 'NotoSansArabic',
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 24),
//
//         // Card Count and Price
//         Row(
//           children: [
//             // Card Count
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'تعداد کارت‌ها',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF1B0E0E),
//                       fontFamily: 'NotoSansArabic',
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     height: 56,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xFFE7D0D1)),
//                     ),
//                     child: TextField(
//                       controller: _cardCountController,
//                       keyboardType: TextInputType.number,
//                       textAlign: TextAlign.left,
//                       textDirection: TextDirection.ltr,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                       ),
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'NotoSansArabic',
//                       ),
//                       onChanged: (value) => _calculateTotal(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 16),
//
//             // Card Price
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'قیمت فی کارت',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF1B0E0E),
//                       fontFamily: 'NotoSansArabic',
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     height: 56,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xFFE7D0D1)),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           margin: const EdgeInsets.only(left: 16),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFFCF8F8),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: const Text(
//                             'AFN',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: Color(0xFF994D51),
//                               fontFamily: 'NotoSansArabic',
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: TextField(
//                             controller: _cardPriceController,
//                             keyboardType: TextInputType.number,
//                             textAlign: TextAlign.left,
//                             textDirection: TextDirection.ltr,
//                             decoration: const InputDecoration(
//                               border: InputBorder.none,
//                               contentPadding: EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                             ),
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               fontFamily: 'NotoSansArabic',
//                             ),
//                             onChanged: (value) => _calculateTotal(),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTotalCard(double totalAmount) {
//     final nominalValue = _selectedType == PurchaseType.sentCredit
//         ? (double.tryParse(_creditAmountController.text) ?? 0)
//         : (_selectedDenomination *
//               (int.tryParse(_cardCountController.text) ?? 0));
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE7D0D1)),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x0A000000),
//             blurRadius: 2,
//             offset: Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Total Credit / Card Count
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 _selectedType == PurchaseType.sentCredit
//                     ? 'کل کریدیت:'
//                     : 'تعداد کل:',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: const Color(0xFF994D51),
//                   fontFamily: 'NotoSansArabic',
//                 ),
//               ),
//               Text(
//                 _selectedType == PurchaseType.sentCredit
//                     ? '${nominalValue.toStringAsFixed(0)} AFN'
//                     : '${int.tryParse(_cardCountController.text) ?? 0} عدد',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF1B0E0E),
//                   fontFamily: 'NotoSansArabic',
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 12),
//
//           // Purchase Rate / Nominal Value
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 _selectedType == PurchaseType.sentCredit
//                     ? 'نرخ خرید:'
//                     : 'ارزش اسمی:',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: const Color(0xFF994D51),
//                   fontFamily: 'NotoSansArabic',
//                 ),
//               ),
//               Text(
//                 _selectedType == PurchaseType.sentCredit
//                     ? '${((double.tryParse(_unitPriceController.text) ?? 0) * 100).toStringAsFixed(0)}% (${_unitPriceController.text})'
//                     : '${nominalValue.toStringAsFixed(0)} افغانی',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: const Color(0xFF1B0E0E),
//                   fontFamily: 'NotoSansArabic',
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 16),
//           const Divider(height: 1, color: Color(0xFFE7D0D1)),
//           const SizedBox(height: 16),
//
//           // Total Amount
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'مجموعه پرداختی',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF1B0E0E),
//                   fontFamily: 'NotoSansArabic',
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     totalAmount.toStringAsFixed(0),
//                     style: const TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.w900,
//                       color: Color(0xFFEA2A33),
//                       fontFamily: 'NotoSansArabic',
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'افغانی',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF994D51),
//                       fontFamily: 'NotoSansArabic',
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _creditAmountController.dispose();
//     _unitPriceController.dispose();
//     _cardAmountController.dispose();
//     _cardCountController.dispose();
//     _cardPriceController.dispose();
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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

  // Data from PurchasePage
  final List<int> _faceValues = [50, 100, 250, 500];
  final List<String> _operatorsList = ['روشن', 'اتصالات', 'ام‌تی‌ان', 'سلام', 'افغان بیسیم'];
  final List<String> _providers = [
    'ستارگان متحد',
    'اکتیو سرویس',
    'افغان پی',
    'شاهی ایزیلود',
  ];

  // Selected values
  String _selectedOperator = 'روشن'; // برای نمایش در UI
  String _selectedOperatorValue = 'awcc'; // برای ذخیره در دیتابیس <- این باید اضافه شود
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
      builder: (context) => AlertDialog(
        title: const Text('تأیید خرید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نوع خرید: ${_selectedType == PurchaseType.paperCard ? 'کارت کاغذی' : 'کریدیت ارسالی'}'),
            const SizedBox(height: 8),
            if (_selectedType == PurchaseType.paperCard) ...[
              Text('اپراتور: $_selectedOperator'),
              Text('مقدار کارت: $_selectedFaceValue AFN'),
              Text('تعداد: ${_quantityController.text} عدد'),
            ] else ...[
              Text('تأمین‌کننده: $_selectedProvider'),
              Text('مقدار کریدیت: ${_totalCreditController.text} AFN'),
            ],
            const SizedBox(height: 8),
            Text('قیمت فی واحد: ${_costPerUnitController.text} AFN'),
            Text('مجموعه پرداختی: ${total.toStringAsFixed(0)} AFN',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Save logic from PurchasePage
              _savePurchase();
            },
            child: const Text('تأیید'),
          ),
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
    String message = '✅ خرید ثبت شد!\n';

    if (data['type'] == 'DIGITAL') {
      message += 'مقدار کریدیت: ${data['total_credit']} AFN\n';
      message += 'مبلغ اسمی: ${data['nominal_price']} AFN\n';
      message += 'مبلغ پرداختی: ${data['actual_paid']} AFN\n';

      if (data['discount_amount'] > 0) {
        message += 'تخفیف: ${data['discount_amount']} AFN';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خرید موفق'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تایید'),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7D0D1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedType == PurchaseType.paperCard ? 'ارزش اسمی:' : 'کل کریدیت:',
                        style: const TextStyle(
                          color: Color(0xFF994D51),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${nominalValue.toStringAsFixed(0)} ${_selectedType == PurchaseType.paperCard ? 'افغانی' : 'AFN'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedType == PurchaseType.paperCard ? 'تعداد کل:' : 'نرخ خرید:',
                        style: const TextStyle(
                          color: Color(0xFF994D51),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _selectedType == PurchaseType.paperCard
                            ? '${_quantityController.text} عدد'
                            : '${((double.tryParse(_costPerUnitController.text) ?? 0) * 100).toStringAsFixed(0)}% (${_costPerUnitController.text})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE7D0D1)),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مجموعه پرداختی',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            totalAmount.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEA2A33),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'افغانی',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF994D51),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // فیلد جدید: مبلغ واقعی پرداختی
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE7D0D1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '💰 اطلاعات پرداخت',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_paymentStatus),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(_paymentStatus),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // مبلغ اسمی (محاسبه شده)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('مبلغ اسمی:', style: TextStyle(color: Colors.grey)),
                            Text(
                              '${_totalPaidController.text} AFN',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        // مبلغ واقعی پرداختی
                        TextField(
                          controller: _actualPaidController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'مبلغ واقعی پرداختی',
                            hintText: 'مبلغی که پرداخت کردید',
                            prefixIcon: Icon(Icons.payments, color: Colors.green),
                            suffixText: 'AFN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (value) {
                            _calculateDiscount();
                          },
                        ),

                        SizedBox(height: 8),

                        // نمایش تخفیف
                        if (_paymentStatus == 'PARTIAL')
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🎉 تخفیف دریافتی:', style: TextStyle(color: Colors.green)),
                                Text(
                                  '${_calculateDiscountAmount()} AFN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
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
            ),
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