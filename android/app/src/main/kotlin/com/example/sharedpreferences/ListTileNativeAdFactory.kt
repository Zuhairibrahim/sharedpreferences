package com.zuhair.sharedpreferencess.apps

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

/**
 * مصنع إعلانات Native المدمجة داخل قوائم التطبيق (factoryId: listTile).
 * يبني عرضاً مضغوطاً يشبه عناصر القائمة بستايل التطبيق الداكن.
 */
class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_list_tile, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val appIconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val badgeView = adView.findViewById<TextView>(R.id.ad_ad_badge)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)

        nativeAd.headline?.let { headlineView.text = it }
        adView.headlineView = headlineView

        if (nativeAd.body.isNullOrEmpty()) {
            bodyView.visibility = View.INVISIBLE
        } else {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
        }
        adView.bodyView = bodyView

        if (nativeAd.icon == null) {
            appIconView.visibility = View.GONE
        } else {
            appIconView.setImageDrawable(nativeAd.icon?.drawable)
            appIconView.visibility = View.VISIBLE
        }
        adView.iconView = appIconView

        badgeView.text = nativeAd.adChoicesInfo?.let { "إعلان" } ?: "إعلان"

        if (nativeAd.callToAction.isNullOrEmpty()) {
            ctaView.visibility = View.GONE
        } else {
            ctaView.text = nativeAd.callToAction
            ctaView.visibility = View.VISIBLE
        }
        adView.callToActionView = ctaView

        val mediaView = MediaView(context)
        adView.mediaView = mediaView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
