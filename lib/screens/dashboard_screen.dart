import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/customer_model.dart';
import '../services/storage_service.dart';
import '../services/money_math.dart';
import '../services/ad_service.dart';
import '../ads/ads_manager.dart';
import '../widgets/inline_native_ad.dart';
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

  // تناوب بين البيني العادي والبيني بمكافأة عند نقاط التوقف الطبيعية
  bool _useRewardedInterstitialNext = false;

  // دالة مساعدة لتنسيق الأرقام بالفواصل تلقائياً (بدون فقدان الكسور)
  String _formatNumber(double number) => formatMoney(number);

  @override
  void initState() {
    super.initState();
    _loadData();
    AdService.loadInterstitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // إغلاق المستشعر عند تدمير الشاشة لحماية الذاكرة
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
  // الحساب يتم بأعداد صحيحة (فلسات = 1/100) لمنع أي كسور برمجية وهمية في لغة Dart
  void _calculateTotals() {
    int initial = 0;
    int current = 0;
    int added = 0;
    int receipts = 0;

    for (var customer in _allCustomers) {
      initial += toCents(customer.initialDebt);
      current += toCents(customer.totalDebt);

      for (var tx in customer.history) {
        if (tx.isAddition) {
          added += toCents(tx.amount);
        } else {
          receipts += toCents(tx.amount);
        }
      }
    }

    _totalInitial = fromCents(initial);
    _totalCurrent = fromCents(current);
    _totalAdded = fromCents(added);
    _totalReceipts = fromCents(receipts);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            tooltip: 'شاهد إعلان وادعم التطبيق',
            onPressed: () => AdsManager.instance.showRewarded(onRewarded: () {}),
          ),
        ],
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
                  itemCount: _filteredCustomers.length + _filteredCustomers.length ~/ 8,
                  itemBuilder: (context, index) {
                    if ((index + 1) % 9 == 0) {
                      return const InlineNativeAd();
                    }
                    final customerIndex = index - ((index + 1) ~/ 9);
                    if (customerIndex >= _filteredCustomers.length) {
                      return const SizedBox.shrink();
                    }
                    final customer = _filteredCustomers[customerIndex];
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

                          // 2. عرض إعلان عند العودة (نقطة توقف طبيعية وبحد زمني آمن)
                          //    بالتناوب بين البيني العادي والبيني بمكافأة
                          if (_useRewardedInterstitialNext) {
                            AdsManager.instance.showRewardedInterstitial();
                          } else {
                            await AdService.showInterstitialAtBreak();
                          }
                          _useRewardedInterstitialNext = !_useRewardedInterstitialNext;

                          // 3. 🔥 فور الرجوع للشاشة: قتل أمر البحث تماماً وإظهار شاشة كل العملاء يدوياً
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