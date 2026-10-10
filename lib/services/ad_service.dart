import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ads/ad_helper.dart';

/// خدمة مركزية لإدارة إعلانات AdMob بشكل متوافق مع سياسة Google.
///
/// القواعد المطبقة للحفاظ على توافق AdMob و Google Play:
/// - لا يتم عرض الإعلان البيني تلقائياً أو عند فتح التطبيق.
/// - يُعرض فقط عند نقاط توقف طبيعية يمر بها المستخدم (بعد حفظ/تنفيذ عملية).
/// - حد أدنى 60 ثانية بين كل إعلانين بينيين لمنع الإفراط الذي يخالف السياسة.
/// - يُعاد تحميل إعلان جديد تلقائياً بعد إغلاق الإعلان الحالي.
class AdService {
  static String get interstitialAdUnitId => AdHelper.interstitialUnitId;
  static String get bannerAdUnitId => AdHelper.bannerUnitId;

  static const Duration _minInterval = Duration(seconds: 60);
  static const String _lastShownKey = 'smart_book_last_interstitial_ms';

  static InterstitialAd? _interstitial;
  static bool _loading = false;

  /// تحميل إعلان بيني مسبقاً دون عرضه (يبدأ التحميل عند فتح الشاشات).
  static void loadInterstitial() {
    if (_loading || _interstitial != null) return;
    _loading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitial = null;
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              _interstitial = null;
              _loading = false;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _loading = false;
          _interstitial = null;
        },
      ),
    );
  }

  /// محاولة عرض الإعلان البيني عند نقطة توقف طبيعية.
  /// يحترم الحد الأدنى للوقت بين الإعلانات، ويرجع true إذا تم العرض فعلياً.
  static Future<bool> showInterstitialAtBreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_lastShownKey) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastShown;

    if (elapsed < _minInterval.inMilliseconds) return false;

    if (_interstitial == null) {
      loadInterstitial();
      return false;
    }

    await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    _interstitial!.show();
    _interstitial = null;
    return true;
  }
}