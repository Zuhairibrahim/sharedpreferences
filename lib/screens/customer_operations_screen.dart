import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/customer_model.dart';
import '../services/storage_service.dart';
import '../services/money_math.dart';
import '../services/ad_service.dart';

class CustomerOperationsScreen extends StatefulWidget {
  final Customer customer;
  final List<Customer> allCustomers;
  const CustomerOperationsScreen({super.key, required this.customer, required this.allCustomers});

  @override
  State<CustomerOperationsScreen> createState() => _CustomerOperationsScreenState();
}

class _CustomerOperationsScreenState extends State<CustomerOperationsScreen> {
  String _inputAmount = '';
  bool _isAddOperation = true;
  String _previewMessage = '';

  @override
  void initState() {
    super.initState();
    AdService.loadInterstitial();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // دالة مساعدة لتنسيق الأرقام بالفواصل تلقائياً عند العرض (بدون فقدان الكسور)
  String _formatNumber(double number) => formatMoney(number);

  // دالة مخصصة لتنسيق النص المكتوب حياً داخل الـ Container
  String _formatLiveInput(String input) {
    if (input.isEmpty) return '0';
    String cleanStr = _convertArabicToEnglishNumbers(input).replaceAll(',', '');
    double? parsed = double.tryParse(cleanStr);
    if (parsed == null) return input;
    return _formatNumber(parsed);
  }

  String _convertArabicToEnglishNumbers(String input) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return result;
  }

  void _onKeyPairPressed(String value) {
    setState(() {
      if (value == 'X') {
        if (_inputAmount.isNotEmpty) _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
      } else {
        if (value == '.' && _inputAmount.contains('.')) return;
        _inputAmount += value;
      }
      _updatePreviewMessage();
    });
  }

  void _updatePreviewMessage() {
    if (_inputAmount.isEmpty) {
      _previewMessage = '';
      return;
    }
    String cleanStr = _convertArabicToEnglishNumbers(_inputAmount);
    double val = double.tryParse(cleanStr) ?? 0.0;
    if (val <= 0) {
      _previewMessage = '';
      return;
    }

    int currentCents = toCents(widget.customer.totalDebt);
    int amountCents = toCents(val);

    if (_isAddOperation) {
      int newDebtCents = currentCents + amountCents;
      _previewMessage = 'سيتم إضافة مبلغ ${_formatNumber(fromCents(amountCents))} ريال يمني لدين العميل.\nالدين الجديد سيكون: ${_formatNumber(fromCents(newDebtCents))} ريال';
    } else {
      if (amountCents > currentCents) {
        _previewMessage = 'تنبيه: مبلغ الخصم أكبر من الدين الحالي (${_formatNumber(widget.customer.totalDebt)} ريال)!';
        return;
      }
      int newDebtCents = currentCents - amountCents;
      _previewMessage = 'سيتم خصم مبلغ ${_formatNumber(fromCents(amountCents))} ريال يمني من دين العميل.\nالباقي سيكون: ${_formatNumber(fromCents(newDebtCents))} ريال';
    }
  }

  void _executeOperation() async {
    String cleanStr = _convertArabicToEnglishNumbers(_inputAmount);
    double amount = double.tryParse(cleanStr) ?? 0.0;
    if (amount <= 0) return;

    int amountCents = toCents(amount);
    int currentCents = toCents(widget.customer.totalDebt);

    if (!_isAddOperation && amountCents > currentCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('المبلغ المدخل أكبر من الدين الحالي!', textAlign: TextAlign.center),
            backgroundColor: Colors.redAccent
        ),
      );
      return;
    }

    setState(() {
      int newDebtCents;
      if (_isAddOperation) {
        newDebtCents = currentCents + amountCents;
        widget.customer.totalDebt = fromCents(newDebtCents);

        widget.customer.history.insert(0, Transaction(
            title: 'إضافة دين جديد',
            amount: fromCents(amountCents),
            balanceAfter: widget.customer.totalDebt,
            date: '2026/06',
            isAddition: true
        ));
      } else {
        newDebtCents = currentCents - amountCents;
        widget.customer.totalDebt = fromCents(newDebtCents);

        widget.customer.history.insert(0, Transaction(
            title: 'سداد مالي (خصم وحفظ)',
            amount: fromCents(amountCents),
            balanceAfter: widget.customer.totalDebt,
            date: '2026/06',
            isAddition: false
        ));
      }
      _inputAmount = '';
      _previewMessage = 'تم حفظ العملية محلياً وتحديث كشف الحساب!';
    });

    await StorageService.saveCustomers(widget.allCustomers);

    // عرض إعلان بيني بعد تنفيذ العملية المالية بنجاح (نقطة توقف طبيعية ومحسوبة)
    await AdService.showInterstitialAtBreak();

    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حفظ العملية وتحديث الحساب بنجاح', textAlign: TextAlign.center),
            backgroundColor: Colors.green
        ),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // كرت تفاصيل العميل العلوي (تم تعديل الديون هنا لتظهر بالفواصل)
                        Container(
                          color: const Color(0xff114f24),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(c.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 5),
                              Text('المبلغ المتبقي: ${_formatNumber(c.totalDebt)} ريال', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('الدين الأولي: ${_formatNumber(c.initialDebt)} ريال', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),

                        // شاشة عرض المبلغ المدخل حياً (تم تعديلها لتظهر الفواصل تلقائياً أثناء النقر)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xff161616), borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: Text(_formatLiveInput(_inputAmount), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),

                        // أزرار تحديد نوع العملية (إضافة / خصم)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(child: ChoiceChip(label: const Center(child: Text('إضافة دين جديد (+)')), selected: _isAddOperation, selectedColor: const Color(0xff0d47a1), onSelected: (val) { setState(() { _isAddOperation = true; _updatePreviewMessage(); }); })),
                              const SizedBox(width: 10),
                              Expanded(child: ChoiceChip(label: const Center(child: Text('خصم وحفظ (-)')), selected: !_isAddOperation, selectedColor: const Color(0xffb71c1c), onSelected: (val) { setState(() { _isAddOperation = false; _updatePreviewMessage(); }); })),
                            ],
                          ),
                        ),

                        // رسالة المعاينة الحية قبل الحفظ
                        if (_previewMessage.isNotEmpty)
                          Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                              child: Text(_previewMessage, textAlign: TextAlign.center, style: TextStyle(color: _isAddOperation ? Colors.greenAccent : Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold))
                          ),

                        // زر التنفيذ الرئيسي
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                          child: ElevatedButton(onPressed: _executeOperation, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(45)), child: Text(_isAddOperation ? 'تسجيل إضافة الدين (+)' : 'تسجيل عملية الخصم (-)')),
                        ),

                        // مساحة مرنة آمنة تدفع الكيبورد للأسفل
                        const Spacer(),

                        // الكيبورد الرقمي المخصص مثبت بالأسفل بشكل فخم ومحمي
                        Container(
                          color: const Color(0xff121212),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildKeyboardRow(['1', '2', '3']),
                              _buildKeyboardRow(['4', '5', '6']),
                              _buildKeyboardRow(['7', '8', '9']),
                              _buildKeyboardRow(['.', '0', 'X']),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(children: keys.map((key) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ElevatedButton(
            onPressed: () => _onKeyPairPressed(key),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1c1c1c), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            child: Text(key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }).toList());
  }
}