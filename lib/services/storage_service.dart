import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';

class StorageService {
  static const String _storageKey = 'smart_book_customers_data';

  static Future<void> saveCustomers(List<Customer> customers) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonList = customers.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  static Future<List<Customer>> loadCustomers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(_storageKey);
    
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }
    
    return jsonList.map((item) => Customer.fromMap(jsonDecode(item))).toList();
  }
}
