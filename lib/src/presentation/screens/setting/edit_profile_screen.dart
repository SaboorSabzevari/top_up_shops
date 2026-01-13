import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// اگر فایل theme/colors.dart را دارید از آن ایمپورت کنید، در غیر این صورت:
const Color kPrimaryColor = Color(0xFFEA2A33);
const Color kBackgroundColor = Color(0xFFF8F6F6);
const Color kSurfaceColor = Colors.white;

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  String? _profileImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // --- بارگذاری اطلاعات از SharedPreferences ---
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeNameCtrl.text = prefs.getString('store_name') ?? '';
      _phoneCtrl.text = prefs.getString('store_phone') ?? '';
      _addressCtrl.text = prefs.getString('store_address') ?? '';
      _profileImagePath = prefs.getString('store_image_path');
      _isLoading = false;
    });
  }

  // --- ذخیره اطلاعات در SharedPreferences ---
  Future<void> _saveProfileData() async {
    if (_storeNameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام فروشگاه و شماره تماس الزامی است'), backgroundColor: Colors.orange),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_name', _storeNameCtrl.text);
    await prefs.setString('store_phone', _phoneCtrl.text);
    await prefs.setString('store_address', _addressCtrl.text);

    if (_profileImagePath != null) {
      await prefs.setString('store_image_path', _profileImagePath!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تغییرات با موفقیت ذخیره شد'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  // --- منطق انتخاب عکس (مشابه add_customer.dart) ---
  Future<void> _pickImage(ImageSource source) async {
    // درخواست دسترسی (مشابه آنچه در add_customer.dart استفاده شده است)
    // نکته: برای اندروید 13+ ممکن است نیاز به permission های متفاوتی باشد
    if (source == ImageSource.camera) {
      var status = await Permission.camera.request();
      if(status.isDenied) return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
              title: const Text('گرفتن عکس با دوربین'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimaryColor),
              title: const Text('انتخاب از گالری'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تشخیص تم تیره/روشن (مشابه analyze_screen.dart)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF211111) : kBackgroundColor,
      // هدر چسبان مشابه HTML
      appBar: AppBar(
        backgroundColor: (isDark ? const Color(0xFF211111) : kBackgroundColor).withOpacity(0.95),
        elevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 28, color: isDark ? Colors.white : Colors.black87),
              Text(
                "بازگشت",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87
                ),
              ),
            ],
          ),
        ),
        title: Text(
          "ویرایش پروفایل",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              children: [
                // --- Profile Image Section ---
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF2F2222) : Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: _profileImagePath != null
                                  ? DecorationImage(
                                image: FileImage(File(_profileImagePath!)),
                                fit: BoxFit.cover,
                              )
                                  : null,
                              color: Colors.grey[200],
                            ),
                            child: _profileImagePath == null
                                ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _showImageSourceSheet,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimaryColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "تغییر عکس فروشگاه",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- Form Section ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2F2222) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: "نام فروشگاه",
                        controller: _storeNameCtrl,
                        icon: Icons.storefront,
                        hint: "نام فروشگاه خود را وارد کنید",
                        isRequired: true,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        label: "شماره تماس",
                        controller: _phoneCtrl,
                        icon: Icons.call,
                        hint: "۰۷XXXXXXXX",
                        isRequired: true,
                        isPhone: true,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        label: "آدرس فروشگاه",
                        controller: _addressCtrl,
                        icon: Icons.location_on,
                        hint: "آدرس دقیق فروشگاه را بنویسید",
                        isMultiLine: true,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Bottom Save Button ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF211111) : kBackgroundColor).withOpacity(0.9),
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)),
              ),
              child: ElevatedButton(
                onPressed: _saveProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: kPrimaryColor.withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "ذخیره تغییرات",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ویجت سازنده فیلدهای ورودی (Custom Input Field) ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isRequired = false,
    bool isPhone = false,
    bool isMultiLine = false,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            if (isRequired)
              const Text(" *", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isPhone ? TextInputType.phone : (isMultiLine ? TextInputType.multiline : TextInputType.text),
            maxLines: isMultiLine ? 3 : 1,
            textDirection: isPhone ? TextDirection.ltr : TextDirection.rtl,
            textAlign: isPhone ? TextAlign.right : TextAlign.start,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontSize: 13,
              ),
              prefixIcon: isPhone ? null : Icon(icon, color: Colors.grey[400], size: 20),
              // آیکون برای شماره تماس باید سمت راست (suffix) باشد چون جهت متن LTR است
              suffixIcon: isPhone ? Icon(icon, color: Colors.grey[400], size: 20) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}