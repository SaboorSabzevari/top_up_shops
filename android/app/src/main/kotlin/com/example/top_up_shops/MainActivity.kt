package com.example.top_up_shops

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
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

                // تلاش برای پیدا کردن سیم‌کارت مشخص شده
                val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                val activeList = subscriptionManager.activeSubscriptionInfoList

                val subInfo = activeList?.find { it.simSlotIndex == simSlot }

                // اگر سیم‌کارت پیدا شد، از آن استفاده کن، وگرنه از پیش‌فرض
                val finalTm = if (subInfo != null) {
                    tm.createForSubscriptionId(subInfo.subscriptionId)
                } else {
                    tm
                }

                val callback = object : TelephonyManager.UssdResponseCallback() {
                    override fun onReceiveUssdResponse(telephonyManager: TelephonyManager, request: String, response: CharSequence) {
                        result.success(response.toString())
                    }

                    override fun onReceiveUssdResponseFailed(telephonyManager: TelephonyManager, request: String, failureCode: Int) {
                        result.error("USSD_FAILED", "خطای شبکه یا عدم پاسخگویی (کد: $failureCode)", null)
                    }
                }

                finalTm.sendUssdRequest(code, callback, Handler(Looper.getMainLooper()))

            } catch (e: SecurityException) {
                result.error("PERMISSION_DENIED", "مجوز دسترسی داده نشده", e.message)
            } catch (e: Exception) {
                result.error("EXCEPTION", "خطا: ${e.message}", null)
            }
        } else {
            result.error("NOT_SUPPORTED", "اندروید گوشی پایین است", null)
        }
    }
}