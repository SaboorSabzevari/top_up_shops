const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteCollection(collectionPath, batchSize = 500) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, batchSize, resolve, reject);
  });
}

async function deleteQueryBatch(query, batchSize, resolve, reject) {
  try {
    const snapshot = await query.get();

    // اگر هیچ سندی وجود نداشته باشد
    if (snapshot.empty) {
      console.log(`   ✅ کالکشن ${query._queryOptions.collectionId} خالی است`);
      resolve();
      return;
    }

    // حذف اسناد در batch
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`   ✅ ${snapshot.size} سند از ${query._queryOptions.collectionId} حذف شد`);

    // اگر batch کامل بود، batch بعدی را پردازش کن
    if (snapshot.size === batchSize) {
      // Recurse on the next process tick, to avoid
      // exploding the stack.
      process.nextTick(() => {
        deleteQueryBatch(query, batchSize, resolve, reject);
      });
    } else {
      resolve();
    }
  } catch (error) {
    reject(error);
  }
}

async function deleteSubcollections(docRef) {
  try {
    const collections = await docRef.listCollections();

    for (const subcollectionRef of collections) {
      console.log(`   🔍 بررسی زیرکالکشن: ${subcollectionRef.id}`);
      await deleteCollection(`${docRef.parent.id}/${docRef.id}/${subcollectionRef.id}`);
      console.log(`   ✅ زیرکالکشن ${subcollectionRef.id} پاک شد`);
    }
  } catch (error) {
    console.error(`   ❌ خطا در پاک کردن زیرکالکشن‌ها:`, error);
  }
}

async function deleteAllData() {
  console.log("🚨🚨🚨 هشدار: این عمل تمام داده‌های Firestore را پاک می‌کند! 🚨🚨🚨");
  console.log("این عملیات غیرقابل بازگشت است!");

  // تاییدیه از کاربر
  const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    readline.question('آیا مطمئن هستید؟ برای تایید کلمه "DELETE" را وارد کنید: ', async (answer) => {
      readline.close();

      if (answer !== 'DELETE') {
        console.log("❌ عملیات لغو شد");
        process.exit(0);
      }

      try {
        console.log("\n🧹 شروع پاک‌سازی کامل Firestore...\n");

        /* =========================
           پاک کردن تمام کالکشن‌ها
        ========================= */
        const collections = await db.listCollections();

        for (const collectionRef of collections) {
          const collectionName = collectionRef.id;
          console.log(`\n📦 پردازش کالکشن: ${collectionName}`);

          // اگر کالکشن shops باشد، ابتدا زیرکالکشن‌ها را پاک می‌کنیم
          if (collectionName === 'shops') {
            console.log(`   🔍 بررسی shops و زیرمجموعه‌های آن...`);

            // گرفتن تمام shops
            const shopsSnapshot = await db.collection('shops').get();

            for (const shopDoc of shopsSnapshot.docs) {
              const shopRef = db.collection('shops').doc(shopDoc.id);
              console.log(`   🏪 پردازش shop: ${shopDoc.id}`);

              // پاک کردن تمام زیرکالکشن‌های این shop
              await deleteSubcollections(shopRef);

              // حذف خود shop
              await shopRef.delete();
              console.log(`   ✅ shop ${shopDoc.id} حذف شد`);
            }
          } else {
            // برای کالکشن‌های دیگر، بررسی زیرکالکشن‌ها
            const docsSnapshot = await db.collection(collectionName).get();

            for (const doc of docsSnapshot.docs) {
              const docRef = db.collection(collectionName).doc(doc.id);

              // بررسی و پاک کردن زیرکالکشن‌ها
              await deleteSubcollections(docRef);
            }

            // پاک کردن خود کالکشن
            await deleteCollection(collectionName);
          }

          console.log(`✅ کالکشن ${collectionName} کامل پاک شد`);
        }

        /* =========================
           پاک کردن کاربران از Authentication
        ========================= */
        console.log("\n👤 پاک کردن کاربران از Authentication...");
        try {
          const auth = admin.auth();
          const userList = await auth.listUsers();

          for (const userRecord of userList.users) {
            await auth.deleteUser(userRecord.uid);
            console.log(`   ✅ کاربر ${userRecord.email || userRecord.uid} حذف شد`);
          }
          console.log(`✅ ${userList.users.length} کاربر از Auth حذف شدند`);
        } catch (authError) {
          console.log(`   ⚠️ خطا در پاک کردن Auth: ${authError.message}`);
        }

        console.log("\n🎉🎉🎉 تمام داده‌ها با موفقیت پاک شدند! 🎉🎉🎉");
        console.log("\n📊 خلاصه عملیات:");
        console.log("- تمام کالکشن‌های Firestore پاک شدند");
        console.log("- تمام زیرکالکشن‌ها پاک شدند");
        console.log("- تمام کاربران Authentication پاک شدند");
        console.log("\n🔥 Firestore کاملاً خالی شد!");

      } catch (error) {
        console.error("❌ خطای بحرانی:", error);
        process.exit(1);
      }

      resolve();
    });
  });
}

// اجرای اصلی
deleteAllData()
  .then(() => {
    console.log("\n✅ اسکریپت با موفقیت اجرا شد");
    process.exit(0);
  })
  .catch(error => {
    console.error("❌ خطا در اجرای اسکریپت:", error);
    process.exit(1);
  });