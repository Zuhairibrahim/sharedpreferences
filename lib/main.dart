// ============================================================================
//  © 2026 Zuhair Ibrahim — ALL RIGHTS RESERVED | جميع الحقوق محفوظة © زهير إبراهيم
//  Project: Smart Book — الدفتر الذكي
//  This code contains a proprietary embedded copyright fingerprint.
//  Selling, redistributing, or removing this notice is strictly forbidden.
//  ============================================================================

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads/ad_consent.dart';
import 'ads/ads_manager.dart';
import 'ads/app_open_ad_service.dart';
import 'screens/splash_screen.dart';
import 'core/ownership/ownership_guard.dart';

/// بصمة الملكية الفكرية — يُمنع حذفها أو تعديلها (انظر ملف LICENSE)
/// Proprietary ownership fingerprint — must NOT be removed or altered (see LICENSE).
const String kAppOwnershipFingerprint =
    'OWNER:Zuhair-Ibrahim|PROJECT:smartbook|YEAR:2026|'
    'LICENSE:ALL-RIGHTS-RESERVED|SIG:ZI-2026-SBK-PROPRIETARY';

void main() async {
  assert(ownershipSealsIntact(), 'Ownership seals must remain intact — see LICENSE');
  WidgetsFlutterBinding.ensureInitialized();
  await AdConsent.instance.collectConsent();
  await MobileAds.instance.initialize();
  AdsManager.instance.loadAll();
  AppOpenAdService.instance.start();

  // فحص الاتصال عند بداية تشغيل التطبيق
  final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
  bool isConnected = !connectivityResult.contains(ConnectivityResult.none);

  runApp(SmartBookApp(isConnected: isConnected));
}

class SmartBookApp extends StatelessWidget {
  final bool isConnected;
  const SmartBookApp({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الدفتر الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff090909),
        primaryColor: Colors.white,
      ),
      home: isConnected
          ? const SplashScreen()
          : Scaffold(
        backgroundColor: const Color(0xff090909),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.wifi_off, size: 100, color: Colors.redAccent),
                SizedBox(height: 20),
                Text(
                  'الرجاء الاتصال بالإنترنت لإتمام العمليات',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'لا يمكن تشغيل التطبيق بدون اتصال.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}