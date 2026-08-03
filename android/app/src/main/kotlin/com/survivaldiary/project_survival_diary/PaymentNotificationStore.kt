package com.survivaldiary.project_survival_diary

import android.content.Context
import kotlin.math.abs
import kotlin.math.max
import org.json.JSONArray
import org.json.JSONObject

class PaymentNotificationStore(context: Context) {
    private val appContext = context.applicationContext
    private val preferences = appContext.getSharedPreferences(
        PREFERENCES_NAME,
        Context.MODE_PRIVATE,
    )

    fun getAll(): List<DetectedExpenseCandidate> = synchronized(lock) {
        readAll().sortedByDescending { it.detectedAt }
    }

    /**
     * 새 후보가 추가되거나 기존 후보가 더 정확한 정보로 합쳐지면 저장된 후보를 반환한다.
     * 같은 알림·문자 또는 최근 처리한 동일 결제라면 null을 반환한다.
     */
    fun add(candidate: DetectedExpenseCandidate): DetectedExpenseCandidate? = synchronized(lock) {
        val current = readAll().toMutableList()
        val recentSeen = readSeen().filter(::isRecent)
        val existingIndex = current.indexOfFirst {
            PaymentTransactionMatcher.isSame(it, candidate)
        }

        if (existingIndex >= 0) {
            val existing = current[existingIndex]
            val merged = merge(existing, candidate)
            val updatedSeen = remember(recentSeen, candidate)
            if (merged != existing) {
                current[existingIndex] = merged
                writeAll(current)
                writeSeen(updatedSeen)
                return@synchronized merged
            }
            if (updatedSeen != recentSeen) {
                writeSeen(updatedSeen)
            }
            return@synchronized null
        }

        if (recentSeen.any { it.matches(candidate) }) {
            return@synchronized null
        }

        current.add(candidate)
        writeAll(current.sortedByDescending { it.detectedAt }.take(MAX_ITEMS))
        writeSeen(remember(recentSeen, candidate))
        DetectedExpenseAlertNotifier.notifyIfRecent(appContext, candidate)
        candidate
    }

    fun update(id: String, merchant: String, amount: Int, category: String): Boolean =
        synchronized(lock) {
            val current = readAll().toMutableList()
            val index = current.indexOfFirst { it.id == id }
            if (index < 0) {
                return@synchronized false
            }
            current[index] = current[index].copy(
                merchant = merchant,
                amount = amount,
                category = category,
                confidence = 1.0,
            )
            writeAll(current)
            true
        }

    fun remove(id: String): Boolean = synchronized(lock) {
        val current = readAll()
        val updated = current.filterNot { it.id == id }
        if (updated.size == current.size) {
            return@synchronized false
        }
        writeAll(updated)
        true
    }

    private fun merge(
        existing: DetectedExpenseCandidate,
        candidate: DetectedExpenseCandidate,
    ): DetectedExpenseCandidate {
        val existingIsGeneric = PaymentTransactionMatcher.merchantKey(existing.merchant).isBlank()
        val candidateIsGeneric = PaymentTransactionMatcher.merchantKey(candidate.merchant).isBlank()
        val candidateIsBetter =
            (existingIsGeneric && !candidateIsGeneric) ||
                candidate.confidence > existing.confidence ||
                (
                    candidate.confidence == existing.confidence &&
                        existing.detectionChannel == "sms" &&
                        candidate.detectionChannel == "notification"
                    )
        val preferred = if (candidateIsBetter) candidate else existing
        val channel = if (existing.detectionChannel == candidate.detectionChannel) {
            existing.detectionChannel
        } else {
            "combined"
        }

        return existing.copy(
            merchant = preferred.merchant,
            detectedAt = minOf(existing.detectedAt, candidate.detectedAt),
            source = preferred.source,
            sourcePackage = preferred.sourcePackage,
            sourceKey = preferred.sourceKey.ifBlank { existing.sourceKey },
            detectionChannel = channel,
            category = preferred.category,
            confidence = max(existing.confidence, candidate.confidence),
        )
    }

    private fun remember(
        current: List<SeenTransaction>,
        candidate: DetectedExpenseCandidate,
    ): List<SeenTransaction> {
        if (current.any { it.matches(candidate) }) {
            return current
        }
        return (current + SeenTransaction.from(candidate))
            .sortedByDescending(SeenTransaction::detectedAt)
            .take(MAX_SEEN_ITEMS)
    }

    private fun isRecent(item: SeenTransaction): Boolean =
        System.currentTimeMillis() - item.detectedAt <= SEEN_RETENTION_MS

    private fun readAll(): List<DetectedExpenseCandidate> {
        val raw = preferences.getString(KEY_ITEMS, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    add(DetectedExpenseCandidate.fromJson(array.getJSONObject(index)))
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun readSeen(): List<SeenTransaction> {
        val raw = preferences.getString(KEY_SEEN, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    add(SeenTransaction.fromJson(array.getJSONObject(index)))
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun writeAll(items: List<DetectedExpenseCandidate>) {
        val array = JSONArray()
        items.forEach { array.put(it.toJson()) }
        preferences.edit().putString(KEY_ITEMS, array.toString()).apply()
    }

    private fun writeSeen(items: List<SeenTransaction>) {
        val array = JSONArray()
        items.forEach { array.put(it.toJson()) }
        preferences.edit().putString(KEY_SEEN, array.toString()).apply()
    }

    private data class SeenTransaction(
        val sourceKey: String,
        val amount: Int,
        val detectedAt: Long,
        val merchantKey: String,
    ) {
        fun matches(candidate: DetectedExpenseCandidate): Boolean {
            if (
                amount != candidate.amount ||
                abs(detectedAt - candidate.detectedAt) >
                PaymentTransactionMatcher.DEDUPE_WINDOW_MS
            ) {
                return false
            }
            val candidateMerchant = PaymentTransactionMatcher.merchantKey(candidate.merchant)
            return merchantKey.isNotBlank() && merchantKey == candidateMerchant
        }

        fun toJson(): JSONObject = JSONObject().apply {
            put("sourceKey", sourceKey)
            put("amount", amount)
            put("detectedAt", detectedAt)
            put("merchantKey", merchantKey)
        }

        companion object {
            fun from(candidate: DetectedExpenseCandidate): SeenTransaction = SeenTransaction(
                sourceKey = candidate.sourceKey,
                amount = candidate.amount,
                detectedAt = candidate.detectedAt,
                merchantKey = PaymentTransactionMatcher.merchantKey(candidate.merchant),
            )

            fun fromJson(json: JSONObject): SeenTransaction = SeenTransaction(
                sourceKey = json.optString("sourceKey"),
                amount = json.getInt("amount"),
                detectedAt = json.getLong("detectedAt"),
                merchantKey = json.optString("merchantKey"),
            )
        }
    }

    companion object {
        private const val PREFERENCES_NAME = "detected_expense_candidates"
        private const val KEY_ITEMS = "items"
        private const val KEY_SEEN = "seen_transactions"
        private const val MAX_ITEMS = 100
        private const val MAX_SEEN_ITEMS = 500
        private const val SEEN_RETENTION_MS = 35L * 24 * 60 * 60 * 1000
        private val lock = Any()
    }
}
