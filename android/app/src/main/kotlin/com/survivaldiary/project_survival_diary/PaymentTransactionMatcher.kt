package com.survivaldiary.project_survival_diary

import kotlin.math.abs

object PaymentTransactionMatcher {
    const val DEDUPE_WINDOW_MS = 10 * 1000L

    fun isSame(
        first: DetectedExpenseCandidate,
        second: DetectedExpenseCandidate,
    ): Boolean {
        if (first.id == second.id) {
            return true
        }
        if (
            first.amount != second.amount ||
            abs(first.detectedAt - second.detectedAt) > DEDUPE_WINDOW_MS
        ) {
            return false
        }
        val firstMerchant = merchantKey(first.merchant)
        return firstMerchant.isNotBlank() && firstMerchant == merchantKey(second.merchant)
    }

    fun merchantKey(value: String): String {
        val normalized = value.lowercase()
            .replace("결제", "")
            .replace("승인", "")
            .replace("문자", "")
            .replace(Regex("""[^가-힣a-z0-9]"""), "")
        return normalized.takeIf { it.length >= 2 } ?: ""
    }
}
