package com.survivaldiary.project_survival_diary

import android.app.Activity
import android.location.Address
import android.location.Geocoder
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import kotlin.concurrent.thread

class LocationRegionChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val geocoder = Geocoder(activity, Locale.KOREA)

    fun register() {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "findRegion") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val latitude = call.argument<Number>("latitude")?.toDouble()
            val longitude = call.argument<Number>("longitude")?.toDouble()
            if (
                latitude == null || longitude == null ||
                latitude !in -90.0..90.0 || longitude !in -180.0..180.0
            ) {
                result.error("INVALID_ARGUMENT", "현재 위치 좌표가 올바르지 않습니다.", null)
                return@setMethodCallHandler
            }
            findRegion(latitude, longitude, result)
        }
    }

    private fun findRegion(
        latitude: Double,
        longitude: Double,
        result: MethodChannel.Result,
    ) {
        if (!Geocoder.isPresent()) {
            result.error("GEOCODER_UNAVAILABLE", "기기에서 현재 지역을 확인할 수 없습니다.", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            geocoder.getFromLocation(
                latitude,
                longitude,
                1,
                object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) {
                        activity.runOnUiThread { complete(addresses.firstOrNull(), result) }
                    }

                    override fun onError(errorMessage: String?) {
                        activity.runOnUiThread {
                            result.error(
                                "REGION_NOT_FOUND",
                                errorMessage ?: "현재 위치의 지역을 확인하지 못했습니다.",
                                null,
                            )
                        }
                    }
                },
            )
            return
        }

        thread {
            @Suppress("DEPRECATION")
            val address = runCatching {
                geocoder.getFromLocation(latitude, longitude, 1)?.firstOrNull()
            }.getOrNull()
            activity.runOnUiThread { complete(address, result) }
        }
    }

    private fun complete(address: Address?, result: MethodChannel.Result) {
        if (address == null) {
            result.error("REGION_NOT_FOUND", "현재 위치의 지역을 확인하지 못했습니다.", null)
            return
        }

        val province = address.adminArea.orEmpty().trim()
        val district = sequenceOf(
            address.subAdminArea,
            address.locality,
            address.subLocality,
        ).map { it.orEmpty().trim() }
            .firstOrNull { it.isNotEmpty() && it != province }
            .orEmpty()
        if (province.isEmpty()) {
            result.error("REGION_NOT_FOUND", "현재 위치의 시도를 확인하지 못했습니다.", null)
            return
        }

        result.success(
            mapOf(
                "province" to province,
                "district" to district,
            ),
        )
    }

    companion object {
        private const val CHANNEL_NAME =
            "com.survivaldiary.project_survival_diary/location_region"
    }
}
