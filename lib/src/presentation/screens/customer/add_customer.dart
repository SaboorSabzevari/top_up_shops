import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:top_up_shops/src/presentation/theme/colors.dart';
import '../../../data/local/app_database.dart';
import '../../../domain/entity/customer.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../services/file_helper.dart';
import '../../../utils/debuge.dart';

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

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'شماره تماس الزامی است';
    }

    if (value.length != 10) {
      return 'شماره باید ۱۰ رقم باشد';
    }

    if (!value.startsWith('07')) {
      return 'شماره باید با 07 شروع شود';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'فقط عدد وارد کنید';
    }

    return null;
  }

  String _formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleanPhone.startsWith('+93')) {
      cleanPhone = '0${cleanPhone.substring(3)}';
    } else if (cleanPhone.startsWith('0093')) {
      cleanPhone = '0${cleanPhone.substring(4)}';
    } else if (cleanPhone.startsWith('93') && cleanPhone.length > 10) {
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

    if (widget.customerData == null) {
      _initializeDefaultFields();
    } else {
      _loadExistingCustomerData();
    }
  }

  void _initializeDefaultFields() {
    if (_customerType == CustomerType.normal) {
      normalPhones.add(TextEditingController());
    } else {
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

    DatabaseHelper.instance
        .getCustomerFullDetails(widget.customerData!['id'])
        .then((details) {
          if (mounted) {
            setState(() {
              normalPhones.clear();
              dealers.clear();

              // پارس کردن phones از JSON
              List<dynamic> phonesData = [];
              if (details['phones'] is String) {
                try {
                  phonesData = jsonDecode(details['phones'] as String);
                } catch (e) {
                  phonesData = [];
                }
              } else if (details['phones'] is List) {
                phonesData = details['phones'] as List<dynamic>;
              }

              if (phonesData.isNotEmpty) {
                for (var p in phonesData) {
                  if (p is Map) {
                    normalPhones.add(
                      TextEditingController(
                        text: p['phone_number']?.toString() ?? '',
                      ),
                    );
                  } else if (p is String) {
                    normalPhones.add(TextEditingController(text: p));
                  }
                }
              } else if (_customerType == CustomerType.normal) {
                normalPhones.add(TextEditingController());
              }

              // پارس کردن wholesale_codes از JSON
              List<dynamic> codesData = [];
              if (details['wholesale_codes'] is String) {
                try {
                  codesData = jsonDecode(details['wholesale_codes'] as String);
                } catch (e) {
                  codesData = [];
                }
              } else if (details['wholesale_codes'] is List) {
                codesData = details['wholesale_codes'] as List<dynamic>;
              }

              if (codesData.isNotEmpty) {
                for (var c in codesData) {
                  final item = _DealerItem();
                  if (c is Map) {
                    item.companyType =
                        c['company']?.toString() ??
                        c['company_name']?.toString();
                    item.codeCtrl.text =
                        c['code']?.toString() ??
                        c['company_code']?.toString() ??
                        '';
                  }
                  dealers.add(item);
                }
              } else if (_customerType == CustomerType.shopkeeper) {
                dealers.add(_DealerItem());
              }

              // برای مشتری عمده، اولین شماره را در فیلد اصلی قرار بده
              if (_customerType == CustomerType.shopkeeper &&
                  phonesData.isNotEmpty) {
                if (phonesData[0] is Map) {
                  wholesaleMainPhone.text =
                      phonesData[0]['phone_number']?.toString() ?? '';
                } else if (phonesData[0] is String) {
                  wholesaleMainPhone.text = phonesData[0] as String;
                }
              }
            });
          }
        });
  }

  void _changeCustomerType(CustomerType newType) {
    if (newType == _customerType) return;

    setState(() {
      _customerType = newType;

      if (newType == CustomerType.normal) {
        for (var dealer in dealers) {
          dealer.dispose();
        }
        dealers.clear();

        if (normalPhones.isEmpty) {
          normalPhones.add(TextEditingController());
        }

        wholesaleMainPhone.clear();
      } else {
        for (var phoneCtrl in normalPhones) {
          phoneCtrl.dispose();
        }
        normalPhones.clear();

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
                for (var ctrl in normalPhones) {
                  ctrl.dispose();
                }
                normalPhones.clear();

                for (var phone in fullContact.phones) {
                  String cleanPhone = phone.number.replaceAll(
                    RegExp(r'[^\d+]'),
                    '',
                  );
                  if (cleanPhone.startsWith('+93'))
                    cleanPhone = '0${cleanPhone.substring(3)}';
                  normalPhones.add(TextEditingController(text: cleanPhone));
                }

                if (normalPhones.isEmpty) {
                  normalPhones.add(TextEditingController());
                }
              } else {
                String cleanPhone = fullContact.phones.first.number.replaceAll(
                  RegExp(r'[^\d+]'),
                  '',
                );
                if (cleanPhone.startsWith('+93'))
                  cleanPhone = '0${cleanPhone.substring(3)}';
                wholesaleMainPhone.text = cleanPhone;
              }
            }
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اجازه دسترسی به مخاطبین داده نشد')),
      );
    }
  }

  Future<void> _pickImage(bool isProfile, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      File selectedFile = File(image.path);
      String prefix = isProfile ? 'profile' : 'tazkira';

      String? savedPath = await ImageService.saveAndCompressImage(
        selectedFile,
        prefix,
      );

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, size: 24.w),
              title: Text(
                'گرفتن عکس با دوربین',
                style: TextStyle(fontSize: 16.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProfile, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, size: 24.w),
              title: Text('انتخاب از گالری', style: TextStyle(fontSize: 16.sp)),
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
    if (!_formKey.currentState!.validate()) return;

    // 🔴 دریافت کاربر با روش جدید
    final user = ref.read(currentUserProvider);

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لطفاً دوباره وارد شوید')));
      return;
    }

    final typeStr = _customerType == CustomerType.normal
        ? 'ORDINARY'
        : 'WHOLESALE';

    List<String> validPhones = [];

    if (_customerType == CustomerType.normal) {
      validPhones = normalPhones
          .map((e) => _formatPhoneNumber(e.text))
          .where((phone) => phone.length == 10 && phone.startsWith('07'))
          .toList();
    } else {
      if (wholesaleMainPhone.text.isNotEmpty) {
        String cleanPhone = _formatPhoneNumber(wholesaleMainPhone.text);
        if (cleanPhone.length == 10 && cleanPhone.startsWith('07')) {
          validPhones.add(cleanPhone);
        }
      }
    }

    if (_customerType == CustomerType.shopkeeper) {
      bool hasDealerCode = dealers.any(
        (d) => d.companyType != null && d.codeCtrl.text.isNotEmpty,
      );
      bool hasValidPhone = validPhones.isNotEmpty;

      if (!hasDealerCode && !hasValidPhone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'برای مشتری عمده، درج شماره تماس صحیح یا حداقل یک کد دیلری الزامی است',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    List<Map<String, String>> wholesaleCodes = dealers
        .where(
          (d) =>
              d.companyType != null &&
              d.companyType!.isNotEmpty &&
              d.codeCtrl.text.isNotEmpty,
        )
        .map((e) => {'company': e.companyType!, 'code': e.codeCtrl.text})
        .toList();

    final customer = Customer(
      name: fullNameCtrl.text,
      customerCode:
          widget.customerData?['customer_code'] ??
          'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      type: typeStr,
      shopId: user.shopId, // ✅ اضافه شد
      createdBy: user.uid, // ✅ اضافه شد
      address: addressCtrl.text,
      profileImage: _profilePath,
      tazkiraImage: _tazkiraPath,
      phones: validPhones, // ✅ اضافه شد
      wholesaleCodes: wholesaleCodes, // ✅ اضافه شد
    );
    try {
      // ۱. دریافت اطلاعات کاربر فعلی از Riverpod
      final user = ref.read(currentUserProvider);

      if (user == null) {
        // مدیریت خطا در صورت نبود کاربر
        return;
      }

      if (widget.customerData != null) {
        final id = widget.customerData?['id'];
        if (id == null) return;

        final int customerId = id as int;
        // اگر متد updateCustomer را هم تغییر داده‌اید، کاربر را به آن هم پاس دهید
        await DatabaseHelper.instance.updateCustomer(
          customerId,
          customer,
          validPhones,
          wholesaleCodes,
          user, // اضافه کردن آرگومان کاربر
        );
      } else {
        // ۲. پاس دادن آرگومان چهارم (user) برای رفع خطا
        await DatabaseHelper.instance.addCustomer(
          customer,
          validPhones,
          wholesaleCodes,
          user, // این همان آرگومانی است که جایش خالی بود
        );
      }

      if (mounted) {
        ref.refresh(customerSearchResults);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره‌سازی: $e'),
            backgroundColor: Colors.red,
          ),
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
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customerData == null
              ? 'افزودن مشتری جدید'
              : 'ویرایش اطلاعات مشتری',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: _buildSaveButton(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerTypeSwitch(),
              SizedBox(height: 20.h),
              _buildAvatar(),
              SizedBox(height: 24.h),
              _buildFullName(),
              SizedBox(height: 20.h),
              _customerType == CustomerType.normal
                  ? _buildNormalCustomerSection()
                  : _buildWholesaleSection(),
              SizedBox(height: 24.h),
              _buildNationalIdUpload(),
              SizedBox(height: 24.h),
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
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _typeButton(
            'مشتری عادی',
            _customerType == CustomerType.normal,
            () => _changeCustomerType(CustomerType.normal),
          ),
          _typeButton(
            'عمده',
            _customerType == CustomerType.shopkeeper,
            () => _changeCustomerType(CustomerType.shopkeeper),
            primary: true,
          ),
        ],
      ),
    );
  }

  Widget _typeButton(
    String title,
    bool selected,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42.h,
          decoration: BoxDecoration(
            color: selected
                ? (primary ? const Color(0xffEA2A33) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: selected
                  ? (primary ? Colors.white : Colors.black)
                  : Colors.grey.shade600,
            ),
          ),
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
            radius: 46.r,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _profilePath != null
                ? FileImage(File(_profilePath!))
                : null,
            child: _profilePath == null
                ? Icon(Icons.add_a_photo, size: 32.w, color: kPrimaryColor)
                : null,
          ),
          SizedBox(height: 8.h),
          Text(
            'آواتار (برای آپلود کلیک کنید)',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildFullName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نام کامل',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          cursorColor: kPrimaryColor,
          controller: fullNameCtrl,
          validator: (value) {
            if (value == null || value.isEmpty) return 'نام کامل الزامی است';
            return null;
          },
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person, size: 24.w),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.contact_phone,
                color: const Color(0xffEA2A33),
                size: 24.w,
              ),
              onPressed: _pickContact,
              tooltip: 'انتخاب از مخاطبین گوشی',
            ),
            hintText: 'نام کامل را وارد کنید',
            hintStyle: TextStyle(fontSize: 14.sp),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalCustomerSection() {
    return Column(
      children: [
        _sectionHeader(
          'شماره‌های تماس',
          onAdd: () =>
              setState(() => normalPhones.add(TextEditingController())),
        ),
        ...List.generate(
          normalPhones.length,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Expanded(child: _phoneInput(normalPhones[i])),
                if (normalPhones.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.grey, size: 24.w),
                    onPressed: () => setState(() {
                      normalPhones[i].dispose();
                      normalPhones.removeAt(i);
                    }),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWholesaleSection() {
    return Column(
      children: [
        _input(
          controller: wholesaleMainPhone,
          label: 'شماره تماس اصلی',
          icon: Icons.call,
          isPhone: true,
          hint: '07XXXXXXXX',
        ),
        SizedBox(height: 16.h),
        _sectionHeader(
          'لیست کدهای دیلری',
          onAdd: () => setState(() => dealers.add(_DealerItem())),
        ),
        ...List.generate(
          dealers.length,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Flexible(
                  flex: 3, // 60% فضای ردیف
                  child: dealers[i].buildCompany(ref, () {
                    setState(() {});
                  }),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  flex: 2, // 40% فضای ردیف
                  child: dealers[i].buildCode(),
                ),
                if (dealers.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.grey, size: 24.w),
                    onPressed: () => setState(() {
                      dealers[i].dispose();
                      dealers.removeAt(i);
                    }),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNationalIdUpload() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(false),
      child: _dashedBox(
        icon: Icons.badge,
        title: _tazkiraPath == null
            ? 'برای آپلود تذکره کلیک کنید'
            : 'عکس تذکره بارگذاری شد',
        subtitle: 'JPG, PNG (حداکثر 2MB)',
      ),
    );
  }

  Widget _buildAddress() {
    return _input(
      controller: addressCtrl,
      label: 'آدرس دقیق',
      icon: Icons.location_on,
      hint: 'آدرس محل سکونت یا دکان...',
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffEA2A33),
          minimumSize: Size.fromHeight(54.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        onPressed: _saveData,
        icon: Icon(Icons.save, color: Colors.white, size: 24.w),
        label: Text(
          widget.customerData == null ? 'ذخیره اطلاعات' : 'بروزرسانی تغییرات',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: Icon(Icons.add, color: kPrimaryColor, size: 18.w),
          label: Text(
            'افزودن',
            style: TextStyle(color: kPrimaryColor, fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          cursorColor: kPrimaryColor,
          controller: controller,
          enabled: enabled,
          style: TextStyle(fontSize: 14.sp),
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 24.w),
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14.sp),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
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
      style: TextStyle(fontSize: 14.sp),
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.call, size: 24.w),
        hintText: '07XXXXXXXX',
        hintStyle: TextStyle(fontSize: 14.sp),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dashedBox({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30.w, color: Colors.grey),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(color: kPrimaryColor, fontSize: 14.sp),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ---------- Dealer Item Model ----------
class _DealerItem {
  final TextEditingController codeCtrl = TextEditingController();
  String? companyType;
  int? companyTypeId;

  Widget buildCompany(WidgetRef ref, VoidCallback onUpdate) {
    final providersAsync = ref.watch(providersListProvider);
    return providersAsync.when(
      data: (list) {
        // حذف مقادیر تکراری بر اساس فیلد 'name'
        final uniqueList = <Map<String, dynamic>>[];
        final seenNames = <String>{};

        for (var p in list) {
          final name = p['name'].toString();
          if (!seenNames.contains(name)) {
            seenNames.add(name);
            uniqueList.add(p);
          }
        }

        // اگر مقدار companyType در لیست وجود ندارد، آن را null قرار بده
        final String? currentValue =
            companyType != null && seenNames.contains(companyType)
            ? companyType
            : null;

        return DropdownButtonFormField<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          value: currentValue,
          items: uniqueList
              .map(
                (p) => DropdownMenuItem(
                  value: p['name'].toString(),
                  child: Text(
                    p['name'].toString(),
                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            companyType = v;
            onUpdate();
          },
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'شرکت',
            hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 16.h,
            ),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2.w)),
      error: (_, __) => Text(
        'خطا در بارگذاری',
        style: TextStyle(fontSize: 14.sp, color: Colors.red),
      ),
    );
  }

  Widget buildCode() {
    return TextField(
      keyboardType: TextInputType.number,
      cursorColor: kPrimaryColor,
      controller: codeCtrl,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: 'کد شرکت',
        hintStyle: TextStyle(fontSize: 14.sp),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      ),
    );
  }

  void dispose() => codeCtrl.dispose();
}
