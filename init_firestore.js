//////const admin = require("firebase-admin");
//////
//////const serviceAccount = require("./serviceAccountKey.json");
//////
//////
//////admin.initializeApp({
//////  credential: admin.credential.cert(serviceAccount),
//////});
//////
//////const db = admin.firestore();
//////const auth = admin.auth();
//////
//////async function seedFirestore() {
//////  /* =========================
//////     1. CREATE USERS (AUTH)
//////     ========================= */
//////  const owner = await auth.createUser({
//////    email: "ewq@shop.com",
//////    password: "1234567890",
//////    displayName: "احasمد",
//////  });
//////
//////  const staff = await auth.createUser({
//////    email: "qwe@shop.com",
//////    password: "0987654321",
//////    displayName: "علdjfdfی",
//////  });
//////
//////  /* =========================
//////     2. CREATE SHOP
//////     ========================= */
//////  const shopRef = await db.collection("shops").add({
//////    info: {
//////      name: "فروشگاه ستارگان",
//////      owner_uid: owner.uid,
//////      max_employees: 3,
//////      created_at: admin.firestore.FieldValue.serverTimestamp(),
//////    },
//////  });
//////
//////  const shopId = shopRef.id;
//////  console.log("Shop created:", shopId);
//////
//////  /* =========================
//////     3. USERS SUBCOLLECTION
//////     ========================= */
//////  await shopRef.collection("users").doc(owner.uid).set({
//////    uid: owner.uid,
//////    name: "احمد",
//////    email: owner.email,
//////    role: "OWNER",
//////    active: true,
//////  });
//////
//////  await shopRef.collection("users").doc(staff.uid).set({
//////    uid: staff.uid,
//////    name: "علی",
//////    email: staff.email,
//////    role: "STAFF",
//////    active: true,
//////  });
//////
//////  /* =========================
//////     4. CUSTOMER
//////     ========================= */
//////  const customerRef = await shopRef.collection("customers").add({
//////    name: "مشتری تست",
//////    customer_code: "C-001",
//////    type: "REGISTERED",
//////    shop_id: shopId,
//////    created_by: staff.uid,
//////    created_at: admin.firestore.FieldValue.serverTimestamp(),
//////  });
//////
//////  /* =========================
//////     5. PROVIDERS
//////     ========================= */
//////  const providerRef = await shopRef.collection("providers").add({
//////    name: "ستارگان متحد",
//////    type: "AWCC",
//////    ordinary_code: "543*2",
//////    wholesale_code: "543*6",
//////    shop_id: shopId,
//////  });
//////
//////  /* =========================
//////     6. PROVIDER BALANCE
//////     ========================= */
//////  await shopRef.collection("provider_balances").add({
//////    provider_name: "ستارگان متحد",
//////    current_balance: 10000,
//////    shop_id: shopId,
//////    updated_at: admin.firestore.FieldValue.serverTimestamp(),
//////  });
//////
//////  /* =========================
//////     7. UNIT
//////     ========================= */
//////  await shopRef.collection("units").add({
//////    name: "واحد اصلی",
//////    buy_price: 0.95,
//////    sell_price: 0.96,
//////    shop_id: shopId,
//////  });
//////
//////  /* =========================
//////     8. PAPER STOCK
//////     ========================= */
//////  await shopRef.collection("paper_stock").add({
//////    operator: "AWCC",
//////    face_value: 50,
//////    quantity: 100,
//////    shop_id: shopId,
//////  });
//////
//////  /* =========================
//////     9. PURCHASE
//////     ========================= */
//////  await shopRef.collection("purchases").add({
//////    type: "WHOLESALE",
//////    provider_name: "ستارگان متحد",
//////    quantity: 100,
//////    total_credit: 5000,
//////    actual_paid: 4800,
//////    created_by: owner.uid,
//////    shop_id: shopId,
//////    created_at: admin.firestore.FieldValue.serverTimestamp(),
//////  });
//////
//////  /* =========================
//////     10. TRANSACTION
//////     ========================= */
//////  await shopRef.collection("transactions").add({
//////    customer_id: customerRef.id,
//////    customer_name: "مشتری تست",
//////    customer_type: "REGISTERED",
//////    transaction_type: "DIGITAL",
//////    operator_name: "AWCC",
//////    phone_number: "0700000000",
//////    sent_amount: 50,
//////    quantity: 1,
//////    total_price: 50,
//////    paid_amount: 50,
//////    remaining_amount: 0,
//////    profit: 5,
//////    created_by: staff.uid,
//////    created_role: "STAFF",
//////    shop_id: shopId,
//////    created_at: admin.firestore.FieldValue.serverTimestamp(),
//////  });
//////
//////  console.log("✅ Firestore FULL seed completed");
//////}
//////
//////seedFirestore()
//////  .then(() => process.exit())
//////  .catch(err => {
//////    console.error(err);
//////    process.exit(1);
//////  });
////// seed-firestore-fixed.js
////const admin = require("firebase-admin");
////const serviceAccount = require("./serviceAccountKey.json");
////
////admin.initializeApp({
////  credential: admin.credential.cert(serviceAccount),
////});
////
////const db = admin.firestore();
////const auth = admin.auth();
////
////async function seedFirestore() {
////  /* =========================
////     1. CREATE USERS (AUTH) - با ایمیل ewq@shop.com
////  ========================= */
////  const owner = await auth.createUser({
////    email: "ewqrtyu@shop.com", // ← ایمیل لاگین شما
////    password: "12345678",
////    displayName: "احمد",
////  });
////  console.log("✅ کاربر Auth ایجاد شد:");
////  console.log("  UID:", owner.uid);
////  console.log("  Email:", owner.email);
////
////  /* =========================
////     2. CREATE SHOP
////  ========================= */
////  const shopRef = await db.collection("shops").add({
////    info: {
////      name: "فروشگاه تست",
////      owner_uid: owner.uid,
////      max_employees: 5,
////      created_at: admin.firestore.FieldValue.serverTimestamp(),
////    },
////  });
////
////  const shopId = shopRef.id;
////  console.log("✅ Shop created:", shopId);
////
////  /* =========================
////     3. CREATE USER IN ROOT USERS COLLECTION (CRITICAL!)
////  ========================= */
////  await db.collection("users").doc(owner.uid).set({
////    uid: owner.uid,
////    email: owner.email,
////    role: "OWNER", // یا "STAFF" برای کارمند
////    shopId: shopId,
////    name: "احمد",
////    active: true,
////    createdAt: admin.firestore.FieldValue.serverTimestamp(),
////  });
////
////  console.log("✅ کاربر در Firestore ذخیره شد");
////
////  /* =========================
////     4. CREATE SHOP SUBCOLLECTIONS (اختیاری)
////  ========================= */
////  await shopRef.collection("users").doc(owner.uid).set({
////    uid: owner.uid,
////    name: "احمد",
////    email: owner.email,
////    role: "OWNER",
////    active: true,
////  });
////
////  /* =========================
////     5. CREATE SAMPLE DATA
////  ========================= */
////  // مشتری
////  await shopRef.collection("customers").add({
////    name: "مشتری تست",
////    customer_code: "C-001",
////    type: "REGISTERED",
////    shop_id: shopId,
////    created_by: owner.uid,
////    created_at: admin.firestore.FieldValue.serverTimestamp(),
////  });
////
////  // واحد
////  await shopRef.collection("units").add({
////    name: "واحد اصلی",
////    buy_price: 0.95,
////    sell_price: 0.96,
////    shop_id: shopId,
////  });
////
////  console.log("✅ داده‌های تست ایجاد شدند");
////  console.log("\n📋 اطلاعات ورود:");
////  console.log("ایمیل: ewqrtyu@shop.com");
////  console.log("رمز: 12345678");
////  console.log("Shop ID:", shopId);
////  console.log("User UID:", owner.uid);
////}
////
////seedFirestore()
////  .then(() => {
////    console.log("\n✅ تمام عملیات با موفقیت انجام شد");
////    process.exit(0);
////  })
////  .catch(err => {
////    console.error("❌ خطا:", err);
////    process.exit(1);
////  });
//const admin = require("firebase-admin");
//const serviceAccount = require("./serviceAccountKey.json");
//
//// راه اندازی اولیه
//admin.initializeApp({
//  credential: admin.credential.cert(serviceAccount),
//});
//
//const db = admin.firestore();
//const auth = admin.auth();
//
//// تنظیمات کاربری که می‌خواهید بسازید
//const USER_EMAIL = "admin@shop.com"; // ایمیل برای لاگین
//const USER_PASS = "12345678";        // رمز عبور
//
//async function seedFirestore() {
//  console.log("🚀 شروع عملیات Seed دیتابیس...");
//
//  /* =========================
//     1. ایجاد کاربر (Authentication)
//     ========================= */
//  let owner;
//  try {
//    // تلاش برای ساخت کاربر جدید
//    owner = await auth.createUser({
//      email: USER_EMAIL,
//      password: USER_PASS,
//      displayName: "مدیر فروشگاه",
//    });
//    console.log("✅ کاربر Auth ساخته شد:", owner.uid);
//  } catch (error) {
//    if (error.code === 'auth/email-already-exists') {
//      // اگر کاربر وجود داشت، اطلاعاتش را بگیر
//      owner = await auth.getUserByEmail(USER_EMAIL);
//      console.log("ℹ️ کاربر از قبل وجود داشت:", owner.uid);
//    } else {
//      throw error;
//    }
//  }
//
//  /* =========================
//     2. ایجاد فروشگاه (SHOP)
//     ========================= */
//  // ایجاد داکیومنت فروشگاه در کالکشن shops
//  const shopRef = await db.collection("shops").add({
//    info: {
//      name: "فروشگاه مرکزی",
//      owner_uid: owner.uid,
//      created_at: admin.firestore.FieldValue.serverTimestamp(),
//      subscription_status: "active"
//    },
//  });
//  const shopId = shopRef.id;
//  console.log("✅ فروشگاه ایجاد شد. Shop ID:", shopId);
//
//  /* =========================
//     3. جدول USERS (سطح روت و داخل شاپ)
//     ========================= */
//  // طبق کد شما، یک جدول users داریم. در فایربیس هم در روت و هم در شاپ ذخیره می‌کنیم
// const userData = {
//     uid: owner.uid,
//     name: "مدیر فروشگاه",
//     email: USER_EMAIL,
//     role: "OWNER",
//     shop_id: shopId, // برای هماهنگی با SQLite و Sync
//     shopId: shopId,  // برای هماهنگی با منطق لاگین فلاتر شما
//     active: true
//   };
//
//  // ذخیره در روت (برای لاگین)
//  await db.collection("users").doc(owner.uid).set(userData);
//
//  // ذخیره در زیرمجموعه فروشگاه (برای مدیریت داخلی)
//  await shopRef.collection("users").doc(owner.uid).set(userData);
//  console.log("✅ اطلاعات کاربر در دیتابیس ذخیره شد.");
//
//  /* =========================
//     4. جدول CUSTOMERS (مشتریان)
//     ========================= */
//  const customerRef = await shopRef.collection("customers").add({
//    // فیلدها دقیقاً مطابق جدول customers در app_database.dart
//    name: "مشتری نمونه",
//    customer_code: "C-1001",
//    type: "REGISTERED",
//    shop_id: shopId,
//    created_by: owner.uid,
//    address: "کابل، بازار اصلی",
//    profile_image: "",
//    tazkira_image: "",
//    // فیلد کمکی برای Sync (کد جدید شما این را فیلتر می‌کند پس مشکلی نیست)
//    created_at: admin.firestore.FieldValue.serverTimestamp(),
//  });
//  console.log("✅ مشتری اضافه شد.");
//
//  /* =========================
//     5. جدول CUSTOMER_PHONES (تلفن مشتریان)
//     ========================= */
//  // این جدول در کد قبلی نبود، اضافه شد
//  await shopRef.collection("customer_phones").add({
//    customer_id: customerRef.id, // ارجاع به ID مشتری در فایربیس
//    phone_number: "0799999999",
//    // نکته: در SQLite شما customer_id از نوع Integer است.
//    // در فرآیند Sync باید منطقی برای تبدیل ID استرینگ فایربیس به Integer داشته باشید
//    // یا اینکه در جدول‌های محلی remote_id ذخیره کنید.
//  });
//  console.log("✅ شماره تماس مشتری اضافه شد.");
//
//  /* =========================
//     6. جدول UNITS (واحدها)
//     ========================= */
//  await shopRef.collection("units").add({
//    name: "افغانی",
//    buy_price: 1.0,
//    sell_price: 1.0,
//    shop_id: shopId,
//  });
//  console.log("✅ واحد پول اضافه شد.");
//
//  /* =========================
//     7. جدول PROVIDERS (تامین‌کنندگان)
//     ========================= */
//  await shopRef.collection("providers").add({
//    name: "Roshan",
//    type: "TELECOM",
//    ordinary_code: "111",
//    wholesale_code: "222",
//  });
//  console.log("✅ پرووایدر اضافه شد.");
//
//  /* =========================
//     8. جدول PROVIDER_BALANCES (موجودی) - مهم
//     ========================= */
//  // نام کالکشن دقیقاً provider_balances شد
//  await shopRef.collection("provider_balances").add({
//    provider_name: "Roshan",
//    current_balance: 5000.0,
//    shop_id: shopId,
//    // فیلد unique در sqlite چک می‌شود (provider_name, shop_id)
//  });
//  console.log("✅ موجودی (Balance) اضافه شد.");
//
//  /* =========================
//     9. جدول PAPER_STOCK (کارت‌های کاغذی)
//     ========================= */
//  await shopRef.collection("paper_stock").add({
//    operator: "Roshan",
//    face_value: 50,
//    quantity: 200,
//    shop_id: shopId,
//  });
//  console.log("✅ موجودی کارت کاغذی اضافه شد.");
//
//  /* =========================
//     10. جدول PURCHASES (خریدها)
//     ========================= */
//  await shopRef.collection("purchases").add({
//    type: "BUY_CREDIT",
//    provider_name: "Roshan",
//    operator_name: "Roshan",
//    face_value: 0,
//    quantity: 1,
//    total_credit: 5000.0,
//    nominal_price: 5000.0,
//    actual_paid: 4800.0,
//    discount_amount: 200.0,
//    cost_per_unit: 4800.0,
//    payment_status: "PAID",
//    payment_date: new Date().toISOString(),
//    created_at: new Date().toISOString(), // چون در SQLite نوع TEXT است
//    shop_id: shopId,
//    created_by: owner.uid
//  });
//  console.log("✅ رکورد خرید اضافه شد.");
//
//  /* =========================
//     11. جدول TRANSACTIONS (تراکنش‌ها)
//     ========================= */
//  await shopRef.collection("transactions").add({
//    // مشخصات مشتری
//    customer_id: null, // برای تست Null می‌گذاریم (یا ID عددی اگر دارید)
//    customer_name: "مشتری رهگذر",
//    customer_type: "WALK_IN",
//
//    // مشخصات سیستم
//    shop_id: shopId,
//    created_by: owner.uid,
//    is_synced: 1, // در سرور همیشه 1 است
//
//    // مشخصات سرویس
//    transaction_type: "DIGITAL",
//    operator_name: "Roshan",
//    phone_number: "0799123456",
//    company_code: null,
//
//    // مقادیر مالی
//    sent_amount: 100.0,
//    quantity: 1,
//    total_price: 100.0,
//    discount: 0.0,
//    paid_amount: 100.0,
//    remaining_amount: 0.0,
//
//    // سود و زیان
//    cost_price: 95.0,
//    profit: 5.0,
//
//    received_amount: 100.0,
//    ussd_command: "*123*...",
//    created_at: new Date().toISOString() // فرمت استاندارد ISO8601
//  });
//  console.log("✅ تراکنش نمونه اضافه شد.");
//
//  console.log("\n===========================================");
//  console.log("🎉 دیتابیس با موفقیت طبق ساختار SQLite ساخته شد.");
//  console.log(`🔑 ایمیل ورود: ${USER_EMAIL}`);
//  console.log(`🔑 رمز عبور: ${USER_PASS}`);
//  console.log(`🆔 Shop ID: ${shopId}`);
//  console.log("===========================================\n");
//}
//
//// اجرای تابع
//seedFirestore()
//  .then(() => process.exit(0))
//  .catch((err) => {
//    console.error("❌ خطا در اجرای اسکریپت:", err);
//    process.exit(1);
//  });
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

