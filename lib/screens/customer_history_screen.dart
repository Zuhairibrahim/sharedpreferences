import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/money_math.dart';
import '../services/ad_service.dart';

class CustomerFullHistoryScreen extends StatefulWidget {
  final Customer customer;
  const CustomerFullHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerFullHistoryScreen> createState() => _CustomerFullHistoryScreenState();
}

class _CustomerFullHistoryScreenState extends State<CustomerFullHistoryScreen> {
  // دالة مساعدة لتنسيق الأرقام بالفواصل تلقائياً (بدون فقدان الكسور)
  String _formatNumber(double number) => formatMoney(number);

  @override
  void initState() {
    super.initState();
    AdService.loadInterstitial();
  }

  @override
  void dispose() {
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
                      // عرض إعلان بيني عند نقر المستخدم على عملية (نقطة توقف طبيعية ومحسوبة)
                      AdService.showInterstitialAtBreak();
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