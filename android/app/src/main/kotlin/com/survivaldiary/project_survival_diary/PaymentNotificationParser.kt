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

    private data class PaymentSource(
        val name: String,
    )

    private val supportedSources = mapOf(
        "viva.republica.toss" to PaymentSource("토스"),
        "com.kakaopay.app" to PaymentSource("카카오페이"),
        "com.kakaobank.channel" to PaymentSource("카카오뱅크"),
        "com.kbankwith.smartbank" to PaymentSource("케이뱅크"),
        "com.shinhan.sbanking" to PaymentSource("신한 SOL뱅크"),
        "com.shcard.smartpay" to PaymentSource("신한 SOL페이"),
        "com.kbstar.kbbank" to PaymentSource("KB스타뱅킹"),
        "com.kbcard.cxh.appcard" to PaymentSource("KB Pay"),
        "nh.smart.banking" to PaymentSource("NH스마트뱅킹"),
        "nh.smart.card" to PaymentSource("NH pay"),
        "com.wooribank.smart.npib" to PaymentSource("우리WON뱅킹"),
        "com.wooricard.smartapp" to PaymentSource("우리WON카드"),
        "com.hanabank.ebk.channel.android.hananbank" to PaymentSource("하나원큐"),
        "kr.co.samsungcard.mpocket" to PaymentSource("삼성카드"),
        "com.hyundaicard.appcard" to PaymentSource("현대카드"),
        "com.lcacApp" to PaymentSource("디지로카"),
        "com.bccard.bcapp" to PaymentSource("페이북"),
    )

    private val paymentKeywords = listOf(
        "결제",
        "승인",
        "카드사용",
        "카드 사용",
        "체크카드",
        "신용카드",
    )
    private val ignoredKeywords = listOf(
        "승인취소",
        "승인 취소",
        "결제취소",
        "결제 취소",
        "취소 완료",
        "환불",
        "승인거절",
        "승인 거절",
        "결제실패",
        "결제 실패",
    )
    private val amountRegex = Regex("""(?<!\d)(\d{1,3}(?:,\d{3})+|\d+)\s*원""")
    private val dateRegex = Regex("""\b\d{1,2}[/.-]\d{1,2}(?:[/.-]\d{1,2}|\s+\d{1,2}:\d{2})?\b""")

    fun parse(content: NotificationContent): DetectedExpenseCandidate? {
        val source = supportedSources[content.packageName] ?: return null
        val lines = listOfNotNull(content.title, content.text, content.bigText)
            .plus(content.textLines)
            .map(::normalize)
            .filter(String::isNotBlank)
            .distinct()
        val combined = lines.joinToString(" ")

        if (combined.isBlank() || paymentKeywords.none(combined::contains)) {
            return null
        }
        if (ignoredKeywords.any(combined::contains)) {
            return null
        }

        val amountMatch = amountRegex.find(combined) ?: return null
        val amount = amountMatch.groupValues[1].replace(",", "").toIntOrNull()
            ?: return null
        if (amount <= 0) {
            return null
        }

        val merchant = findMerchant(
            lines = lines,
            combined = combined,
            amountText = amountMatch.value,
            sourceName = source.name,
        )
        val hasMerchant = merchant != null
        val resolvedMerchant = merchant ?: "${source.name} 결제"

        return DetectedExpenseCandidate(
            id = detectionId(
                packageName = content.packageName,
                notificationKey = content.notificationKey,
                postedAt = content.postedAt,
                amount = amount,
                merchant = resolvedMerchant,
            ),
            merchant = resolvedMerchant,
            amount = amount,
            detectedAt = content.postedAt,
            source = source.name,
            sourcePackage = content.packageName,
            category = inferCategory(resolvedMerchant),
            confidence = if (hasMerchant) 0.9 else 0.65,
        )
    }

    private fun findMerchant(
        lines: List<String>,
        combined: String,
        amountText: String,
        sourceName: String,
    ): String? {
        val amountLineIndex = lines.indexOfFirst { it.contains(amountText) }
        if (amountLineIndex >= 0) {
            val nearbyLines = lines.drop(amountLineIndex + 1) +
                lines.take(amountLineIndex).asReversed()
            nearbyLines.firstOrNull { isMerchantLine(it, sourceName) }
                ?.let { return cleanMerchant(it) }
        }

        val escapedAmount = Regex.escape(amountText)
        Regex(
            """$escapedAmount\s*(?:승인|결제|사용)?\s*""" +
                """([가-힣A-Za-z0-9][가-힣A-Za-z0-9 .&()_\-]{1,40}?)""" +
                """(?=\s+(?:잔액|누적|일시불|할부|승인번호|\d{1,2}[/.-]\d{1,2})|$)""",
        ).find(combined)?.groupValues?.get(1)?.let(::cleanMerchant)
            ?.takeIf { isMerchantLine(it, sourceName) }
            ?.let { return it }

        Regex(
            """([가-힣A-Za-z][가-힣A-Za-z0-9 .&()_\-]{1,40}?)\s+$escapedAmount""",
        ).find(combined)?.groupValues?.get(1)?.let(::cleanMerchant)
            ?.takeIf { isMerchantLine(it, sourceName) }
            ?.let { return it }

        return null
    }

    private fun isMerchantLine(value: String, sourceName: String): Boolean {
        val line = cleanMerchant(value)
        if (line.length !in 2..40 || line == sourceName || amountRegex.containsMatchIn(line)) {
            return false
        }
        if (dateRegex.containsMatchIn(line)) {
            return false
        }
        val metadataWords = listOf(
            "결제",
            "승인",
            "사용",
            "카드",
            "잔액",
            "누적",
            "일시불",
            "할부",
            "알림",
        )
        return metadataWords.none { line == it || line.startsWith("$it ") }
    }

    private fun cleanMerchant(value: String): String = normalize(value)
        .replace(Regex("""^(?:승인|결제|사용)\s*"""), "")
        .replace(Regex("""\s+(?:잔액|누적|일시불|할부|승인번호).*$"""), "")
        .trim(' ', '-', '·', '|', ':')
        .take(40)

    private fun inferCategory(merchant: String): String {
        val value = merchant.lowercase()
        return when {
            listOf("카페", "커피", "coffee", "스타벅스", "투썸", "메가커피", "컴포즈")
                .any(value::contains) -> "cafe"
            listOf("택시", "버스", "지하철", "교통", "철도", "코레일", "티머니", "주유", "주차")
                .any(value::contains) -> "transport"
            listOf("마트", "쇼핑", "백화점", "쿠팡", "다이소", "올리브영", "무신사")
                .any(value::contains) -> "shopping"
            listOf("식당", "푸드", "치킨", "피자", "버거", "김밥", "편의점", "cu", "gs25")
                .any(value::contains) -> "food"
            else -> "etc"
        }
    }

    private fun detectionId(
        packageName: String,
        notificationKey: String,
        postedAt: Long,
        amount: Int,
        merchant: String,
    ): String {
        val bytes = MessageDigest.getInstance("SHA-256")
            .digest(
                "$packageName|$notificationKey|$postedAt|$amount|$merchant"
                    .toByteArray(Charsets.UTF_8),
            )
        return bytes.joinToString("") { "%02x".format(it) }
    }

    private fun normalize(value: String): String = value
        .replace('\n', ' ')
        .replace(Regex("""\s+"""), " ")
        .trim()
}
