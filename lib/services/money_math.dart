import 'package:intl/intl.dart';

final NumberFormat _moneyFormat = NumberFormat('#,##0.##', 'en_US');

String formatMoney(double value) => _moneyFormat.format(value);

int toCents(double value) => (value * 100).round();

double fromCents(int cents) => cents / 100;

double roundToCents(double value) => fromCents(toCents(value));
