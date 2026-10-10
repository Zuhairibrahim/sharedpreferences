import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';

/// App Open Ad service: cold-start + resume-from-background ads.
/// Self-contained: unit ID comes from [AdHelper.appOpenUnitId].
class AppOpenAdService with WidgetsBindingObserver {
  AppOpenAdService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final AppOpenAdService instance = AppOpenAdService._internal();

  static const Duration _adExpireDuration = Duration(hours: 4);
  static const Duration _minIntervalBetweenAds = Duration(seconds: 25);
  static const int _maxReleaseLoadAttempts = 3;

  String get _unitId => AdHelper.appOpenUnitId;

  AppOpenAd? _appOpenAd;
  DateTime? _loadedAt;
  DateTime _lastShownAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isShowing = false;
  bool _started = false;
  int _loadAttempts = 0;

  /// Call once after MobileAds.initialize().
  void start() {
    if (_started) return;
    _started = true;
    _load();
    Timer(const Duration(milliseconds: 1300), () {
      showIfAvailable();
    });
  }

  void _load() {
    AppOpenAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _loadAttempts = 0;
          _appOpenAd = ad;
          _loadedAt = DateTime.now();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (AppOpenAd ad) {
              ad.dispose();
              _appOpenAd = null;
              _isShowing = false;
              _load();
            },
            onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
              ad.dispose();
              _appOpenAd = null;
              _isShowing = false;
              _load();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _appOpenAd = null;
          _loadAttempts++;
          if (!kReleaseMode && _loadAttempts < 20) {
            Timer(const Duration(seconds: 15), _load);
          } else if (_loadAttempts < _maxReleaseLoadAttempts) {
            Timer(const Duration(seconds: 30), _load);
          }
        },
      ),
    );
  }

  bool get _isAdAvailable {
    if (_appOpenAd == null || _loadedAt == null) return false;
    if (DateTime.now().difference(_loadedAt!) > _adExpireDuration) return false;
    return true;
  }

  void showIfAvailable() {
    if (_isShowing) return;
    if (DateTime.now().difference(_lastShownAt) < _minIntervalBetweenAds) return;
    if (!_isAdAvailable) {
      if (_appOpenAd == null) _load();
      return;
    }
    _lastShownAt = DateTime.now();
    _isShowing = true;
    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showIfAvailable();
    }
  }
}
