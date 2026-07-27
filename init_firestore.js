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

const STAFF_EMAIL = "staff@shop.com";
const STAFF_PASS = "12345678";

async function seedFirestore() {
  console.log("🚀 شروع عملیات Seed دیتابیس با ساختار جدید...");

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


  const shopRef = await db.collection("shops").add({
    info: {
      name: "فروشگاه مرکزی",
      owner_uid: owner.uid,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      subscription_status: "active"
    },
  });
  const shopId = shopRef.id;
  console.log(`🆔 Shop ID ایجاد شد: ${shopId}`);
const ownerData = {
    uid: owner.uid,
    name: "مدیر فروشگاه",
    email: OWNER_EMAIL,
    role: "OWNER",
    shop_id: shopId,
    shopId: shopId,
    active: true
  };
  await db.collection("users").doc(owner.uid).set(ownerData);
  await shopRef.collection("users").doc(owner.uid).set(ownerData);
  console.log("✅ اطلاعات مدیر ذخیره شد.");

  /* =========================
     4. ایجاد کارمند (STAFF)
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
      throw error;
    }
  }

  const staffData = {
    uid: staff.uid,
    name: "کارمند علی",
    email: STAFF_EMAIL,
    role: "STAFF",
    shop_id: shopId,
    shopId: shopId,
    active: true
  };

  await db.collection("users").doc(staff.uid).set(staffData);
  await shopRef.collection("users").doc(staff.uid).set(staffData);
  console.log("✅ اطلاعات کارمند ذخیره شد.");

  /* =========================
     5. دیتای نمونه (ساختار جدید)
     ========================= */

  // 5.1 واحدها (Units)
  await shopRef.collection("units").doc("1").set({
    id: 1,
    name: "افغانی",
    buy_price: 0.95,
    sell_price: 0.96,
    shop_id: shopId,
    created_at: new Date().toISOString(),
  });
  console.log("✅ واحد با ID 1 اضافه شد.");

  // 5.2 تامین کنندگان (Providers)
//  await shopRef.collection("providers").doc("1").set({
//    id: 1,
//    name: "Roshan",
//    type: "TELECOM",
//    ordinary_code: "111",
//    wholesale_code: "222",
//    shop_id: shopId,
//    created_at: new Date().toISOString(),
//  });
//  console.log("✅ تامین‌کننده با ID 1 اضافه شد.");

  // 5.3 موجودی تامین‌کنندگان (Provider Balances)

  // 5.4 مشتریان (Customers) - ساختار جدید با JSON fields
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

    // ✅ ساختار جدید: تلفن‌ها به صورت JSON string
    phones: JSON.stringify(["0799999999", "0788888888"]),

    // ✅ ساختار جدید: کدهای عمده به صورت JSON string
    wholesale_codes: JSON.stringify([
      { company: "Roshan", code: "COMP001" },
      { company: "شرکت نمونه", code: "COMP002" }
    ]),

    created_at: new Date().toISOString(),
  });
  console.log("✅ مشتری با ID 1 اضافه شد (ساختار جدید).");

  // 5.5 مشتری عمده برای تست (Wholesale Customer)
  await shopRef.collection("customers").doc("2").set({
    id: 2,
    name: "مشتری عمده نمونه",
    shop_id: shopId,
    customer_code: "C-2001",
    type: "WHOLESALE",
    created_by: owner.uid,
    address: "کابل، منطقه تجاری",
    profile_image: "",
    tazkira_image: "",

    // ✅ ساختار جدید: تلفن‌ها
    phones: JSON.stringify(["0777777777"]),

    // ✅ ساختار جدید: کدهای عمده
    wholesale_codes: JSON.stringify([
      { company: "افغان پی", code: "WHOLESALE001" },
      { company: "ستارگان متحد", code: "STAR001" }
    ]),

    created_at: new Date().toISOString(),
  });
  console.log("✅ مشتری عمده با ID 2 اضافه شد.");

  // 5.6 کارت کاغذی (Paper Stock)

  // 5.7 خریدها (Purchases)
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
  console.log("✅ خرید با ID 1 اضافه شد.");

  // 5.8 تراکنش‌ها (Transactions)
  // تراکنش برای مشتری عادی
  await shopRef.collection("transactions").doc("1").set({
    id: 1,
    customer_id: customerId,
    customer_name: "مشتری نمونه",
    customer_type: "REGISTERED",
    shop_id: shopId,
    created_by: owner.uid,
    is_synced: 1,
    transaction_type: "DIGITAL",
    operator_name: "Roshan",
    phone_number: "0799999999",
    company_code: null,
    sent_amount: 100.0,
    quantity: 1,
    total_price: 96.0,
    discount: 0.0,
    paid_amount: 96.0,
    remaining_amount: 0.0,
    cost_price: 95.0,
    profit: 1.0,
    received_amount: 96.0,
    ussd_command: "*111*0799999999*100#",
    created_at: new Date().toISOString()
  });

  // تراکنش برای مشتری رهگذر
  await shopRef.collection("transactions").doc("2").set({
    id: 2,
    customer_id: null,
    customer_name: "مشتری رهگذر",
    customer_type: "WALK_IN",
    shop_id: shopId,
    created_by: staff.uid,
    is_synced: 1,
    transaction_type: "DIGITAL",
    operator_name: "Roshan",
    phone_number: "0799123456",
    company_code: null,
    sent_amount: 50.0,
    quantity: 1,
    total_price: 48.0,
    discount: 0.0,
    paid_amount: 48.0,
    remaining_amount: 0.0,
    cost_price: 47.5,
    profit: 0.5,
    received_amount: 48.0,
    ussd_command: "*111*0799123456*50#",
    created_at: new Date().toISOString()
  });

  // تراکنش برای مشتری عمده
  await shopRef.collection("transactions").doc("3").set({
    id: 3,
    customer_id: 2,
    customer_name: "مشتری عمده نمونه",
    customer_type: "REGISTERED",
    shop_id: shopId,
    created_by: owner.uid,
    is_synced: 1,
    transaction_type: "DIGITAL",
    operator_name: "Roshan",
    phone_number: "0777777777",
    company_code: "WHOLESALE001",
    sent_amount: 1000.0,
    quantity: 1,
    total_price: 950.0,
    discount: 50.0,
    paid_amount: 900.0,
    remaining_amount: 50.0,
    cost_price: 950.0,
    profit: 0.0,
    received_amount: 900.0,
    ussd_command: "*222*WHOLESALE001*1000#",
    created_at: new Date().toISOString()
  });

  console.log("✅ ۳ تراکنش نمونه اضافه شد.");

  /* =========================
     6. اضافه کردن تامین‌کنندگان بیشتر برای تست
     ========================= */
