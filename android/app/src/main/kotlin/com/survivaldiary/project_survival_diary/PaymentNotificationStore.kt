package com.survivaldiary.project_survival_diary

import android.content.Context
import org.json.JSONArray

class PaymentNotificationStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(
        PREFERENCES_NAME,
        Context.MODE_PRIVATE,
    )

    fun getAll(): List<DetectedExpenseCandidate> = synchronized(lock) {
        readAll().sortedByDescending { it.detectedAt }
    }

    fun add(candidate: DetectedExpenseCandidate): Boolean = synchronized(lock) {
        val current = readAll().toMutableList()
        val existingIndex = current.indexOfFirst { it.id == candidate.id }
        if (existingIndex >= 0) {
            if (current[existingIndex] != candidate) {
                current[existingIndex] = candidate
                writeAll(current)
            }
            return@synchronized false
        }

        current.add(candidate)
        writeAll(current.sortedByDescending { it.detectedAt }.take(MAX_ITEMS))
        true
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

    private fun writeAll(items: List<DetectedExpenseCandidate>) {
        val array = JSONArray()
        items.forEach { array.put(it.toJson()) }
        preferences.edit().putString(KEY_ITEMS, array.toString()).apply()
    }

    companion object {
        private const val PREFERENCES_NAME = "detected_expense_candidates"
        private const val KEY_ITEMS = "items"
        private const val MAX_ITEMS = 100
        private val lock = Any()
    }
}
