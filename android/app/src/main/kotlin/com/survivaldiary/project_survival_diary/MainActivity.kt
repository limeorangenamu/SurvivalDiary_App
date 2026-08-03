package com.survivaldiary.project_survival_diary

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val smsExecutor = Executors.newSingleThreadExecutor()
    private var pendingSmsPermissionResult: MethodChannel.Result? = null
    private var pendingExpenseAlertPermissionResult: MethodChannel.Result? = null

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
                "getSmsAccessState" -> result.success(getSmsAccessState())
                "requestSmsAccess" -> requestSmsAccess(result)
                "requestExpenseAlertPermission" -> requestExpenseAlertPermission(result)
                "scanSmsInbox" -> scanSmsInbox(result)
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            SMS_PERMISSION_REQUEST_CODE -> {
                pendingSmsPermissionResult?.success(hasSmsReadPermission())
                pendingSmsPermissionResult = null
            }
            EXPENSE_ALERT_PERMISSION_REQUEST_CODE -> {
                pendingExpenseAlertPermissionResult?.success(hasExpenseAlertPermission())
                pendingExpenseAlertPermissionResult = null
            }
        }
    }

    override fun onDestroy() {
        pendingSmsPermissionResult?.error(
            "ACTIVITY_DESTROYED",
            "문자 접근 요청을 완료하지 못했습니다.",
            null,
        )
        pendingSmsPermissionResult = null
        pendingExpenseAlertPermissionResult?.error(
            "ACTIVITY_DESTROYED",
            "지출 감지 알림 권한 요청을 완료하지 못했습니다.",
            null,
        )
        pendingExpenseAlertPermissionResult = null
        smsExecutor.shutdownNow()
        super.onDestroy()
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

    private fun getSmsAccessState(): String {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
            return "unsupported"
        }
        return when {
            hasSmsAccessPermissions() -> "enabled"
            hasSmsReadPermission() -> "read_only"
            else -> "disabled"
        }
    }

    private fun hasSmsReadPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED

    private fun hasSmsReceivePermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED

    private fun hasMmsReceivePermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.RECEIVE_MMS) == PackageManager.PERMISSION_GRANTED

    private fun hasWapPushReceivePermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.RECEIVE_WAP_PUSH) ==
            PackageManager.PERMISSION_GRANTED

    private fun hasSmsAccessPermissions(): Boolean =
        hasSmsReadPermission() && hasSmsReceivePermission() &&
            hasMmsReceivePermission() && hasWapPushReceivePermission()

    private fun hasExpenseAlertPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestExpenseAlertPermission(result: MethodChannel.Result) {
        if (hasExpenseAlertPermission()) {
            result.success(true)
            return
        }
        if (pendingExpenseAlertPermissionResult != null) {
            result.error(
                "REQUEST_IN_PROGRESS",
                "지출 감지 알림 권한을 요청하고 있습니다.",
                null,
            )
            return
        }

        pendingExpenseAlertPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            EXPENSE_ALERT_PERMISSION_REQUEST_CODE,
        )
    }

    private fun requestSmsAccess(result: MethodChannel.Result) {
        if (getSmsAccessState() == "unsupported") {
            result.success(false)
            return
        }
        if (hasSmsAccessPermissions()) {
            result.success(true)
            return
        }
        if (pendingSmsPermissionResult != null) {
            result.error("REQUEST_IN_PROGRESS", "문자 접근 권한을 요청하고 있습니다.", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(true)
            return
        }

        pendingSmsPermissionResult = result
        requestPermissions(
            arrayOf(
                Manifest.permission.READ_SMS,
                Manifest.permission.RECEIVE_SMS,
                Manifest.permission.RECEIVE_MMS,
                Manifest.permission.RECEIVE_WAP_PUSH,
            ),
            SMS_PERMISSION_REQUEST_CODE,
        )
    }

    private fun scanSmsInbox(result: MethodChannel.Result) {
        if (!hasSmsReadPermission()) {
            result.error("SMS_PERMISSION_DENIED", "문자 읽기 권한이 필요합니다.", null)
            return
        }
        smsExecutor.execute {
            runCatching {
                PaymentSmsInboxReader(this).scanRecent() +
                    PaymentMmsInboxReader(this).scanRecent()
            }
                .onSuccess { candidates ->
                    candidates.forEach(PaymentNotificationEventBus::publish)
                    runOnUiThread { result.success(candidates.size) }
                }
                .onFailure { error ->
                    runOnUiThread {
                        result.error(
                            "SMS_SCAN_FAILED",
                            error.message ?: "문자함을 확인하지 못했습니다.",
                            null,
                        )
                    }
                }
        }
    }

    companion object {
        private const val METHOD_CHANNEL =
            "com.survivaldiary.project_survival_diary/payment_notifications"
        private const val EVENT_CHANNEL =
            "com.survivaldiary.project_survival_diary/payment_notification_events"
        private const val SMS_PERMISSION_REQUEST_CODE = 7201
        private const val EXPENSE_ALERT_PERMISSION_REQUEST_CODE = 7202
    }
}
