import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/session_provider.dart';
import '../../../data/local/app_database.dart';

class AddStaffPage extends ConsumerStatefulWidget {
  const AddStaffPage({super.key});

  @override
  ConsumerState<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends ConsumerState<AddStaffPage> {
  Future<void> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String ownerShopId, // آیدی دکان مدیر فعلی
  }) async {
    // ۱. ایجاد اپلیکیشن موقت برای ثبت‌نام (تا مدیر لاگ‌اوت نشود)
    FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp', options: Firebase.app().options);

    try {
      // ۲. ثبت‌نام در Firebase Auth
      UserCredential res = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      String staffUid = res.user!.uid;

      // ۳. ذخیره در Firestore (بسیار مهم برای ورود از راه دور)
      await FirebaseFirestore.instance.collection('users').doc(staffUid).set({
        'uid': staffUid,
        'name': name,
        'email': email,
        'role': 'STAFF',
        'shopId': ownerShopId, // اتصال کارمند به دکان مدیر
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ۴. ذخیره در دیتابیس محلی (اختیاری - برای گزارشات آفلاین مدیر)
      await DatabaseHelper.instance.insertStaff(staffUid, name, email, ownerShopId);

    } finally {
      await tempApp.delete();
    }
  }

  Future<UserCredential?> registerStaffInFirebase(String email, String password) async {
    // ایجاد یک اپلیکیشن موقت برای ثبت نام کارمند بدون لاگ‌اوت شدن مدیر
    FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp', options: Firebase.app().options);

    UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
        .createUserWithEmailAndPassword(email: email, password: password);

    // پاک کردن اپلیکیشن موقت بعد از اتمام کار
    await tempApp.delete();

    return userCredential;
  }

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleCreateStaff() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("اطلاعات را به درستی وارد کنید (رمز حداقل ۶ کاراکتر)")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);

      // ۱. ثبت در فایربیس
      final userCred = await registerStaffInFirebase(_emailCtrl.text.trim(), _passwordCtrl.text);

      if (userCred != null) {
        // ۲. ذخیره در دیتابیس محلی با shop_id مدیر فعلی
        await DatabaseHelper.instance.insertStaff(
          userCred.user!.uid,
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          currentUser!.shopId,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("کارمند با موفقیت ساخته شد")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطا: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f6f6),
      appBar: AppBar(
        title: const Text("افزودن کارمند جدید", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true, backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputCard(),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _handleCreateStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA2A33),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("ثبت و ایجاد حساب کارمند", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          _buildTextField(_nameCtrl, "نام و نام خانوادگی", Icons.person_outline),
          const SizedBox(height: 15),
          _buildTextField(_emailCtrl, "ایمیل (نام کاربری برای ورود)", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 15),
          _buildTextField(_passwordCtrl, "رمز عبور", Icons.lock_outline, isPassword: true),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFEA2A33)),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}