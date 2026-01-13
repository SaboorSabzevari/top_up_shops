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
  CustomerType _customerType = CustomerType.normal; // تغییر پیش‌فرض به عادی
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController wholesaleMainPhone = TextEditingController();
  // متد اعتبارسنجی را به این صورت تغییر دهید
  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'شماره تماس الزامی است';
    }

    // اگر کاربر دستی تایپ کرد و +93 زد، اینجا صرفا خطا می‌دهیم
    // (یا می‌توانیم در onSaved اصلاح کنیم، اما خطا دادن برای آگاهی کاربر بهتر است)

    // ۱. بررسی طول شماره (دقیقا ۱۰ رقم)
    if (value.length != 10) {
      return 'شماره باید ۱۰ رقم باشد';
    }

    // ۲. بررسی شروع شدن با 07
    if (!value.startsWith('07')) {
      return 'شماره باید با 07 شروع شود';
    }

    // ۳. بررسی عددی بودن
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'فقط عدد وارد کنید';
    }

    return null;
  } // این متد را به داخل کلاس _AddCustomerPageState اضافه کنید
  String _formatPhoneNumber(String phone) {
    // ۱. حذف تمام فاصله‌ها، پرانتزها و خط تیره‌ها
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // ۲. تبدیل +93 یا 0093 به 0
    if (cleanPhone.startsWith('+93')) {
      cleanPhone = '0${cleanPhone.substring(3)}';
    } else if (cleanPhone.startsWith('0093')) {
      cleanPhone = '0${cleanPhone.substring(4)}';
    } else if (cleanPhone.startsWith('93') && cleanPhone.length > 10) {
      // اگر کاربر اشتباها 93 زد ولی + نذاشت
      cleanPhone = '0${cleanPhone.substring(2)}';
    }

    return cleanPhone;
  }
  String? _profilePath;
  String? _tazkiraPath;

  final List<TextEditingController> normalPhones = [];
  final List<_DealerItem> dealers = [];

  @override
  void initState() {
    super.initState();

    // اضافه کردن فیلدهای پیش‌فرض برای حالت جدید
    if (widget.customerData == null) {
      // برای مشتری جدید: اضافه کردن فیلدهای پیش‌فرض
      _initializeDefaultFields();
    } else {
      // برای حالت ویرایش: بارگذاری داده‌های موجود
      _loadExistingCustomerData();
    }
  }

  void _initializeDefaultFields() {
    // برای مشتری عادی: یک فیلد شماره تماس پیش‌فرض
    if (_customerType == CustomerType.normal) {
      normalPhones.add(TextEditingController());
    }
    // برای مشتری عمده: یک شرکت دیلری پیش‌فرض
    else {
      dealers.add(_DealerItem());
    }
  }

  void _loadExistingCustomerData() {
    final data = widget.customerData!;
    fullNameCtrl.text = data['name'] ?? '';
    addressCtrl.text = data['address'] ?? '';
    _profilePath = data['profile_image'];
    _tazkiraPath = data['tazkira_image'];
    _customerType = data['type'] == 'ORDINARY'
        ? CustomerType.normal
        : CustomerType.shopkeeper;

    // بارگذاری داده‌های کامل از دیتابیس
    DatabaseHelper.instance.getCustomerFullDetails(widget.customerData!['id']).then((details) {
      if (mounted) {
        setState(() {
          // پاک کردن لیست‌ها
          normalPhones.clear();
          dealers.clear();

          // بارگذاری شماره‌های مشتری عادی
          final List phones = details['phones'] ?? [];
          if (phones.isNotEmpty) {
            for (var p in phones) {
              normalPhones.add(TextEditingController(text: p['phone_number'].toString()));
            }
          } else if (_customerType == CustomerType.normal) {
            // اگر مشتری عادی است و شماره‌ای ندارد، یک فیلد پیش‌فرض اضافه کن
            normalPhones.add(TextEditingController());
          }

          // بارگذاری کدهای دیلری مشتری عمده
          final List codes = details['wholesale_codes'] ?? [];
          if (codes.isNotEmpty) {
            for (var c in codes) {
              final item = _DealerItem();
              item.companyType = c['company_name']?.toString();
              item.codeCtrl.text = c['company_code']?.toString() ?? '';
              dealers.add(item);
            }
          } else if (_customerType == CustomerType.shopkeeper) {
            // اگر مشتری عمده است و کد دیلری ندارد، یک فیلد پیش‌فرض اضافه کن
            dealers.add(_DealerItem());
          }

          // اگر مشتری عمده بود و شماره داشت، شماره اصلی را پر کن
          if (_customerType == CustomerType.shopkeeper && phones.isNotEmpty) {
            wholesaleMainPhone.text = phones[0]['phone_number'].toString();
          }
        });
      }
    });
  }

  // تابع تغییر نوع مشتری
  void _changeCustomerType(CustomerType newType) {
    if (newType == _customerType) return;

    setState(() {
      _customerType = newType;

      // پاک کردن فیلدهای نوع قبلی و اضافه کردن فیلد پیش‌فرض برای نوع جدید
      if (newType == CustomerType.normal) {
        // حذف همه شرکت‌های دیلری
        for (var dealer in dealers) {
          dealer.dispose();
        }
        dealers.clear();

        // اضافه کردن یک فیلد شماره تماس پیش‌فرض
        if (normalPhones.isEmpty) {
          normalPhones.add(TextEditingController());
        }

        // پاک کردن شماره تماس اصلی (مخصوص عمده)
        wholesaleMainPhone.clear();
      } else {
        // حذف همه شماره‌های عادی
        for (var phoneCtrl in normalPhones) {
          phoneCtrl.dispose();
        }
        normalPhones.clear();

        // اضافه کردن یک شرکت دیلری پیش‌فرض
        if (dealers.isEmpty) {
          dealers.add(_DealerItem());
        }
      }
    });
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

  // متد _pickContact موجود را با این نسخه جایگزین کنید
  Future<void> _pickContact() async {
    if (await Permission.contacts.request().isGranted) {
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id);

        if (fullContact != null) {
          setState(() {
            fullNameCtrl.text = fullContact.displayName;

            if (fullContact.phones.isNotEmpty) {
              if (_customerType == CustomerType.normal) {
                // برای مشتری عادی: پاک کردن فیلدهای قبلی و اضافه کردن شماره‌های جدید
                for (var ctrl in normalPhones) {
                  ctrl.dispose();
                }
                normalPhones.clear();

                for (var phone in fullContact.phones) {
                  String cleanPhone = phone.number.replaceAll(RegExp(r'[^\d+]'), '');
                  if (cleanPhone.startsWith('+93')) cleanPhone = '0${cleanPhone.substring(3)}';
                  normalPhones.add(TextEditingController(text: cleanPhone));
                }

                // اگر هیچ شماره‌ای اضافه نشد، یک فیلد خالی اضافه کن
                if (normalPhones.isEmpty) {
                  normalPhones.add(TextEditingController());
                }
              } else {
                // برای دکان‌دار: فقط اولین شماره را در فیلد اصلی بگذار
                String cleanPhone = fullContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
                if (cleanPhone.startsWith('+93')) cleanPhone = '0${cleanPhone.substring(3)}';
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
    final image = await picker.pickImage(source: source);

    if (image != null) {
      File selectedFile = File(image.path);
      String prefix = isProfile ? 'profile' : 'tazkira';

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

  void _saveData() async {
    // ۱. اعتبارسنجی فرم (ظاهری)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ۲. تعیین نوع مشتری برای دیتابیس
    final typeStr = _customerType == CustomerType.normal ? 'ORDINARY' : 'WHOLESALE';

    // ۳. جمع‌آوری و استانداردسازی شماره تماس‌ها
    List<String> validPhones = [];

    if (_customerType == CustomerType.normal) {
      // برای مشتری عادی: تمام فیلدها را چک و فرمت می‌کنیم
      validPhones = normalPhones
          .map((e) => _formatPhoneNumber(e.text)) // حذف +93 و فاصله‌ها
          .where((phone) => phone.length == 10 && phone.startsWith('07')) // فیلتر کردن شماره‌های معتبر
          .toList();
    } else {
      // برای مغازه‌دار: تک شماره را چک می‌کنیم
      if (wholesaleMainPhone.text.isNotEmpty) {
        String cleanPhone = _formatPhoneNumber(wholesaleMainPhone.text);
        if (cleanPhone.length == 10 && cleanPhone.startsWith('07')) {
          validPhones.add(cleanPhone);
        }
      }
    }

    // ۴. بررسی الزامات خاص مغازه‌دار (کد دیلری یا شماره تماس)
    if (_customerType == CustomerType.shopkeeper) {
      // بررسی اینکه آیا حداقل یک کد دیلری وارد شده است؟
      bool hasDealerCode = dealers.any((d) => d.companyType != null && d.codeCtrl.text.isNotEmpty);
      // بررسی اینکه آیا لیست شماره‌های معتبر پر است؟
      bool hasValidPhone = validPhones.isNotEmpty;

      if (!hasDealerCode && !hasValidPhone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برای مشتری عمده، درج شماره تماس صحیح یا حداقل یک کد دیلری الزامی است'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // ۵. جمع‌آوری کدهای دیلری (بدون تغییر)
    List<Map<String, String>> wholesaleCodes = dealers
        .where((d) => d.companyType != null && d.codeCtrl.text.isNotEmpty)
        .map((e) => {
      'company': e.companyType!,
      'code': e.codeCtrl.text
    })
        .toList();

    // ۶. ساخت آبجکت مشتری
    final customer = Customer(
      name: fullNameCtrl.text,
      customerCode: widget.customerData?['customer_code'] ??
          'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      type: typeStr,
      address: addressCtrl.text,
      profileImage: _profilePath,
      tazkiraImage: _tazkiraPath,
    );

    // ۷. ذخیره در دیتابیس
    try {
      if (widget.customerData != null) {
        // حالت ویرایش
        final int customerId = widget.customerData!['id'];
        await DatabaseHelper.instance.updateCustomer(customerId, customer, validPhones, wholesaleCodes);
      } else {
        // حالت افزودن جدید
        await DatabaseHelper.instance.addCustomer(customer, validPhones, wholesaleCodes);
      }

      // بروزرسانی لیست مشتریان در صفحه قبل
      if (mounted) {
        // اگر از Riverpod استفاده می‌کنید invalidate بهتر از refresh است
        // ref.invalidate(customerSearchResultsProvider);
        // یا همان کد خودتان:
        ref.refresh(customerSearchResults);

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره‌سازی: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customerData == null ? 'افزودن مشتری جدید' : 'ویرایش اطلاعات مشتری',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: _buildSaveButton(),
      body: Form(
          key: _formKey,
        child: SingleChildScrollView(
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
          _typeButton('مشتری عادی', _customerType == CustomerType.normal,
                  () => _changeCustomerType(CustomerType.normal)),
          _typeButton('عمده', _customerType == CustomerType.shopkeeper,
                  () => _changeCustomerType(CustomerType.shopkeeper), primary: true),
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
            child: _profilePath == null ? const Icon(Icons.add_a_photo, size: 32, color: kPrimaryColor,) : null,
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
        TextFormField(cursorColor: kPrimaryColor,
          controller: fullNameCtrl,
    validator: (value) {
    if (value == null || value.isEmpty) return 'نام کامل الزامی است';
    return null;
    },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person),
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
              // فقط اگر بیش از یک فیلد وجود دارد، دکمه حذف نمایش داده شود
              if (normalPhones.length > 1) IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => setState(() {
                    normalPhones[i].dispose();
                    normalPhones.removeAt(i);
                  })
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildWholesaleSection() {
    return Column(
      children: [
        _input(controller: wholesaleMainPhone, label: 'شماره تماس اصلی', icon: Icons.call, isPhone: true, hint: '07XXXXXXXX'),
        const SizedBox(height: 16),
        _sectionHeader('لیست کدهای دیلری', onAdd: () => setState(() => dealers.add(_DealerItem()))),
        ...List.generate(dealers.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: dealers[i].buildCompany(ref, () {
                  setState(() {});
                }),
              ),
              const SizedBox(width: 8),
              Expanded(child: dealers[i].buildCode()),
              // فقط اگر بیش از یک شرکت وجود دارد، دکمه حذف نمایش داده شود
              if (dealers.length > 1) IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => setState(() {
                    dealers[i].dispose();
                    dealers.removeAt(i);
                  })
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
        TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, color: kPrimaryColor, size: 18), label: const Text('افزودن',style: TextStyle(
          color: kPrimaryColor
        ),)),
      ],
    );
  }

  Widget _input({required TextEditingController controller, required String label, required IconData icon, String? hint, bool enabled = true, bool isPhone = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 6),

        TextFormField(cursorColor: kPrimaryColor,
          controller: controller,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!value.startsWith('07')) return 'شروع با 07';
              if (value.length != 10) return '10 رقم باشد';
            }
            return null;
          },
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
    return TextFormField(
      validator: _phoneValidator,
      cursorColor: kPrimaryColor,
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.call),
        hintText: '07XXXXXXXX',
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

  Widget buildCompany(WidgetRef ref, VoidCallback onUpdate) {
    final providersAsync = ref.watch(providersListProvider);
    return providersAsync.when(
      data: (list) => DropdownButtonFormField<String>(dropdownColor: Colors.white,

        value: companyType,
        items: list.map((p) => DropdownMenuItem(
            value: p['name'].toString(),
            child: Text(p['name'].toString())
        )).toList(),
        onChanged: (v) {
          companyType = v;
          onUpdate();
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
      keyboardType: TextInputType.phone,
      cursorColor: kPrimaryColor,
      controller: codeCtrl,

      decoration: InputDecoration(
          hintText: 'کد شرکت',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)
      ),
    );
  }

  void dispose() => codeCtrl.dispose();
}
