package com.survivaldiary.project_survival_diary

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Telephony

class PaymentMmsInboxReader(context: Context) {
    private val appContext = context.applicationContext
    private val resolver = appContext.contentResolver
    private val store = PaymentNotificationStore(appContext)

    fun hasReadPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            appContext.checkSelfPermission(Manifest.permission.READ_SMS) ==
            PackageManager.PERMISSION_GRANTED

    fun scanRecent(): List<DetectedExpenseCandidate> {
        check(hasReadPermission()) { "장문 문자 읽기 권한이 필요합니다." }
        val detected = mutableListOf<DetectedExpenseCandidate>()
        val sinceSeconds = (System.currentTimeMillis() - LOOKBACK_MS) / 1000L
        var examined = 0

        resolver.query(
            Telephony.Mms.Inbox.CONTENT_URI,
            arrayOf("_id", "date"),
            "date >= ?",
            arrayOf(sinceSeconds.toString()),
            "date DESC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow("_id")
            val dateIndex = cursor.getColumnIndexOrThrow("date")
            while (cursor.moveToNext() && examined < MAX_MESSAGES) {
                examined += 1
                val messageId = cursor.getLong(idIndex)
                val body = readTextParts(messageId)
                val sender = readSender(messageId)
                if (body.isBlank()) {
                    continue
                }
                val candidate = PaymentSmsParser.parse(
                    PaymentSmsParser.SmsContent(
                        messageId = "mms:$messageId",
                        sender = sender,
                        body = body,
                        receivedAt = normalizeDate(cursor.getLong(dateIndex)),
                        sourcePackage = PaymentSmsParser.MMS_SOURCE_PACKAGE,
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

    private fun readSender(messageId: Long): String {
        val uri = Uri.parse("content://mms/$messageId/addr")
        resolver.query(
            uri,
            arrayOf("address", "type"),
            "type = ?",
            arrayOf(MMS_FROM_ADDRESS_TYPE.toString()),
            null,
        )?.use { cursor ->
            val addressIndex = cursor.getColumnIndexOrThrow("address")
            if (cursor.moveToFirst()) {
                return cursor.getString(addressIndex).orEmpty()
            }
        }
        return ""
    }

    private fun readTextParts(messageId: Long): String {
        val parts = mutableListOf<String>()
        resolver.query(
            MMS_PARTS_URI,
            arrayOf("_id", "ct", "_data", "text"),
            "mid = ?",
            arrayOf(messageId.toString()),
            "seq ASC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow("_id")
            val contentTypeIndex = cursor.getColumnIndexOrThrow("ct")
            val dataIndex = cursor.getColumnIndexOrThrow("_data")
            val textIndex = cursor.getColumnIndexOrThrow("text")
            while (cursor.moveToNext()) {
                if (cursor.getString(contentTypeIndex) != TEXT_CONTENT_TYPE) {
                    continue
                }
                val text = if (cursor.isNull(dataIndex)) {
                    cursor.getString(textIndex).orEmpty()
                } else {
                    readPartStream(cursor.getLong(idIndex))
                }
                text.trim().takeIf(String::isNotBlank)?.let(parts::add)
            }
        }
        return parts.joinToString("\n")
    }

    private fun readPartStream(partId: Long): String = runCatching {
        resolver.openInputStream(Uri.parse("content://mms/part/$partId"))
            ?.bufferedReader(Charsets.UTF_8)
            ?.use { reader ->
                val buffer = CharArray(MAX_PART_CHARS)
                val count = reader.read(buffer)
                if (count > 0) String(buffer, 0, count) else ""
            }
            .orEmpty()
    }.getOrDefault("")

    private fun normalizeDate(value: Long): Long =
        if (value < MILLIS_THRESHOLD) value * 1000L else value

    companion object {
        private val MMS_PARTS_URI = Uri.parse("content://mms/part")
        private const val TEXT_CONTENT_TYPE = "text/plain"
        private const val MMS_FROM_ADDRESS_TYPE = 137
        private const val MAX_MESSAGES = 200
        private const val MAX_PART_CHARS = 64 * 1024
        private const val LOOKBACK_MS = 30L * 24 * 60 * 60 * 1000
        private const val MILLIS_THRESHOLD = 100_000_000_000L
    }
}
