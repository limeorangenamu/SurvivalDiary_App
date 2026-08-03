package com.survivaldiary.project_survival_diary

object PaymentTextParser {
    private enum class KakaoPayTransferDirection {
        OUTGOING_CONFIRMED,
        INCOMING,
    }

    data class ParsedPayment(
        val merchant: String,
        val amount: Int,
        val category: String,
        val confidence: Double,
    )

    private val paymentKeywords = listOf(
        "결제",
        "승인",
        "카드사용",
        "카드 사용",
        "체크카드",
        "신용카드",
    )
    private val bankAccountExpenseKeywords = listOf(
        "출금",
        "이체",
        "송금",
    )
    private val bankAccountMarkers = listOf(
        "계좌",
        "잔액",
        "메모",
        "적요",
        "거래내용",
        "내용",
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
        "출금취소",
        "출금 취소",
        "이체취소",
        "이체 취소",
        "송금취소",
        "송금 취소",
        "출금실패",
        "출금 실패",
        "이체실패",
        "이체 실패",
        "송금실패",
        "송금 실패",
        "입금",
        "송금 받",
        "받았어요",
        "받았습니다",
        "인증번호",
        "본인인증",
        "광고",
    )
    private val kakaoPayOutgoingConfirmationKeywords = listOf(
        "원을 받았어요",
        "원을 받았습니다",
    )
    private val kakaoPayIncomingKeywords = listOf(
        "원을 보냈어요",
        "원을 보냈습니다",
    )
    private val amountRegex = Regex("""(?<!\d)(\d{1,3}(?:,\d{3})+|\d+)\s*원""")
    private val plainAmountRegex = Regex("""^(\d{1,3}(?:,\d{3})*|\d+)\s*(?:원)?$""")
    private val datedBankAmountRegex = Regex(
        """\b\d{1,2}[/.-]\d{1,2}(?:[/.-]\d{1,2})?\s+\d{1,2}:\d{2}\s+""" +
            """(\d{1,3}(?:,\d{3})*|\d+)\s*(?:원)?(?=\s|$)""",
    )
    private val dateRegex = Regex(
        """\b\d{1,2}[/.-]\d{1,2}(?:[/.-]\d{1,2})?(?:\s+\d{1,2}:\d{2})?\b""",
    )
    private val phoneRegex = Regex("""^\+?[\d()\-\s]{7,}$""")
    private val maskedNameRegex = Regex("""^[가-힣A-Za-z]{0,3}\*+[가-힣A-Za-z]{0,3}$""")

    fun parse(
        lines: List<String>,
        sourceName: String,
        sourceKey: String? = null,
    ): ParsedPayment? {
        val normalizedLines = lines
            .flatMap { it.lines() }
            .map(::normalize)
            .filter(String::isNotBlank)
            .distinct()
        val combined = normalizedLines.joinToString(" ")
        val kakaoPayTransferDirection = if (sourceKey == KAKAO_PAY_SOURCE_KEY) {
            findKakaoPayTransferDirection(normalizedLines)
        } else {
            null
        }
        if (kakaoPayTransferDirection == KakaoPayTransferDirection.INCOMING) {
            return null
        }
        val kakaoPayOutgoingConfirmed =
            kakaoPayTransferDirection == KakaoPayTransferDirection.OUTGOING_CONFIRMED
        val bankAccountExpense =
            bankAccountExpenseKeywords.any(combined::contains) || kakaoPayOutgoingConfirmed

        if (
            combined.isBlank() ||
            (paymentKeywords.none(combined::contains) && !bankAccountExpense)
        ) {
            return null
        }
        val accountAmount = if (bankAccountExpense) {
            findBankAccountAmount(normalizedLines)
        } else {
            null
        }
        val accountMarkerCount = if (bankAccountExpense) {
            bankAccountMarkers.count(combined::contains)
        } else {
            0
        }
        val strongBankAccountExpense = accountAmount != null && accountMarkerCount >= 2
        val ignoredKeyword = ignoredKeywords.firstOrNull { keyword ->
            combined.contains(keyword) &&
                !(keyword == "광고" && strongBankAccountExpense) &&
                !(
                    kakaoPayOutgoingConfirmed &&
                        keyword in kakaoPayOutgoingAllowedIgnoredKeywords
                    )
        }
        if (ignoredKeyword != null) {
            return null
        }

        val amountMatch = if (accountAmount == null) amountRegex.find(combined) else null
        val amountText = amountMatch?.value ?: accountAmount?.second ?: return null
        val amount = (amountMatch?.groupValues?.get(1) ?: accountAmount?.first)
            ?.replace(",", "")
            ?.toIntOrNull()
            ?: return null
        if (amount <= 0) {
            return null
        }

        val merchant = if (bankAccountExpense) {
            findBankAccountMerchant(normalizedLines)
        } else {
            findMerchant(
                lines = normalizedLines,
                combined = combined,
                amountText = amountText,
                sourceName = sourceName,
            )
        }
        val accountAction = bankAccountExpenseKeywords.firstOrNull(combined::contains)
            ?: "송금".takeIf { kakaoPayOutgoingConfirmed }
        val resolvedMerchant = merchant
            ?: "$sourceName ${accountAction ?: "결제"}"

        return ParsedPayment(
            merchant = resolvedMerchant,
            amount = amount,
            category = if (bankAccountExpense) "etc" else inferCategory(resolvedMerchant),
            confidence = if (merchant == null) 0.65 else 0.9,
        )
    }

