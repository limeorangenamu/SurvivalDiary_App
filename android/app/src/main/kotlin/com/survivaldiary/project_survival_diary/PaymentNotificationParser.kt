package com.survivaldiary.project_survival_diary

import java.security.MessageDigest

object PaymentNotificationParser {
    data class NotificationContent(
        val packageName: String,
        val notificationKey: String,
        val title: String?,
        val text: String?,
        val bigText: String?,
        val textLines: List<String>,
        val postedAt: Long,
    )

    fun parse(content: NotificationContent): DetectedExpenseCandidate? {
        val lines = listOfNotNull(content.title, content.text, content.bigText) +
            content.textLines
        val isMessagingNotification = PaymentInstitutions.isMessagingPackage(content.packageName)
        val institution = PaymentInstitutions.fromPackage(content.packageName)
            ?: if (isMessagingNotification) {
                PaymentInstitutions.fromSms(
                    sender = content.title.orEmpty(),
                    body = lines.joinToString("\n"),
                ) ?: PaymentInstitutions.genericBankAccount()
                    .takeIf { PaymentTextParser.looksLikeBankAccountExpense(lines) }
            } else {
                null
            }
            ?: return null
        val parsed = PaymentTextParser.parse(
            lines = lines,
            sourceName = institution.name,
            sourceKey = institution.key,
        ) ?: return null

        return DetectedExpenseCandidate(
            id = eventId(content, parsed),
            merchant = parsed.merchant,
            amount = parsed.amount,
            detectedAt = content.postedAt,
            source = if (isMessagingNotification) {
                "${institution.name} 메시지 알림"
            } else {
                institution.name
            },
            sourcePackage = content.packageName,
            sourceKey = institution.key,
            detectionChannel = if (isMessagingNotification) "sms" else "notification",
            category = parsed.category,
            confidence = parsed.confidence,
        )
    }

    private fun eventId(
        content: NotificationContent,
        parsed: PaymentTextParser.ParsedPayment,
    ): String {
        val raw = "${content.packageName}|${content.notificationKey}|${content.postedAt}|" +
            "${parsed.amount}|${parsed.merchant}"
        val bytes = MessageDigest.getInstance("SHA-256")
            .digest(raw.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
