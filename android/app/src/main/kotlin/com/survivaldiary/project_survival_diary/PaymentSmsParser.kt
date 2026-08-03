package com.survivaldiary.project_survival_diary

import java.security.MessageDigest

object PaymentSmsParser {
    data class SmsContent(
        val messageId: String,
        val sender: String,
        val body: String,
        val receivedAt: Long,
        val sourcePackage: String = SMS_SOURCE_PACKAGE,
    )

    fun parse(content: SmsContent): DetectedExpenseCandidate? {
        val institution = PaymentInstitutions.fromSms(content.sender, content.body)
            ?: PaymentInstitutions.genericBankAccount()
                .takeIf { PaymentTextParser.looksLikeBankAccountExpense(content.body.lines()) }
            ?: return null
        val parsed = PaymentTextParser.parse(
            lines = content.body.lines(),
            sourceName = institution.name,
        ) ?: return null

        return DetectedExpenseCandidate(
            id = eventId(content, parsed),
            merchant = parsed.merchant,
            amount = parsed.amount,
            detectedAt = content.receivedAt,
            source = "${institution.name} 문자",
            sourcePackage = content.sourcePackage,
            sourceKey = institution.key,
            detectionChannel = "sms",
            category = parsed.category,
            confidence = parsed.confidence,
        )
    }

    private fun eventId(
        content: SmsContent,
        parsed: PaymentTextParser.ParsedPayment,
    ): String {
        val raw = "${content.sourcePackage}|${content.messageId}|${content.sender}|" +
            "${content.receivedAt}|" +
            "${parsed.amount}|${parsed.merchant}"
        val bytes = MessageDigest.getInstance("SHA-256")
            .digest(raw.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }

    const val SMS_SOURCE_PACKAGE = "android.provider.Telephony.Sms"
    const val MMS_SOURCE_PACKAGE = "android.provider.Telephony.Mms"
}
