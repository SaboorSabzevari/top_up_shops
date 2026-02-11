package com.example.top_up_shops

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.top_up_shops/ussd"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendUssd") {
                val ussdCode = call.argument<String>("code")
                val simSlot = call.argument<Int>("slot") ?: 0

                if (ussdCode != null) {
                    executeUssd(ussdCode, simSlot, result)
                } else {
                    result.error("INVALID_CODE", "کد USSD خالی است", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun executeUssd(code: String, simSlot: Int, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

                // بررسی وجود سیم‌کارت در اسلات مورد نظر
                val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                val activeList = subscriptionManager.activeSubscriptionInfoList

                if (activeList == null || activeList.isEmpty()) {
                    result.error("NO_SIM", "هیچ سیم‌کارتی یافت نشد", null)
                    return
                }

                val subInfo = activeList.find { it.simSlotIndex == simSlot }

                if (subInfo == null) {
                    result.error("SIM_NOT_FOUND",
                        "سیم‌کارت در اسلات ${simSlot + 1} یافت نشد. لطفاً سیم‌کارت را بررسی کنید.",
                        null)
                    return
                }

                val finalTm = tm.createForSubscriptionId(subInfo.subscriptionId)

                val callback = object : TelephonyManager.UssdResponseCallback() {
                    override fun onReceiveUssdResponse(telephonyManager: TelephonyManager,
                                                       request: String,
                                                       response: CharSequence) {
                        result.success(response.toString())
                    }

                    override fun onReceiveUssdResponseFailed(telephonyManager: TelephonyManager,
                                                             request: String,
                                                             failureCode: Int) {
                        // لاگ خطا برای دیباگ
                        Log.e("USSD_ERROR", "کد خطا: $failureCode, درخواست: $request")

                        when (failureCode) {
                            -1 -> result.error("NETWORK_ERROR",
                                "خطای شبکه یا عدم پاسخگویی اپراتور. لطفاً اتصال شبکه را بررسی کنید.",
                                null)
                            else -> result.error("USSD_FAILED",
                                "خطای USSD (کد: $failureCode)", null)
                        }
                    }
                }

                finalTm.sendUssdRequest(code, callback, Handler(Looper.getMainLooper()))

            } catch (e: SecurityException) {
                result.error("PERMISSION_DENIED",
                    "مجوز دسترسی داده نشده. لطفاً مجوزهای تماس و سیم‌کارت را فعال کنید.",
                    e.message)
            } catch (e: Exception) {
                result.error("EXCEPTION", "خطا: ${e.message}", null)
            }
        } else {
            result.error("NOT_SUPPORTED",
                "این ویژگی نیاز به اندروید ۸ (Oreo) یا بالاتر دارد",
                null)
        }
    }
}