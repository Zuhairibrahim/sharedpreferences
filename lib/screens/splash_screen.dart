import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // تأكد أن ملف شاشتك الرئيسية بهذا الاسم

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // مؤقت زمني 3 ثوانٍ ثم الانتقال التلقائي المستقر لشاشة الحسابات والأرقام
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. فرش صورة icon.png على كامل أبعاد شاشة التلفون بدون حواف
          Positioned.fill(
            child: Image.asset(
              'assets/icon.png',
              fit: BoxFit.fill,
            ),
          ),

          // 2. العداد الدائري وجاري التحميل يظهران بوضوح أسفل الشاشة فوق الصورة
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 55,
                  height: 55,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'جاري التحميل...',
                  style: TextStyle(
                    fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
