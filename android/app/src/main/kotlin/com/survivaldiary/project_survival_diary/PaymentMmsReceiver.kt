package com.survivaldiary.project_survival_diary

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.provider.Telephony
import java.util.concurrent.Executors

class PaymentMmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.WAP_PUSH_RECEIVED_ACTION) {
            return
        }
        val pendingResult = goAsync()
        val executor = Executors.newSingleThreadExecutor()
        executor.execute {
            try {
                SystemClock.sleep(PROVIDER_WRITE_DELAY_MS)
                PaymentMmsInboxReader(context).scanRecent()
                    .forEach(PaymentNotificationEventBus::publish)
            } catch (_: Throwable) {
            } finally {
                pendingResult.finish()
                executor.shutdown()
            }
        }
    }

    companion object {
        private const val PROVIDER_WRITE_DELAY_MS = 1_500L
    }
}