//  const additionalProviders = [
//    {
//      id: 2,
//      name: "ستارگان متحد",
//      type: "ستارگان متحد",
//      ordinary_code: "543*2",
//      wholesale_code: "543*6",
//      shop_id: shopId,
//      created_at: new Date().toISOString(),
//    },
//    {
//      id: 3,
//      name: "اکتیو سرویس",
//      type: "اکتیو سرویس",
//      ordinary_code: "683",
//      wholesale_code: "683*2",
//      shop_id: shopId,
//      created_at: new Date().toISOString(),
//    },
//    {
//      id: 4,
//      name: "افغان پی",
//      type: "افغان پی",
//      ordinary_code: "511",
//      wholesale_code: "511*5",
//      shop_id: shopId,
//      created_at: new Date().toISOString(),
//    },
//    {
//      id: 5,
//      name: "شاهی ایزیلود",
//      type: "شاهی ایزیلود",
//      ordinary_code: "545",
//      wholesale_code: "511*5",
//      shop_id: shopId,
//      created_at: new Date().toISOString(),
//    },
//  ];
//
//  for (const provider of additionalProviders) {
//    await shopRef.collection("providers").doc(provider.id.toString()).set(provider);
//  }
//  console.log(`✅ ${additionalProviders.length} تامین‌کننده اضافی اضافه شد.`);

  /* =========================
     7. اضافه کردن موجودی برای تامین‌کنندگان اضافی
     ========================= */
  const additionalBalances = [
    {
      id: 2,
      provider_name: "ستارگان متحد",
      current_balance: 3000.0,
      shop_id: shopId,
      updated_at: new Date().toISOString(),
    },
    {
      id: 3,
      provider_name: "اکتیو سرویس",
      current_balance: 2500.0,
      shop_id: shopId,
      updated_at: new Date().toISOString(),
    },
    {
      id: 4,
      provider_name: "افغان پی",
      current_balance: 4000.0,
      shop_id: shopId,
      updated_at: new Date().toISOString(),
    },
  ];

  for (const balance of additionalBalances) {
    await shopRef.collection("provider_balances").doc(balance.id.toString()).set(balance);
  }
  console.log(`✅ ${additionalBalances.length} موجودی اضافی اضافه شد.`);


  console.log("\n" + "=".repeat(50));
  console.log("🎉 دیتابیس با ساختار جدید با موفقیت ساخته شد!");
  console.log("=".repeat(50));
  console.log(`🆔 Shop ID: ${shopId}`);
  console.log("-".repeat(50));
  console.log("📊 داده‌های نمونه:");
  console.log("  • 2 مشتری (1 عادی، 1 عمده)");
  console.log("  • 5 تامین‌کننده");
  console.log("  • 4 موجودی تامین‌کننده");
  console.log("  • 4 کارت کاغذی");
  console.log("  • 1 واحد (نرخ)");
  console.log("  • 1 خرید");
  console.log("  • 3 تراکنش");
  console.log("-".repeat(50));
  console.log("👤 اطلاعات ورود:");
  console.log(`  مدیر:   ${OWNER_EMAIL}  |  ${OWNER_PASS}`);
  console.log(`  کارمند: ${STAFF_EMAIL}  |  ${STAFF_PASS}`);
  console.log("=".repeat(50) + "\n");
}

seedFirestore()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ خطا در اجرای اسکریپت:", err);
    process.exit(1);
  });