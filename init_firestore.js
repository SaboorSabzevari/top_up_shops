//const admin = require("firebase-admin");
//
//const serviceAccount = require("./serviceAccountKey.json");
//
//
//admin.initializeApp({
//  credential: admin.credential.cert(serviceAccount),
//});
//
//const db = admin.firestore();
//const auth = admin.auth();
//
//async function seedFirestore() {
//  /* =========================
//     1. CREATE USERS (AUTH)
//     ========================= */
//  const owner = await auth.createUser({
//    email: "ewq@shop.com",
//    password: "1234567890",
//    displayName: "احasمد",
//  });
//
//  const staff = await auth.createUser({
//    email: "qwe@shop.com",
//    password: "0987654321",
//    displayName: "علdjfdfی",
//  });
//
//  /* =========================
//     2. CREATE SHOP
//     ========================= */
//  const shopRef = await db.collection("shops").add({
//    info: {
//      name: "فروشگاه ستارگان",
//      owner_uid: owner.uid,
//      max_employees: 3,
//      created_at: admin.firestore.FieldValue.serverTimestamp(),
//    },
//  });
//
//  const shopId = shopRef.id;
//  console.log("Shop created:", shopId);
//
//  /* =========================
//     3. USERS SUBCOLLECTION
//     ========================= */
//  await shopRef.collection("users").doc(owner.uid).set({
//    uid: owner.uid,
//    name: "احمد",
//    email: owner.email,
//    role: "OWNER",
//    active: true,
//  });
//
//  await shopRef.collection("users").doc(staff.uid).set({
//    uid: staff.uid,
//    name: "علی",
//    email: staff.email,
//    role: "STAFF",
//    active: true,
//  });
//
//  /* =========================
//     4. CUSTOMER
//     ========================= */
//  const customerRef = await shopRef.collection("customers").add({
//    name: "مشتری تست",
//    customer_code: "C-001",
//    type: "REGISTERED",
//    shop_id: shopId,
//    created_by: staff.uid,
//    created_at: admin.firestore.FieldValue.serverTimestamp(),
//  });
//
//  /* =========================
//     5. PROVIDERS
//     ========================= */
//  const providerRef = await shopRef.collection("providers").add({
//    name: "ستارگان متحد",
//    type: "AWCC",
//    ordinary_code: "543*2",
//    wholesale_code: "543*6",
//    shop_id: shopId,
//  });
//
//  /* =========================
//     6. PROVIDER BALANCE
//     ========================= */
//  await shopRef.collection("provider_balances").add({
//    provider_name: "ستارگان متحد",
//    current_balance: 10000,
//    shop_id: shopId,
//    updated_at: admin.firestore.FieldValue.serverTimestamp(),
//  });
//
//  /* =========================
//     7. UNIT
//     ========================= */
//  await shopRef.collection("units").add({
//    name: "واحد اصلی",
//    buy_price: 0.95,
//    sell_price: 0.96,
//    shop_id: shopId,
//  });
//
//  /* =========================
//     8. PAPER STOCK
//     ========================= */
//  await shopRef.collection("paper_stock").add({
//    operator: "AWCC",
//    face_value: 50,
//    quantity: 100,
//    shop_id: shopId,
//  });
//
//  /* =========================
//     9. PURCHASE
//     ========================= */
//  await shopRef.collection("purchases").add({
//    type: "WHOLESALE",
//    provider_name: "ستارگان متحد",
//    quantity: 100,
//    total_credit: 5000,
//    actual_paid: 4800,
//    created_by: owner.uid,
//    shop_id: shopId,
//    created_at: admin.firestore.FieldValue.serverTimestamp(),
//  });
//
//  /* =========================
//     10. TRANSACTION
//     ========================= */
//  await shopRef.collection("transactions").add({
//    customer_id: customerRef.id,
//    customer_name: "مشتری تست",
//    customer_type: "REGISTERED",
//    transaction_type: "DIGITAL",
//    operator_name: "AWCC",
//    phone_number: "0700000000",
//    sent_amount: 50,
//    quantity: 1,
//    total_price: 50,
//    paid_amount: 50,
//    remaining_amount: 0,
//    profit: 5,
//    created_by: staff.uid,
//    created_role: "STAFF",
//    shop_id: shopId,
//    created_at: admin.firestore.FieldValue.serverTimestamp(),
//  });
//
//  console.log("✅ Firestore FULL seed completed");
//}
//
//seedFirestore()
//  .then(() => process.exit())
//  .catch(err => {
//    console.error(err);
//    process.exit(1);
//  });
// seed-firestore-fixed.js
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

async function seedFirestore() {
  /* =========================
     1. CREATE USERS (AUTH) - با ایمیل ewq@shop.com
  ========================= */
  const owner = await auth.createUser({
    email: "ewqrtyu@shop.com", // ← ایمیل لاگین شما
    password: "12345678",
    displayName: "احمد",
  });
  console.log("✅ کاربر Auth ایجاد شد:");
  console.log("  UID:", owner.uid);
  console.log("  Email:", owner.email);

  /* =========================
     2. CREATE SHOP
  ========================= */
  const shopRef = await db.collection("shops").add({
    info: {
      name: "فروشگاه تست",
      owner_uid: owner.uid,
      max_employees: 5,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    },
  });

  const shopId = shopRef.id;
  console.log("✅ Shop created:", shopId);

  /* =========================
     3. CREATE USER IN ROOT USERS COLLECTION (CRITICAL!)
  ========================= */
  await db.collection("users").doc(owner.uid).set({
    uid: owner.uid,
    email: owner.email,
    role: "OWNER", // یا "STAFF" برای کارمند
    shopId: shopId,
    name: "احمد",
    active: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("✅ کاربر در Firestore ذخیره شد");

  /* =========================
     4. CREATE SHOP SUBCOLLECTIONS (اختیاری)
  ========================= */
  await shopRef.collection("users").doc(owner.uid).set({
    uid: owner.uid,
    name: "احمد",
    email: owner.email,
    role: "OWNER",
    active: true,
  });

  /* =========================
     5. CREATE SAMPLE DATA
  ========================= */
  // مشتری
  await shopRef.collection("customers").add({
    name: "مشتری تست",
    customer_code: "C-001",
    type: "REGISTERED",
    shop_id: shopId,
    created_by: owner.uid,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  // واحد
  await shopRef.collection("units").add({
    name: "واحد اصلی",
    buy_price: 0.95,
    sell_price: 0.96,
    shop_id: shopId,
  });

  console.log("✅ داده‌های تست ایجاد شدند");
  console.log("\n📋 اطلاعات ورود:");
  console.log("ایمیل: ewqrtyu@shop.com");
  console.log("رمز: 12345678");
  console.log("Shop ID:", shopId);
  console.log("User UID:", owner.uid);
}

seedFirestore()
  .then(() => {
    console.log("\n✅ تمام عملیات با موفقیت انجام شد");
    process.exit(0);
  })
  .catch(err => {
    console.error("❌ خطا:", err);
    process.exit(1);
  });