import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:top_up_shops/src/presentation/theme/colors.dart';
import '../../../data/local/app_database.dart';
import '../../../domain/entity/customer.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/customer_provider.dart';
import '../../../services/file_helper.dart';


enum CustomerType { normal, shopkeeper }

class AddCustomerPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? customerData; // برای حالت ویرایش
  const AddCustomerPage({super.key, this.customerData});

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  CustomerType _customerType = CustomerType.shopkeeper;

  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController wholesaleMainPhone = TextEditingController();

  String? _profilePath;
  String? _tazkiraPath;

  final List<TextEditingController> normalPhones = [];
  final List<_DealerItem> dealers = [];

  @override
  @override
  void initState() {
    super.initState();
    if (widget.customerData != null) {
      fullNameCtrl.text = widget.customerData!['name'] ?? '';
      addressCtrl.text = widget.customerData!['address'] ?? '';
      _profilePath = widget.customerData!['profile_image'];
      _tazkiraPath = widget.customerData!['tazkira_image'];
      _customerType = widget.customerData!['type'] == 'ORDINARY'
          ? CustomerType.normal
          : CustomerType.shopkeeper;

      DatabaseHelper.instance.getCustomerFullDetails(widget.customerData!['id']).then((details) {
        if (mounted) {
          setState(() {
            // ۱. حتماً لیست‌ها را ابتدا پاک کنید تا موارد تکراری ایجاد نشود
            normalPhones.clear();
            dealers.clear();

            // ۲. بارگذاری شماره‌های مشتری عادی
            final List phones = details['phones'] ?? [];
            if (phones.isNotEmpty) {
              for (var p in phones) {
                normalPhones.add(TextEditingController(text: p['phone_number'].toString()));
              }
            }

            // ۳. بارگذاری کدهای دیلری مشتری عمده
            final List codes = details['wholesale_codes'] ?? [];
            if (codes.isNotEmpty) {
              for (var c in codes) {
                final item = _DealerItem();
                item.companyType = c['company_name']?.toString();
                item.codeCtrl.text = c['company_code']?.toString() ?? '';
                dealers.add(item);
              }
            }

            // اگر مشتری عمده بود و شماره داشت، شماره اصلی را پر کن
            if (_customerType == CustomerType.shopkeeper && phones.isNotEmpty) {
              wholesaleMainPhone.text = phones[0]['phone_number'].toString();
            }
          });
        }
      });
    }
  }

  void _initEditMode() {
    final data = widget.customerData!;
    fullNameCtrl.text = data['name'] ?? '';
    addressCtrl.text = data['address'] ?? '';
    _customerType = data['type'] == 'ORDINARY' ? CustomerType.normal : CustomerType.shopkeeper;
    _profilePath = data['profile_image'];
    _tazkiraPath = data['tazkira_image'];

    if (_customerType == CustomerType.normal) {
      final List phones = data['phones'] ?? [];
      for (var p in phones) {
        normalPhones.add(TextEditingController(text: p['phone_number'].toString()));
      }
      if (normalPhones.isEmpty) normalPhones.add(TextEditingController());
    } else {
      final List codes = data['wholesale_codes'] ?? [];
      final List phones = data['phones'] ?? [];
      if (phones.isNotEmpty) wholesaleMainPhone.text = phones[0]['phone_number'].toString();

      for (var c in codes) {
        var item = _DealerItem();
        item.companyType = c['company_name'];
        item.codeCtrl.text = c['dealer_code'] ?? '';
        dealers.add(item);
      }
      if (dealers.isEmpty) dealers.add(_DealerItem());
    }
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    addressCtrl.dispose();
    wholesaleMainPhone.dispose();
    for (final c in normalPhones) c.dispose();
    for (final d in dealers) d.dispose();
    super.dispose();
  }
  Future<void> _pickContact() async {
    // درخواست اجازه دسترسی
    if (await Permission.contacts.request().isGranted) {
      // باز کردن لیست مخاطبین برای انتخاب توسط کاربر
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        // دریافت جزئیات کامل مخاطب منتخب
        final fullContact = await FlutterContacts.getContact(contact.id);

        if (fullContact != null) {
          setState(() {
            // ۱. تنظیم نام
            fullNameCtrl.text = fullContact.displayName;

            // ۲. پردازش شماره‌ها
            if (fullContact.phones.isNotEmpty) {
              if (_customerType == CustomerType.normal) {
                // برای مشتری عادی: تمام شماره‌ها را به لیست اضافه کن
                normalPhones.clear();
                for (var phone in fullContact.phones) {
                  // پاکسازی شماره (حذف فاصله‌ها و کاراکترهای اضافی)
                  String cleanPhone = phone.number.replaceAll(RegExp(r'[^\d+]'), '');
                  if (cleanPhone.startsWith('+93')) cleanPhone = cleanPhone.substring(3);

                  normalPhones.add(TextEditingController(text: cleanPhone));
                }
              } else {
                // برای دکان‌دار: فقط اولین شماره را در فیلد اصلی بگذار
                String cleanPhone = fullContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
                if (cleanPhone.startsWith('+93')) cleanPhone = cleanPhone.substring(3);
                wholesaleMainPhone.text = cleanPhone;
              }
            }
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اجازه دسترسی به مخاطبین داده نشد'))
      );
    }
  }
  Future<void> _pickImage(bool isProfile, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source); // گالری یا دوربین

    if (image != null) {
      File selectedFile = File(image.path);
      String prefix = isProfile ? 'profile' : 'tazkira';

      // فشرده‌سازی و ذخیره
      String? savedPath = await ImageService.saveAndCompressImage(selectedFile, prefix);

      if (savedPath != null) {
        setState(() {
          if (isProfile) {
            _profilePath = savedPath;
          } else {
            _tazkiraPath = savedPath;
          }
        });
      }
    }
  }
  void _showImageSourceSheet(bool isProfile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('گرفتن عکس با دوربین'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProfile, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('انتخاب از گالری'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProfile, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // void _saveData() async {
  //   // ۱. بررسی اعتبار نام
  //   if (fullNameCtrl.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام کامل الزامی است')));
  //     return;
  //   }
  //
  //   final typeStr = _customerType == CustomerType.normal ? 'ORDINARY' : 'WHOLESALE';
  //
  //   // ۲. جمع‌آوری شماره‌های تماس (برای عادی لیست و برای دکاندار شماره اصلی)
  //   List<String> phones = _customerType == CustomerType.normal
  //       ? normalPhones.map((e) => e.text).where((t) => t.isNotEmpty).toList()
  //       : (wholesaleMainPhone.text.isNotEmpty ? [wholesaleMainPhone.text] : []);
  //
  //   // ۳. جمع‌آوری کدهای دیلری (بسیار مهم: بررسی کنید آیا companyType مقدار دارد یا خیر)
  //   List<Map<String, String>> wholesaleCodes = dealers
  //       .where((d) => d.companyType != null && d.codeCtrl.text.isNotEmpty)
  //       .map((e) => {
  //     'company': e.companyType!,
  //     'code': e.codeCtrl.text
  //   })
  //       .toList();
  //
  //   // 🔴 بخش دیباگ: نمایش دقیق داده‌ها در کنسول قبل از ذخیره
  //   print('========== DEBUG SAVE DATA ==========');
  //   print('Name: ${fullNameCtrl.text}');
  //   print('Type: $typeStr');
  //   print('Phones Count: ${phones.length}');
  //   print('Phones Data: $phones');
  //   print('Wholesale Codes Count: ${wholesaleCodes.length}');
  //   print('Wholesale Codes Data: $wholesaleCodes');
  //   print('=====================================');
  //
  //   // ساخت آبجکت مشتری
  //   final customer = Customer(
  //     name: fullNameCtrl.text,
  //     customerCode: widget.customerData?['customer_code'] ??
  //         'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
  //     type: typeStr,
  //     address: addressCtrl.text,
  //     profileImage: _profilePath,
  //     tazkiraImage: _tazkiraPath,
  //   );
  //
  //   try {
  //     if (widget.customerData != null) {
  //       print('Status: Updating existing customer...');
  //       await DatabaseHelper.instance.updateCustomer(widget.customerData!['id'], customer, phones, wholesaleCodes);
  //     } else {
  //       print('Status: Adding new customer...');
  //       await DatabaseHelper.instance.addCustomer(customer, phones, wholesaleCodes);
  //     }
  //
  //     print('✅ Success: Data sent to DatabaseHelper');
  //     ref.refresh(customerSearchResults);
  //     Navigator.pop(context);
  //   } catch (e) {
  //     print('❌ ERROR during save: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ذخیره سازی: $e')));
  //   }
  // }
  void _saveData() async {
    if (fullNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام کامل الزامی است')));
      return;
    }

    final typeStr = _customerType == CustomerType.normal ? 'ORDINARY' : 'WHOLESALE';

    // ۱. اصلاح بخش شماره تماس برای مشتری عمده
    List<String> phones = [];
    if (_customerType == CustomerType.normal) {
      phones = normalPhones.map((e) => e.text).where((t) => t.isNotEmpty).toList();
    } else {
      if (wholesaleMainPhone.text.isNotEmpty) {
        phones.add(wholesaleMainPhone.text); // اضافه کردن شماره مشتری عمده
      }
    }

    // ۲. جمع‌آوری کدهای دیلری
    List<Map<String, String>> wholesaleCodes = dealers
        .where((d) => d.companyType != null && d.codeCtrl.text.isNotEmpty)
        .map((e) => {
      'company': e.companyType!,
      'code': e.codeCtrl.text
    })
        .toList();

    final customer = Customer(
      name: fullNameCtrl.text,
      customerCode: widget.customerData?['customer_code'] ??
          'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      type: typeStr,
      address: addressCtrl.text,
      // مقادیر زیر را به درستی پاس دهید تا نال فرستاده نشود
      profileImage: _profilePath,
      tazkiraImage: _tazkiraPath,
    );

    try {
      if (widget.customerData != null) {
        // ⚠️ بسیار مهم: ID را به صورت مستقیم جداگانه بفرستید
        final int customerId = widget.customerData!['id'];
        await DatabaseHelper.instance.updateCustomer(customerId, customer, phones, wholesaleCodes);
      } else {
        await DatabaseHelper.instance.addCustomer(customer, phones, wholesaleCodes);
      }

      ref.refresh(customerSearchResults);
      Navigator.pop(context);
    } catch (e) {
      // اگر اینجا ارور چاپ شد، یعنی دیتابیس اجازه ذخیره نداده است
      print('❌ ERROR IN SAVE: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.customerData == null ? 'افزودن مشتری جدید' : 'ویرایش اطلاعات مشتری',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: _buildSaveButton(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerTypeSwitch(),
              const SizedBox(height: 20),
              _buildAvatar(),
              const SizedBox(height: 24),
              _buildFullName(),
              const SizedBox(height: 20),
              _customerType == CustomerType.normal ? _buildNormalCustomerSection() : _buildWholesaleSection(),
              const SizedBox(height: 24),
              _buildNationalIdUpload(),
              const SizedBox(height: 24),
              _buildAddress(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _buildCustomerTypeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _typeButton('مشتری عادی', _customerType == CustomerType.normal, () => setState(() => _customerType = CustomerType.normal)),
          _typeButton('دکان‌دار', _customerType == CustomerType.shopkeeper, () => setState(() => _customerType = CustomerType.shopkeeper), primary: true),
        ],
      ),
    );
  }

  Widget _typeButton(String title, bool selected, VoidCallback onTap, {bool primary = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: selected ? (primary ? const Color(0xffEA2A33) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? (primary ? Colors.white : Colors.black) : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(true),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _profilePath != null ? FileImage(File(_profilePath!)) : null,
            child: _profilePath == null ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey) : null,
          ),
          const SizedBox(height: 8),
          const Text('آواتار (برای آپلود کلیک کنید)', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFullName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('نام کامل', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: fullNameCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person),
            // اضافه کردن آیکون مخاطبین در سمت چپ فیلد (یا راست در RTL)
            suffixIcon: IconButton(
              icon: const Icon(Icons.contact_phone, color: Color(0xffEA2A33)),
              onPressed: _pickContact,
              tooltip: 'انتخاب از مخاطبین گوشی',
            ),
            hintText: 'نام کامل را وارد کنید',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalCustomerSection() {
    return Column(
      children: [
        _sectionHeader('شماره‌های تماس', onAdd: () => setState(() => normalPhones.add(TextEditingController()))),
        ...List.generate(normalPhones.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: _phoneInput(normalPhones[i])),
              if (normalPhones.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => setState(() => normalPhones.removeAt(i))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildWholesaleSection() {
    return Column(
      children: [
        _input(controller: wholesaleMainPhone, label: 'شماره تماس اصلی', icon: Icons.call, isPhone: true, hint: '7XXXXXXXX'),
        const SizedBox(height: 16),
        _sectionHeader('لیست کدهای دیلری', onAdd: () => setState(() => dealers.add(_DealerItem()))),
        // در لیست کدهای دیلری
        ...List.generate(dealers.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: dealers[i].buildCompany(ref, () {
                  // این بخش باعث می‌شود صفحه اصلی متوجه تغییر در کلاس DealerItem شود
                  setState(() {});
                }),
              ),
              const SizedBox(width: 8),
              Expanded(child: dealers[i].buildCode()),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => setState(() => dealers.removeAt(i))
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildNationalIdUpload() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(false),
      child: _dashedBox(
        icon: Icons.badge,
        title: _tazkiraPath == null ? 'برای آپلود تذکره کلیک کنید' : 'عکس تذکره بارگذاری شد',
        subtitle: 'JPG, PNG (حداکثر 2MB)',
      ),
    );
  }

  Widget _buildAddress() {
    return _input(controller: addressCtrl, label: 'آدرس دقیق', icon: Icons.location_on, hint: 'آدرس محل سکونت یا دکان...', maxLines: 3);
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffEA2A33),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _saveData,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          widget.customerData == null ? 'ذخیره اطلاعات' : 'بروزرسانی تغییرات',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('افزودن')),
      ],
    );
  }

  Widget _input({required TextEditingController controller, required String label, required IconData icon, String? hint, bool enabled = true, bool isPhone = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 6),

        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _phoneInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.call),
        suffixText: '+93',
        hintText: '7XXXXXXXX',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _dashedBox({required IconData icon, required String title, required String subtitle}) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade400)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.grey),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color:kPrimaryColor)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ---------- Dealer Item Model ----------
class _DealerItem {
  final TextEditingController codeCtrl = TextEditingController();
  String? companyType;

  // اضافه کردن پارامتر onChanged به متد
  Widget buildCompany(WidgetRef ref, VoidCallback onUpdate) {
    final providersAsync = ref.watch(providersListProvider);
    return providersAsync.when(
      data: (list) => DropdownButtonFormField<String>(
        value: companyType,
        items: list.map((p) => DropdownMenuItem(
          // مقدار را نام شرکت بگیرید تا با سیستم ارسال کریدیت هماهنگ باشد
            value: p['name'].toString(),
            child: Text(p['name'].toString())
        )).toList(),
        onChanged: (v) {
          companyType = v;
          onUpdate(); // فراخوانی تابع برای آپلود State صفحه اصلی
        },
        decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'شرکت',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('خطا'),
    );
  }

  Widget buildCode() {
    return TextField(
      controller: codeCtrl,
      textAlign: TextAlign.center,
      onChanged: (v) {
        // اختیاری: برای اطمینان از ثبت لحظه‌ای
      },
      decoration: InputDecoration(
          hintText: 'کد دیلری',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)
      ),
    );
  }

  void dispose() => codeCtrl.dispose();
}