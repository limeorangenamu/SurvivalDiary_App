package com.survivaldiary.project_survival_diary

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class PaymentNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(statusBarNotification: StatusBarNotification?) {
        val item = statusBarNotification ?: return
        if (item.packageName == packageName) {
            return
        }

        val notification = item.notification ?: return
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) {
            return
        }

        val extras = notification.extras
        val candidate = PaymentNotificationParser.parse(
            PaymentNotificationParser.NotificationContent(
                packageName = item.packageName,
                notificationKey = item.key,
                title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
                text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
                bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString(),
                textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                    ?.map(CharSequence::toString)
                    .orEmpty(),
                postedAt = item.postTime,
            ),
        ) ?: return

        if (PaymentNotificationStore(this).add(candidate)) {
            PaymentNotificationEventBus.publish(candidate)
        }
    }
}
