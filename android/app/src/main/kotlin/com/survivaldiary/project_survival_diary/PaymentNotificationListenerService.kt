package com.survivaldiary.project_survival_diary

import android.app.Notification
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.concurrent.Executors

class PaymentNotificationListenerService : NotificationListenerService() {
    private val mmsObserverHandler = Handler(Looper.getMainLooper())
    private val mmsExecutor = Executors.newSingleThreadExecutor()
    private var mmsObserverRegistered = false
    private val scanMmsRunnable = Runnable {
        if (mmsExecutor.isShutdown) {
            return@Runnable
        }
        mmsExecutor.execute {
            runCatching { PaymentMmsInboxReader(this).scanRecent() }
                .onSuccess { candidates ->
                    candidates.forEach(PaymentNotificationEventBus::publish)
                }
        }
    }
    private val mmsContentObserver = object : ContentObserver(mmsObserverHandler) {
        override fun onChange(selfChange: Boolean, uri: Uri?) {
            mmsObserverHandler.removeCallbacks(scanMmsRunnable)
            mmsObserverHandler.postDelayed(scanMmsRunnable, MMS_SCAN_DEBOUNCE_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        runCatching {
            contentResolver.registerContentObserver(
                Telephony.Mms.CONTENT_URI,
                true,
                mmsContentObserver,
            )
            mmsObserverRegistered = true
        }
    }

    override fun onDestroy() {
        mmsObserverHandler.removeCallbacks(scanMmsRunnable)
        if (mmsObserverRegistered) {
            contentResolver.unregisterContentObserver(mmsContentObserver)
            mmsObserverRegistered = false
        }
        mmsExecutor.shutdownNow()
        super.onDestroy()
    }

    override fun onNotificationPosted(statusBarNotification: StatusBarNotification?) {
        val item = statusBarNotification ?: return
        runCatching { detectExpense(item) }
    }

    private fun detectExpense(item: StatusBarNotification) {
        if (item.packageName == packageName) {
            return
        }

        val notification = item.notification ?: return
        val extras = notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        val messagingText = extractLatestMessagingText(notification)
        val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.map(CharSequence::toString)
            .orEmpty()
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) {
            return
        }

        val candidate = PaymentNotificationParser.parse(
            PaymentNotificationParser.NotificationContent(
                packageName = item.packageName,
                notificationKey = item.key,
                title = title,
                messagingText = messagingText,
                text = text,
                bigText = bigText,
                textLines = textLines,
                postedAt = item.postTime,
            ),
        )
        if (candidate == null) {
            return
        }

        PaymentNotificationStore(this).add(candidate)
            ?.let(PaymentNotificationEventBus::publish)
    }

    @Suppress("DEPRECATION")
    private fun extractLatestMessagingText(notification: Notification): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return null
        }

        val messageBundles = notification.extras
            .getParcelableArray(Notification.EXTRA_MESSAGES)
            ?: return null
        return Notification.MessagingStyle.Message
            .getMessagesFromBundleArray(messageBundles)
            .asReversed()
            .firstNotNullOfOrNull { message ->
                message.text
                    ?.toString()
                    ?.trim()
                    ?.takeIf(String::isNotEmpty)
            }
    }

    companion object {
        private const val MMS_SCAN_DEBOUNCE_MS = 1_000L
    }
}
