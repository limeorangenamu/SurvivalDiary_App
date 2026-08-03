package com.survivaldiary.project_survival_diary

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val store = PaymentNotificationStore(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDetectedExpenses" -> result.success(
                    store.getAll().map(DetectedExpenseCandidate::toMap),
                )
                "isNotificationAccessGranted" -> result.success(
                    isNotificationAccessGranted(),
                )
                "openNotificationAccessSettings" -> {
                    openNotificationAccessSettings()
                    result.success(null)
                }
                "removeDetectedExpense" -> {
                    val id = call.argument<String>("id")
                    if (id.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "감지 내역 ID가 필요합니다.", null)
                    } else {
                        result.success(store.remove(id))
                    }
                }
                "updateDetectedExpense" -> {
                    val id = call.argument<String>("id")
                    val merchant = call.argument<String>("merchant")?.trim()
                    val amount = call.argument<Number>("amount")?.toInt()
                    val category = call.argument<String>("category")
                    if (
                        id.isNullOrBlank() || merchant.isNullOrBlank() ||
                        amount == null || amount <= 0 || category.isNullOrBlank()
                    ) {
                        result.error("INVALID_ARGUMENT", "수정할 감지 내역이 올바르지 않습니다.", null)
                    } else {
                        result.success(store.update(id, merchant, amount, category))
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                PaymentNotificationEventBus.setListener { candidate ->
                    events?.success(candidate)
                }
            }

            override fun onCancel(arguments: Any?) {
                PaymentNotificationEventBus.setListener(null)
            }
        })
    }

    private fun isNotificationAccessGranted(): Boolean {
        val component = ComponentName(this, PaymentNotificationListenerService::class.java)
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ).orEmpty()
        return enabledListeners.split(':')
            .mapNotNull(ComponentName::unflattenFromString)
            .any { it == component }
    }

    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        runCatching { startActivity(intent) }
            .onFailure { startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS)) }
    }

    companion object {
        private const val METHOD_CHANNEL =
            "com.survivaldiary.project_survival_diary/payment_notifications"
        private const val EVENT_CHANNEL =
            "com.survivaldiary.project_survival_diary/payment_notification_events"
    }
}
