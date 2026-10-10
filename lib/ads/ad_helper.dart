import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // ✅ IDs الوحدات الجديدة (AdMob App الجديد)
  static const String _androidAppId =
      'ca-app-pub-1396394529471927~6755202884';

  static const String _androidBannerId =
      'ca-app-pub-1396394529471927/1104224254';

  static const String _androidInterstitialId =
      'ca-app-pub-1396394529471927/7632130272';

  static const String _androidRewardedId =
      'ca-app-pub-1396394529471927/7109386095';

  static const String _androidRewardedInterstitialId =
      'ca-app-pub-1396394529471927/5900246207';

  static const String _androidNativeId =
      'ca-app-pub-1396394529471927/3692885263';

  static const String _androidAppOpenId =
      'ca-app-pub-1396394529471927/8753640251';

  // ✅ IDs تجريبية من Google (Debug)
  static const String _testBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _testAppOpenId =
      'ca-app-pub-3940256099942544/9257395921';

  static const String _testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _testRewardedInterstitialId =
      'ca-app-pub-3940256099942544/5354046614';

  static const String _testNativeId =
      'ca-app-pub-3940256099942544/2247696110';

  /// ✅ للتشخيص: خليها true إذا تبي "تجبر" الإعلانات التجريبية حتى في Release
  static const bool forceTestAds = false;

  /// هل الوحدة الإعلانية placeholder لم تُستبدل بـ ID حقيقي بعد؟
  static bool _isPlaceholder(String id) => id.startsWith('PLACEHOLDER-');

  static bool get rewardedEnabled =>
      kDebugMode || forceTestAds || !_isPlaceholder(_androidRewardedId);

  static bool get rewardedInterstitialEnabled =>
      kDebugMode ||
      forceTestAds ||
      !_isPlaceholder(_androidRewardedInterstitialId);

  static bool get nativeEnabled =>
      kDebugMode || forceTestAds || !_isPlaceholder(_androidNativeId);

  /// App ID (موجود بالـ AndroidManifest، هنا فقط للمرجع)
  static String get appId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _androidAppId;
  }

  static bool get _useTestAds => !kReleaseMode || forceTestAds;

  /// Banner Ad Unit ID
  static String get bannerUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds ? _testBannerId : _androidBannerId;
  }

  /// Interstitial Ad Unit ID
  static String get interstitialUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds ? _testInterstitialId : _androidInterstitialId;
  }

  /// Rewarded Ad Unit ID
  static String get rewardedUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds ? _testRewardedId : _androidRewardedId;
  }

  /// Rewarded Interstitial Ad Unit ID
  static String get rewardedInterstitialUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds
        ? _testRewardedInterstitialId
        : _androidRewardedInterstitialId;
  }

  /// Native Advanced Ad Unit ID
  static String get nativeUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds ? _testNativeId : _androidNativeId;
  }

  /// App Open Ad Unit ID
  static String get appOpenUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds ? _testAppOpenId : _androidAppOpenId;
  }
}
