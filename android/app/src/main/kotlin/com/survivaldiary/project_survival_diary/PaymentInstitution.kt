package com.survivaldiary.project_survival_diary

data class PaymentInstitution(
    val key: String,
    val name: String,
    val smsMarkers: List<String>,
)

object PaymentInstitutions {
    private val institutions = listOf(
        PaymentInstitution("toss", "토스", listOf("토스", "toss")),
        PaymentInstitution("kakao-pay", "카카오페이", listOf("카카오페이")),
        PaymentInstitution("kakao-bank", "카카오뱅크", listOf("카카오뱅크")),
        PaymentInstitution("kbank", "케이뱅크", listOf("케이뱅크")),
        PaymentInstitution(
            "busan-bank",
            "BNK부산은행",
            listOf(
                "부산은행",
                "bnk부산은행",
                "bnk 부산은행",
                "1544-6200",
                "15446200",
            ),
        ),
        PaymentInstitution(
            "shinhan-card",
            "신한카드",
            listOf("신한카드", "신한 play", "신한play"),
        ),
        PaymentInstitution(
            "shinhan-bank",
            "신한은행",
            listOf("신한은행", "신한 sol뱅크", "신한sol뱅크"),
        ),
        PaymentInstitution(
            "kb-card",
            "KB국민카드",
            listOf("kb국민카드", "국민카드", "kb pay", "kbpay"),
        ),
        PaymentInstitution(
            "kb-bank",
            "KB국민은행",
            listOf("kb국민은행", "국민은행", "kb스타뱅킹"),
        ),
        PaymentInstitution(
            "nh-card",
            "NH농협카드",
            listOf("nh농협카드", "농협카드", "nh카드", "nh pay"),
        ),
        PaymentInstitution(
            "nh-bank",
            "NH농협은행",
            listOf("nh농협은행", "농협은행", "nh스마트뱅킹"),
        ),
        PaymentInstitution(
            "woori-card",
            "우리카드",
            listOf("우리카드", "우리won카드"),
        ),
        PaymentInstitution(
            "woori-bank",
            "우리은행",
            listOf("우리은행", "우리won뱅킹"),
        ),
        PaymentInstitution("hana-card", "하나카드", listOf("하나카드")),
        PaymentInstitution("hana-bank", "하나은행", listOf("하나은행", "하나원큐")),
        PaymentInstitution("samsung-card", "삼성카드", listOf("삼성카드")),
        PaymentInstitution("hyundai-card", "현대카드", listOf("현대카드")),
        PaymentInstitution(
            "lotte-card",
            "롯데카드",
            listOf("롯데카드", "디지로카"),
        ),
        PaymentInstitution(
            "bc-card",
            "BC카드",
            listOf("bc카드", "비씨카드", "페이북"),
        ),
        PaymentInstitution("ibk-bank", "IBK기업은행", listOf("ibk기업은행", "기업은행")),
        PaymentInstitution("sc-bank", "SC제일은행", listOf("sc제일은행")),
        PaymentInstitution("city-card", "씨티카드", listOf("씨티카드")),
        PaymentInstitution("post-bank", "우체국", listOf("우체국카드", "우체국예금")),
    )

    private val byKey = institutions.associateBy(PaymentInstitution::key)

    private val packageKeys = mapOf(
        "viva.republica.toss" to "toss",
        "com.kakaopay.app" to "kakao-pay",
        "com.kakaobank.channel" to "kakao-bank",
        "com.kbankwith.smartbank" to "kbank",
        "com.shinhan.sbanking" to "shinhan-bank",
        "com.shcard.smartpay" to "shinhan-card",
        "com.kbstar.kbbank" to "kb-bank",
        "com.kbcard.cxh.appcard" to "kb-card",
        "nh.smart.banking" to "nh-bank",
        "nh.smart.card" to "nh-card",
        "com.wooribank.smart.npib" to "woori-bank",
        "com.wooricard.smartapp" to "woori-card",
        "com.hanabank.ebk.channel.android.hananbank" to "hana-bank",
        "kr.co.samsungcard.mpocket" to "samsung-card",
        "com.hyundaicard.appcard" to "hyundai-card",
        "com.lcacApp" to "lotte-card",
        "com.bccard.bcapp" to "bc-card",
    )

    private val messagingPackages = setOf(
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
        "com.android.messaging",
        "com.android.mms",
    )

    fun fromPackage(packageName: String): PaymentInstitution? =
        packageKeys[packageName]?.let(byKey::get)

    fun isMessagingPackage(packageName: String): Boolean =
        packageName in messagingPackages

    fun fromSms(sender: String, body: String): PaymentInstitution? {
        val sourceBody = body.lines()
            .map(String::trim)
            .filterNot { line ->
                listOf("메모", "적요", "내용", "거래내용", "받는 분", "받는분", "거래처")
                    .any { label -> line == label || line.startsWith("$label ") }
            }
            .joinToString(" ")
        val haystack = "$sender $sourceBody".lowercase()
        return institutions.firstOrNull { institution ->
            institution.smsMarkers.any { marker -> haystack.contains(marker.lowercase()) }
        }
    }

    fun genericBankAccount(): PaymentInstitution = PaymentInstitution(
        key = "bank-account",
        name = "은행 계좌",
        smsMarkers = emptyList(),
    )

    fun sourceKeyFor(packageName: String, sourceName: String): String =
        fromPackage(packageName)?.key
            ?: institutions.firstOrNull { it.name == sourceName.removeSuffix(" 문자") }?.key
            ?: packageName
}
