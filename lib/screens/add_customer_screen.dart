import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // تفعيل التنسيق والتحكم بالمدخلات

import '../models/customer_model.dart';
import '../services/storage_service.dart';
import '../services/money_math.dart';
import '../services/ad_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final List<Customer> allCustomers;
  const AddCustomerScreen({super.key, required this.allCustomers});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _initialDebtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AdService.loadInterstitial();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // دالة تحويل الأرقام العربية (الشرقية) إلى إنجليزية لضمان صحة التحقق والتخزين
  String _convertArabicToEnglishNumbers(String input) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة عميل جديد'), centerTitle: true, backgroundColor: const Color(0xff121212)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CircleAvatar(radius: 45, backgroundColor: Colors.grey[800], child: const Icon(Icons.account_circle, size: 70, color: Colors.grey)),
                const SizedBox(height: 25),

                _buildInputField('الاسم الأول', _firstNameController, TextInputType.text, (value) {
                  if (value == null || value.trim().isEmpty) return 'يرجى إدخال الاسم الأول';
                  return null;
                }),

                _buildInputField('اللقب / العائلة', _lastNameController, TextInputType.text, (value) {
                  if (value == null || value.trim().isEmpty) return 'يرجى إدخال اللقب أو اسم العائلة';
                  return null;
                }),

                // 🔥 حقل رقم الهاتف المطور مع الأمثلة البسيطة والمنظمة الجديدة
                _buildInputField(
                  'رقم الهاتف',
                  _phoneController,
                  TextInputType.phone,
                      (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }

                    // تحويل المدخلات لأرقام إنجليزية قبل فحص الشروط
                    String cleanPhone = _convertArabicToEnglishNumbers(value.trim());

                    // 1. التحقق من الطول الإلزامي (يجب أن يكون 9 أرقام بالضبط)
                    if (cleanPhone.length != 9) {
                      return 'يجب أن يتكون رقم الهاتف من 9 أرقام بالضبط';
                    }

                    // 2. الفحص الذكي والموحد للمقدمات المطلوبة
                    if (!cleanPhone.startsWith('77') &&
                        !cleanPhone.startsWith('78') &&
                        !cleanPhone.startsWith('73') &&
                        !cleanPhone.startsWith('71')) {
                      return 'خطأ في البداية! يجب أن يبدأ بـ (77، 78، 73، 71)';
                    }

                    return null;
                  },
                  isPhone: true, // تفعيل تحديد الطول الأقصى 9 خانات
                ),

                _buildInputField(
                    'الدين الأولي (ريال يمني)',
                    _initialDebtController,
                    TextInputType.number,
                        (value) {
                      if (value == null || value.trim().isEmpty) return 'يرجى إدخال المبلغ الأولي';
                      return null;
                    },
                    isMoney: true
                ),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {

                      String enteredFirstName = _firstNameController.text.trim();
                      String enteredLastName = _lastNameController.text.trim();
                      String fullNameEntered = '$enteredFirstName $enteredLastName'.trim();

                      bool isExist = widget.allCustomers.any((customer) =>
                      customer.fullName.trim().toLowerCase() == fullNameEntered.toLowerCase()
                      );

                      if (isExist) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '⚠️ تنبيه: العميل "$fullNameEntered" مضاف مسبقاً بالدفتر!',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.right,
                            ),
                            backgroundColor: Colors.red[900],
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      String cleanPhone = _convertArabicToEnglishNumbers(_phoneController.text.trim());
                      String rawDebtStr = _initialDebtController.text.replaceAll(',', '').trim();
                      String cleanDebtStr = _convertArabicToEnglishNumbers(rawDebtStr);
                      double debt = roundToCents(double.tryParse(cleanDebtStr) ?? 0.0);

                      Customer newCustomer = Customer(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        firstName: enteredFirstName,
                        lastName: enteredLastName,
                        phone: cleanPhone,
                        totalDebt: debt,
                        initialDebt: debt,
                        history: [],
                      );

                      widget.allCustomers.add(newCustomer);
                      await StorageService.saveCustomers(widget.allCustomers);

                      // عرض إعلان بيني بعد حفظ العميل (نقطة توقف طبيعية ومحسوبة)
                      await AdService.showInterstitialAtBreak();

                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00695c), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                  child: const Text('حفظ العميل', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      TextInputType type,
      String? Function(String?)? validator,
      {bool isMoney = false, bool isPhone = false}
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: type,
            style: const TextStyle(color: Colors.white),
            inputFormatters: isMoney
                ? [ThousandsFormatter()] // 🔥 يستدعي المنسق الذكي المعدل أدناه
                : isPhone
                ? [LengthLimitingTextInputFormatter(9), FilteringTextInputFormatter.digitsOnly]
                : [],
            validator: validator,
            decoration: InputDecoration(
              fillColor: const Color(0xff121212),
              filled: true,
              hintText: isPhone ? 'أمثلة: 771234567 أو 781234567 أو 731234567' : null,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔥 تم تعديل منسق الفواصل هنا ليدعم الأرقام العربية ويحافظ على استقرار مؤشر الكتابة
class ThousandsFormatter extends TextInputFormatter {
  String _convertArabicToEnglish(String input) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return result;
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    // تحويل الأرقام المدخلة أولاً للتأكد من توافقها مع صيغ الفواصل
    String englishText = _convertArabicToEnglish(newValue.text);
    String cleanText = englishText.replaceAll(',', '');

    if (num.tryParse(cleanText) == null) return oldValue;

    final buffer = StringBuffer();
    int count = 0;
    for (int i = cleanText.length - 1; i >= 0; i--) {
      if (count == 3) {
        buffer.write(',');
        count = 0;
      }
      buffer.write(cleanText[i]);
      count++;
    }

    final formatted = buffer.toString().split('').reversed.join('');

    // حساب موقع المؤشر (Cursor) الجديد بدقة لكي لا يسبب قفزات مزعجة أثناء التعديل
    int selectionOffset = formatted.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      int commasBeforeOffset = newValue.text.substring(0, newValue.selection.baseOffset).split(',').length - 1;
      int cleanOffset = newValue.selection.baseOffset - commasBeforeOffset;

      int currentCommas = 0;
      int newOffset = 0;
      while (newOffset < formatted.length && (newOffset - currentCommas) < cleanOffset) {
        if (formatted[newOffset] == ',') {
          currentCommas++;
        }
        newOffset++;
      }
      selectionOffset = newOffset;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}