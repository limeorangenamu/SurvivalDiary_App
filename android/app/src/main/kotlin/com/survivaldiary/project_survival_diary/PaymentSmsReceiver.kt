package com.survivaldiary.project_survival_diary

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class PaymentSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }
        runCatching { detectExpense(context, intent) }
    }

    private fun detectExpense(context: Context, intent: Intent) {
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) {
            return
        }
        val sender = messages.first().displayOriginatingAddress.orEmpty()
        val body = messages.joinToString(separator = "") { it.displayMessageBody.orEmpty() }
        val receivedAt = messages.maxOf { it.timestampMillis }
        val candidate = PaymentSmsParser.parse(
            PaymentSmsParser.SmsContent(
                messageId = "broadcast:$sender:$receivedAt:${body.hashCode()}",
                sender = sender,
                body = body,
                receivedAt = receivedAt,
            ),
        )
        if (candidate == null) {
            return
        }

        PaymentNotificationStore(context).add(candidate)
            ?.let(PaymentNotificationEventBus::publish)
    }
}