    fun looksLikeBankAccountExpense(lines: List<String>): Boolean {
        val normalized = lines.map(::normalize).filter(String::isNotBlank)
        val combined = normalized.joinToString(" ")
        val accountAction = bankAccountExpenseKeywords.firstOrNull(combined::contains)
        if (accountAction == null) {
            return false
        }
        val accountMarkers = bankAccountMarkers.filter(combined::contains)
        val accountAmount = findBankAccountAmount(normalized)
        val strongBankAccountExpense = accountMarkers.size >= 2 && accountAmount != null
        val ignoredKeyword = ignoredKeywords.firstOrNull { keyword ->
            combined.contains(keyword) &&
                !(keyword == "광고" && strongBankAccountExpense)
        }
        if (ignoredKeyword != null) {
            return false
        }
        return accountMarkers.size >= 2 && accountAmount != null
    }

    fun containsBankAccountExpenseKeyword(value: String): Boolean =
        bankAccountExpenseKeywords.any(value::contains)

    private fun findKakaoPayTransferDirection(
        lines: List<String>,
    ): KakaoPayTransferDirection? = lines.firstNotNullOfOrNull { line ->
        when {
            kakaoPayOutgoingConfirmationKeywords.any(line::contains) ->
                KakaoPayTransferDirection.OUTGOING_CONFIRMED
            kakaoPayIncomingKeywords.any(line::contains) ->
                KakaoPayTransferDirection.INCOMING
            else -> null
        }
    }

    private fun findBankAccountAmount(lines: List<String>): Pair<String, String>? {
        val actionLineIndex = lines.indexOfFirst { line ->
            bankAccountExpenseKeywords.any(line::contains)
        }
        if (actionLineIndex < 0) {
            return null
        }

        datedBankAmountRegex.find(lines.joinToString(" "))?.let { match ->
            return match.groupValues[1] to match.groupValues[1]
        }

        return lines.drop(actionLineIndex).take(3).firstNotNullOfOrNull { line ->
            val action = bankAccountExpenseKeywords.firstOrNull(line::contains)
            val afterAction = action?.let { line.substringAfter(it).trim() }.orEmpty()
            plainAmountRegex.matchEntire(afterAction)?.let { match ->
                match.groupValues[1] to match.value
            } ?: dateRegex.find(line)?.let { date ->
                val afterDate = line.substring(date.range.last + 1).trim()
                plainAmountRegex.matchEntire(afterDate)?.let { match ->
                    match.groupValues[1] to match.value
                }
            } ?: plainAmountRegex.matchEntire(line)?.let { match ->
                match.groupValues[1] to match.value
            }
        }
    }

    private fun findBankAccountMerchant(lines: List<String>): String? {
        val labels = listOf("메모", "적요", "거래내용", "받는 분", "받는분", "거래처")
        for ((index, line) in lines.withIndex()) {
            val label = labels.firstOrNull { line == it || line.startsWith("$it ") }
                ?: continue
            val inlineValue = line.removePrefix(label).trim(' ', ':', '-', '|')
            if (inlineValue.length >= 2) {
                return inlineValue.take(40)
            }
            val nextLine = lines.getOrNull(index + 1).orEmpty()
            if (nextLine.length >= 2 && labels.none(nextLine::startsWith)) {
                return nextLine.take(40)
            }
        }
        return null
    }

    private fun findMerchant(
        lines: List<String>,
        combined: String,
        amountText: String,
        sourceName: String,
    ): String? {
        val afterDate = Regex(
            """\d{1,2}[/.-]\d{1,2}(?:[/.-]\d{1,2})?\s+\d{1,2}:\d{2}\s+""" +
                """([가-힣A-Za-z0-9][가-힣A-Za-z0-9 .&()_\-]{1,40})""",
        ).find(combined)?.groupValues?.get(1)
        cleanMerchant(afterDate.orEmpty())
            .takeIf { isMerchantLine(it, sourceName) }
            ?.let { return it }

        val amountLineIndex = lines.indexOfFirst { it.contains(amountText) }
        if (amountLineIndex >= 0) {
            val nearbyLines = lines.drop(amountLineIndex + 1) +
                lines.take(amountLineIndex).asReversed()
            nearbyLines.firstOrNull { isMerchantLine(it, sourceName) }
                ?.let(::cleanMerchant)
                ?.let { return it }
        }

        val escapedAmount = Regex.escape(amountText)
        Regex(
            """$escapedAmount\s*(?:승인|결제|사용|일시불|할부)?\s*""" +
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
        if (line.length !in 2..40 || line.equals(sourceName, ignoreCase = true)) {
            return false
        }
        if (
            amountRegex.containsMatchIn(line) || dateRegex.containsMatchIn(line) ||
            phoneRegex.matches(line) || maskedNameRegex.matches(line) || line.contains('*')
        ) {
            return false
        }
        val lower = line.lowercase()
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
            "web발신",
            "무료수신거부",
        )
        return metadataWords.none { lower == it || lower.startsWith("$it ") }
    }

    private fun cleanMerchant(value: String): String = normalize(value)
        .replace(Regex("""^\[?(?:web발신|국외발신)\]?\s*""", RegexOption.IGNORE_CASE), "")
        .replace(Regex("""^(?:승인|결제|사용)\s*"""), "")
        .replace(Regex("""\s+(?:잔액|누적|일시불|할부|승인번호).*$"""), "")
        .trim(' ', '-', '·', '|', ':', '[', ']')
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

    fun normalize(value: String): String = value
        .replace('\n', ' ')
        .replace(Regex("""\s+"""), " ")
        .trim()

    private const val KAKAO_PAY_SOURCE_KEY = "kakao-pay"
    private val kakaoPayOutgoingAllowedIgnoredKeywords = setOf(
        "송금 받",
        "받았어요",
        "받았습니다",
    )
}
