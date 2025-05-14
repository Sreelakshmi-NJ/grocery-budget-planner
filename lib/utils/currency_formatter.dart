import 'package:intl/intl.dart';

class CurrencyFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  String format(double amount) {
    return _formatter.format(amount);
  }

  String formatCompact(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return format(amount);
  }

  double parse(String value) {
    return _formatter.parse(value).toDouble();
  }
} 