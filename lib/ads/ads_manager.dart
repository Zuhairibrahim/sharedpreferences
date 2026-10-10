import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';

/// مدير موحّد لإعلانات Rewarded و Rewarded Interstitial.
/// يحمّل مسبقاً ويعيد التحميل تلقائياً بعد كل عرض، ويتجاهل
/// الوحدات ذات الـ placeholder في Release حتى لا تنكسر الإعلانات.
class AdsManager {
  AdsManager._();
  static final AdsManager instance = AdsManager._();

  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  bool _loadingRewarded = false;
  bool _loadingRewardedInterstitial = false;

  bool get hasRewardedAd => _rewardedAd != null;
  bool get hasRewardedInterstitialAd => _rewardedInterstitialAd != null;

  /// يُنادى مرة واحدة بعد MobileAds.initialize()
  void loadAll() {
    loadRewarded();
    loadRewardedInterstitial();
  }

  // ── Rewarded ────────────────────────────────────────────────────────

  void loadRewarded() {
    if (!AdHelper.rewardedEnabled || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdHelper.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// يعرض إعلان مكافأة. [onRewarded] يُنادى عند إكمال المشاهدة.
  /// [onDone] يُنادى دائماً بعد الإغلاق (نجاح أو فشل).
  void showRewarded({
    required VoidCallback onRewarded,
    VoidCallback? onDone,
  }) {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewarded();
      onDone?.call();
      return;
    }
    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewardedAd = null;
        if (rewarded) onRewarded();
        onDone?.call();
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewardedAd = null;
        onDone?.call();
        loadRewarded();
      },
    );
    ad.show(
      onUserEarnedReward: (_, _) => rewarded = true,
    );
    _rewardedAd = null;
  }

  // ── Rewarded Interstitial ───────────────────────────────────────────

  void loadRewardedInterstitial() {
    if (!AdHelper.rewardedInterstitialEnabled || _loadingRewardedInterstitial) {
      return;
    }
    _loadingRewardedInterstitial = true;
    RewardedInterstitialAd.load(
      adUnitId: AdHelper.rewardedInterstitialUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewardedInterstitial = false;
          _rewardedInterstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _loadingRewardedInterstitial = false;
          _rewardedInterstitialAd = null;
        },
      ),
    );
  }

  /// يعرض إعلان بيني بمكافأة عند نقاط انتقال طبيعية.
  void showRewardedInterstitial() {
    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      loadRewardedInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewardedInterstitialAd = null;
        loadRewardedInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewardedInterstitialAd = null;
        loadRewardedInterstitial();
      },
    );
    ad.show(onUserEarnedReward: (_, _) {});
    _rewardedInterstitialAd = null;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _rewardedAd = null;
    _rewardedInterstitialAd = null;
  }
}
