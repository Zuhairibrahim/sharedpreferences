import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart'; // 🔥 تم إضافة مكتبة الفواصل هنا
import '../models/customer_model.dart';

class CustomerFullHistoryScreen extends StatefulWidget {
  final Customer customer;
  const CustomerFullHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerFullHistoryScreen> createState() => _CustomerFullHistoryScreenState();
}

class _CustomerFullHistoryScreenState extends State<CustomerFullHistoryScreen> {
  InterstitialAd? _interstitialAd;

  // دالة مساعدة مضافة لتنسيق الأرقام بالفواصل تلقائياً
  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number);
  }

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-1396394529471927/6080023882',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => _interstitialAd = null,
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سجل العمليات وحركة الدفتر للعميل:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Expanded(
            child: widget.customer.history.isEmpty
                ? const Center(child: Text('لا توجد عمليات مسجلة حالياً.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: widget.customer.history.length,
              itemBuilder: (context, index) {
                final tx = widget.customer.history[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: const Color(0xff121212), borderRadius: BorderRadius.circular(8), border: Border(right: BorderSide(color: tx.isAddition ? Colors.green : Colors.red, width: 5))),
                  child: ListTile(
                    onTap: () {
                      if (_interstitialAd != null) {
                        _interstitialAd!.show();
                      }
                    },
                    title: Text(tx.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    // 🔥 تم تعديل السطر أدناه لإضافة الفواصل للمبلغ المتبقي
                    subtitle: Text('المتبقي بعدها: ${_formatNumber(tx.balanceAfter)} ر.ي', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    // 🔥 تم تعديل السطر أدناه لإضافة الفواصل لمبلغ العملية الحالي (+ أو -)
                    trailing: Text('${tx.isAddition ? "+" : "-"}${_formatNumber(tx.amount)} ر.ي', style: TextStyle(color: tx.isAddition ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}