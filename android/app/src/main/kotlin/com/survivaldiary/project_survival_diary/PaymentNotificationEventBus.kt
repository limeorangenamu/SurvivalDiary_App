package com.survivaldiary.project_survival_diary

import android.os.Handler
import android.os.Looper

object PaymentNotificationEventBus {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var listener: ((Map<String, Any>) -> Unit)? = null

    fun setListener(value: ((Map<String, Any>) -> Unit)?) {
        listener = value
    }

    fun publish(candidate: DetectedExpenseCandidate) {
        mainHandler.post {
            listener?.invoke(candidate.toMap())
        }
    }
}
