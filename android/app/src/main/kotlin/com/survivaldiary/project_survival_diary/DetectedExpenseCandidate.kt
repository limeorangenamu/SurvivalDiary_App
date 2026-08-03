package com.survivaldiary.project_survival_diary

import org.json.JSONObject

data class DetectedExpenseCandidate(
    val id: String,
    val merchant: String,
    val amount: Int,
    val detectedAt: Long,
    val source: String,
    val sourcePackage: String,
    val sourceKey: String,
    val detectionChannel: String,
    val category: String,
    val confidence: Double,
) {
    fun toMap(): Map<String, Any> = mapOf(
        "id" to id,
        "merchant" to merchant,
        "amount" to amount,
        "detectedAt" to detectedAt,
        "source" to source,
        "sourcePackage" to sourcePackage,
        "sourceKey" to sourceKey,
        "detectionChannel" to detectionChannel,
        "category" to category,
        "confidence" to confidence,
    )

    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("merchant", merchant)
        put("amount", amount)
        put("detectedAt", detectedAt)
        put("source", source)
        put("sourcePackage", sourcePackage)
        put("sourceKey", sourceKey)
        put("detectionChannel", detectionChannel)
        put("category", category)
        put("confidence", confidence)
    }

    companion object {
        fun fromJson(json: JSONObject): DetectedExpenseCandidate =
            DetectedExpenseCandidate(
                id = json.getString("id"),
                merchant = json.getString("merchant"),
                amount = json.getInt("amount"),
                detectedAt = json.getLong("detectedAt"),
                source = json.getString("source"),
                sourcePackage = json.getString("sourcePackage"),
                sourceKey = json.optString("sourceKey").ifBlank {
                    PaymentInstitutions.sourceKeyFor(
                        json.getString("sourcePackage"),
                        json.getString("source"),
                    )
                },
                detectionChannel = json.optString("detectionChannel", "notification"),
                category = json.optString("category", "etc"),
                confidence = json.optDouble("confidence", 0.7),
            )
    }
}
