package com.survivaldiary.project_survival_diary

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Telephony

class PaymentSmsInboxReader(context: Context) {
    private val appContext = context.applicationContext
    private val store = PaymentNotificationStore(appContext)

    fun hasReadPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            appContext.checkSelfPermission(Manifest.permission.READ_SMS) ==
            PackageManager.PERMISSION_GRANTED

    fun scanRecent(): List<DetectedExpenseCandidate> {
        check(hasReadPermission()) { "문자 읽기 권한이 필요합니다." }
        val detected = mutableListOf<DetectedExpenseCandidate>()
        val since = System.currentTimeMillis() - LOOKBACK_MS
        val projection = arrayOf("_id", "address", "body", "date")
        appContext.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            "date >= ?",
            arrayOf(since.toString()),
            "date DESC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow("_id")
            val addressIndex = cursor.getColumnIndexOrThrow("address")
            val bodyIndex = cursor.getColumnIndexOrThrow("body")
            val dateIndex = cursor.getColumnIndexOrThrow("date")
            var examined = 0
            while (cursor.moveToNext() && examined < MAX_MESSAGES) {
                examined += 1
                val messageId = cursor.getLong(idIndex).toString()
                val sender = cursor.getString(addressIndex).orEmpty()
                val body = cursor.getString(bodyIndex).orEmpty()
                val candidate = PaymentSmsParser.parse(
                    PaymentSmsParser.SmsContent(
                        messageId = messageId,
                        sender = sender,
                        body = body,
                        receivedAt = cursor.getLong(dateIndex),
                    ),
                )
                if (candidate == null) {
                    continue
                }
                store.add(candidate)?.let(detected::add)
            }
        }
        return detected
    }

    companion object {
        private const val MAX_MESSAGES = 500
        private const val LOOKBACK_MS = 30L * 24 * 60 * 60 * 1000
    }
}