// تنظیمات مدیر
const OWNER_EMAIL = "admin@shop.com";
const OWNER_PASS = "12345678";

// تنظیمات کارمند (اضافه شده)
const STAFF_EMAIL = "staff@shop.com";
const STAFF_PASS = "12345678";

async function seedFirestore() {
  console.log("🚀 شروع عملیات Seed دیتابیس (شامل مدیر و کارمند)...");

  /* =========================
     1. ایجاد مدیر (OWNER)
     ========================= */
  let owner;
  try {
    owner = await auth.createUser({
      email: OWNER_EMAIL,
      password: OWNER_PASS,
      displayName: "مدیر فروشگاه",
    });
    console.log("✅ مدیر (Auth) ساخته شد:", owner.uid);
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      owner = await auth.getUserByEmail(OWNER_EMAIL);
      console.log("ℹ️ مدیر از قبل وجود داشت:", owner.uid);
    } else {
      throw error;
    }
  }

  /* =========================
     2. ایجاد فروشگاه (SHOP)
     ========================= */
  const shopRef = await db.collection("shops").add({
    info: {
      name: "فروشگاه مرکزی",
      owner_uid: owner.uid,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      subscription_status: "active"
    },
  });
  const shopId = shopRef.id;

  /* =========================
     3. ذخیره اطلاعات مدیر
     ========================= */
  const ownerData = {
    uid: owner.uid,
    name: "مدیر فروشگاه",
    email: OWNER_EMAIL,
    role: "OWNER",
    shop_id: shopId,
    shopId: shopId,
  };
  await db.collection("users").doc(owner.uid).set(ownerData);
  await shopRef.collection("users").doc(owner.uid).set(ownerData);

  /* =========================
     4. ایجاد کارمند (STAFF) - جدید
     ========================= */
  let staff;
  try {
    staff = await auth.createUser({
      email: STAFF_EMAIL,
      password: STAFF_PASS,
      displayName: "کارمند علی",
    });
    console.log("✅ کارمند (Auth) ساخته شد:", staff.uid);
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      staff = await auth.getUserByEmail(STAFF_EMAIL);
      console.log("ℹ️ کارمند از قبل وجود داشت:", staff.uid);
    } else {
      throw error; // اگر خطای دیگری بود
    }
  }

  // تنظیم دیتای کارمند (متصل به همان shopId ولی با role متفاوت)
  const staffData = {
    uid: staff.uid,
    name: "کارمند علی",
    email: STAFF_EMAIL,
    role: "STAFF", // نقش کارمند
    shop_id: shopId, // همان دکان مدیر
    shopId: shopId,
    active: true
  };

  // ذخیره در روت (برای لاگین)
  await db.collection("users").doc(staff.uid).set(staffData);
  // ذخیره در زیرمجموعه فروشگاه (برای مدیریت لیست کارمندان)
  await shopRef.collection("users").doc(staff.uid).set(staffData);
  console.log("✅ اطلاعات کارمند در دیتابیس ذخیره شد.");


  /* =========================
     5. دیتای نمونه (با ID های عددی)
     ========================= */

  // مشتریان (با ID = 1)
 const customerId = 1;
   await shopRef.collection("customers").doc(customerId.toString()).set({
     id: customerId,
     name: "مشتری نمونه",
     shop_id: shopId,
    customer_code: "C-1001",
    type: "REGISTERED",

    created_by: owner.uid,
    address: "کابل، بازار اصلی",
    profile_image: "",
    tazkira_image: "",
    created_at: new Date().toISOString(),
  });
  console.log("✅ مشتری با ID 1 اضافه شد.");

  // تلفن مشتری
 await shopRef.collection("customer_phones").doc(customerId.toString()).set({
     id: customerId,          // آی‌دی خودِ ردیف تلفن
     customer_id: customerId, // اشاره به مشتری شماره ۱
     shop_id: shopId,
     phone_number: "0799999999",
   });

  // واحدها
  await shopRef.collection("units").doc("1").set({
    id: 1,
    name: "افغانی",
    buy_price: 1.0,
    sell_price: 1.0,
    shop_id: shopId,
  });

  // تامین کنندگان
 // 7. تامین کنندگان (اصلاح شده)
   await shopRef.collection("providers").doc("1").set({
     id: 1,
     name: "Roshan",
     type: "TELECOM",
     ordinary_code: "111",
     wholesale_code: "222",
     shop_id: shopId, // ✅ این فیلد را اضافه کنید
   });

  // موجودی (Provider Balance)
  await shopRef.collection("provider_balances").doc("1").set({
    id: 1,
    provider_name: "Roshan",
    current_balance: 5000.0,
    shop_id: shopId,
  });

  // کارت کاغذی
  await shopRef.collection("paper_stock").doc("1").set({
    id: 1,
    operator_name: "Roshan",
    face_value: 50,
    quantity: 200,
    shop_id: shopId,
  });

  // خریدها
  await shopRef.collection("purchases").doc("1").set({
    id: 1,
    type: "BUY_CREDIT",
    provider_name: "Roshan",
    operator_name: "Roshan",
    face_value: 0,
    quantity: 1,
    total_credit: 5000.0,
    nominal_price: 5000.0,
    actual_paid: 4800.0,
    discount_amount: 200.0,
    cost_per_unit: 4800.0,
    payment_status: "PAID",
    payment_date: new Date().toISOString(),
    created_at: new Date().toISOString(),
    shop_id: shopId,
    created_by: owner.uid
  });

  // تراکنش‌ها
  await shopRef.collection("transactions").doc("1").set({
    id: 1,
    customer_id: null,
    customer_name: "مشتری رهگذر",
    customer_type: "WALK_IN",
    shop_id: shopId,
    created_by: owner.uid, // این تراکنش توسط مدیر ثبت شده
    is_synced: 1,
    transaction_type: "DIGITAL",
    operator_name: "Roshan",
    phone_number: "0799123456",
    company_code: null,
    sent_amount: 100.0,
    quantity: 1,
    total_price: 100.0,
    discount: 0.0,
    paid_amount: 100.0,
    remaining_amount: 0.0,
    cost_price: 95.0,
    profit: 5.0,
    received_amount: 100.0,
    ussd_command: "*123*...",
    created_at: new Date().toISOString()
  });
  console.log("✅ تراکنش نمونه با ID 1 اضافه شد.");

  console.log("\n===========================================");
  console.log("🎉 دیتابیس با موفقیت آپدیت شد.");
  console.log(`🆔 Shop ID: ${shopId}`);
  console.log("-------------------------------------------");
  console.log(`👤 ADMIN LOGIN:  ${OWNER_EMAIL}  |  ${OWNER_PASS}`);
  console.log(`👷 STAFF LOGIN:  ${STAFF_EMAIL}  |  ${STAFF_PASS}`);
  console.log("===========================================\n");
}

seedFirestore()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ خطا در اجرای اسکریپت:", err);
    process.exit(1);
  });