import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy | HH:mm', 'id_ID');

  static String currency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    if (amount is String) {
      final parsed = num.tryParse(amount);
      if (parsed == null) return 'Rp 0';
      return _currencyFormat.format(parsed);
    }
    return _currencyFormat.format(amount);
  }

  static String date(dynamic dateStr) {
    if (dateStr == null) return '-';
    final s = dateStr.toString().trim();
    if (s.isEmpty) return '-';
    try {
      final dt = DateTime.parse(s).toLocal();
      if (s.contains('T') || s.contains(' ')) {
        return _dateTimeFormat.format(dt);
      }
      return _dateFormat.format(dt);
    } catch (_) {
      return s;
    }
  }

  static String dateTime(dynamic dateStr) {
    if (dateStr == null) return '-';
    final s = dateStr.toString().trim();
    if (s.isEmpty) return '-';
    try {
      return _dateTimeFormat.format(DateTime.parse(s).toLocal());
    } catch (_) {
      return s;
    }
  }

  static String dateOnly(dynamic dateStr) {
    if (dateStr == null) return '-';
    final s = dateStr.toString().trim();
    if (s.isEmpty) return '-';
    try {
      return _dateFormat.format(DateTime.parse(s).toLocal());
    } catch (_) {
      return s;
    }
  }

  static String compactCurrency(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}Rb';
    }
    return _currencyFormat.format(amount);
  }
}
