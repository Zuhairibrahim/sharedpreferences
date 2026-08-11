import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart'; // 🔥 تم إضافة مكتبة الفواصل هنا
import '../models/customer_model.dart';
import '../services/storage_service.dart';
import 'customer_tabs_screen.dart'; // تأكد من مطابقة اسم ملف التبويبات لديك
import 'add_customer_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Customer> _allCustomers = [];      // القائمة الثابتة والمخزن الرئيسي لكل الزبائن
  List<Customer> _filteredCustomers = []; // القائمة المرنة المخصصة للعرض فقط

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // 🔥 مستشعر للتحكم بمؤشر حقل البحث يدوياً

  // متغيرات العدادات الأربعة الفوقية
  double _totalInitial = 0.0;
  double _totalCurrent = 0.0;
  double _totalAdded = 0.0;
  double _totalReceipts = 0.0;

  InterstitialAd? _interstitialAd;

  // دالة مساعدة مضافة لتنسيق الأرقام بالفواصل تلقائياً
  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadInterstitialAd();
    _startAdTimer();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => _interstitialAd = null,
      ),
    );
  }

  void _startAdTimer() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_interstitialAd != null) {
        _interstitialAd!.show();
        _interstitialAd = null;
        _loadInterstitialAd();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // إغلاق المستشعر عند تدمير الشاشة لحماية الذاكرة
    _interstitialAd?.dispose();
    super.dispose();
  }

  // تحميل البيانات من ملفات التخزين المحلية
  Future<void> _loadData() async {
    List<Customer> loaded = await StorageService.loadCustomers();
    setState(() {
      _allCustomers = loaded;
      _filteredCustomers = List.from(_allCustomers);
      _calculateTotals(); // حساب العدادات لجميع الناس
    });
  }

  // 🔥 دالة الحساب بالملّي: تجمع دائماً من القائمة الشاملة لجميع العملاء لضمان عدم لخبطة الأرقام أثناء البحث
  void _calculateTotals() {
    double initial = 0.0;
    double current = 0.0;
    double added = 0.0;
    double receipts = 0.0;

    for (var customer in _allCustomers) {
      initial += customer.initialDebt;
      current += customer.totalDebt;

      for (var tx in customer.history) {
        if (tx.isAddition) {
          added += tx.amount;
        } else {
          receipts += tx.amount;
        }
      }
    }

    // تقريب عشري صارم لمنع أي كسور برمجية وهمية في لغة Dart
    _totalInitial = double.parse(initial.toStringAsFixed(2));
    _totalCurrent = double.parse(current.toStringAsFixed(2));
    _totalAdded = double.parse(added.toStringAsFixed(2));
    _totalReceipts = double.parse(receipts.toStringAsFixed(2));
  }

  // دالة الفلترة اليدوية أثناء الكتابة الفعليّة فقط
  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(_allCustomers);
      } else {
        _filteredCustomers = _allCustomers
            .where((c) => c.fullName.toLowerCase().contains(query.toLowerCase()) || c.phone.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        title: const Text('الدفتر الذكي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xff121212),
        elevation: 0,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // كروت ملخص الحسابات (تم تعديل القيم هنا لتظهر بالفواصل)
              // ---------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ملخص الحسابات', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTotalCard('إجمالي الديون الحالية', '${_formatNumber(_totalCurrent)} ريال', Colors.greenAccent),
                        const SizedBox(width: 10),
                        _buildTotalCard('إجمالي الديون الأولية', '${_formatNumber(_totalInitial)} ريال', Colors.white),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTotalCard('(+) إجمالي الديون المضافة', '${_formatNumber(_totalAdded)} ريال', Colors.white),
                        const SizedBox(width: 10),
                        _buildTotalCard('إجمالي المقبوضات (الخصم)', '${_formatNumber(_totalReceipts)} ريال', Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------------------
              // شريط البحث المطور (يخضع للتحكم اليدوي الكامل)
              // ---------------------------------------------------------------
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xff1d1d1d), borderRadius: BorderRadius.circular(8)),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode, // ربط مستشعر التركيز هنا
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterCustomers,
                  decoration: const InputDecoration(
                    hintText: 'البحث عن عميل...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // قائمة العملاء الرئيسية (تم تعديل الـ trailing هنا لتظهر بالفواصل)
              // ---------------------------------------------------------------
              Expanded(
                child: _filteredCustomers.isEmpty
                    ? const Center(child: Text('لا يوجد عملاء مطابقتين للبحث', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  itemCount: _filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xff1a1a1a), borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xff2c2c2c),
                          child: Icon(Icons.person, color: Colors.white70),
                        ),
                        title: Text(customer.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(customer.phone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Text('${_formatNumber(customer.totalDebt)} ريال', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

                        // 🔥 منطق الانتقال والعودة اليدوي الصارم
                        onTap: () async {
                          // 1. الانتقال لشاشة التبويبات وانتظار العودة
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerDetailTabs(
                                customer: customer,
                                allCustomers: _allCustomers,
                              ),
                            ),
                          );

                          // 2. 🔥 فور الرجوع للشاشة: قتل أمر البحث تماماً وإظهار شاشة كل العملاء يدوياً
                          setState(() {
                            _searchController.clear(); // مسح نص الكتابة كلياً
                            _searchFocusNode.unfocus(); // سحب مؤشر الكتابة وإغلاق الكيبورد بقوة لكي لا يفتح تلقائياً
                            _filteredCustomers = List.from(_allCustomers); // استعادة واجهة كل الزبائن فوراً
                            _calculateTotals(); // إعادة حساب وتثبيت العدادات لكل الناس بالملي
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              // زر إضافة عميل جديد
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => AddCustomerScreen(allCustomers: _allCustomers)));
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('إضافة عميل جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(String title, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(color: valueColor == Colors.white ? Colors.black : valueColor, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}