package com.survivaldiary.project_survival_diary

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.abs

object DetectedExpenseAlertNotifier {
    fun notifyIfRecent(context: Context, candidate: DetectedExpenseCandidate) {
        if (abs(System.currentTimeMillis() - candidate.detectedAt) > MAX_ALERT_AGE_MS) {
            return
        }
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val notificationManager = context.getSystemService(NotificationManager::class.java)
        createChannel(notificationManager)

        val amount = NumberFormat.getNumberInstance(Locale.KOREA).format(candidate.amount)
        val expenseSummary = "${candidate.merchant} · ${amount}원"
        val detail = "$expenseSummary\n${candidate.source}에서 감지했어요."
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                context,
                candidate.id.hashCode(),
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
            .setSmallIcon(R.drawable.ic_expense_notification)
            .setContentTitle("새로운 지출 내역이 확인되었어요!")
            .setContentText(expenseSummary)
            .setStyle(Notification.BigTextStyle().bigText(detail))
            .setWhen(candidate.detectedAt)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setCategory(Notification.CATEGORY_STATUS)

        if (contentIntent != null) {
            builder.setContentIntent(contentIntent)
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
        }

        runCatching {
            notificationManager.notify(candidate.id.hashCode(), builder.build())
        }
    }

    private fun createChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            "지출 자동 감지",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "새로 감지된 지출 내역을 알려드려요."
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        notificationManager.createNotificationChannel(channel)
    }

    private const val CHANNEL_ID = "detected_expense_alerts"
    private const val MAX_ALERT_AGE_MS = 5 * 60 * 1000L
}
