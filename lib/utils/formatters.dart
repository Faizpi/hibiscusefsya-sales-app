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
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) {
      if (dateStr == null) return '-';
      final raw = dateStr.toString().trim();
      return raw.isEmpty ? '-' : raw;
    }
    return _dateFormat.format(parsed);
  }

  static String dateTime(dynamic dateStr) {
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) {
      if (dateStr == null) return '-';
      final raw = dateStr.toString().trim();
      return raw.isEmpty ? '-' : raw;
    }
    return _dateTimeFormat.format(parsed);
  }

  static String dateOnly(dynamic dateStr) {
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) {
      if (dateStr == null) return '-';
      final raw = dateStr.toString().trim();
      return raw.isEmpty ? '-' : raw;
    }
    return _dateFormat.format(parsed);
  }

  static DateTime? _tryParseDate(dynamic input) {
    if (input == null) return null;

    var s = input.toString().trim();
    if (s.isEmpty) return null;

    // Normalize common backend timezone variants to RFC3339-compatible forms.
    s = s.replaceFirst(RegExp(r'\s+Z$'), 'Z');
    s = s.replaceFirst(RegExp(r'([+-]\d{2})(\d{2})$'), r'$1:$2');
    s = s.replaceFirst(RegExp(r'\s+([+-]\d{2}:\d{2})$'), r'$1');

    // Clamp fractional seconds to max 6 digits for Dart parser compatibility.
    final frac = RegExp(r'\.(\d{7,})');
    if (frac.hasMatch(s)) {
      s = s.replaceFirstMapped(frac, (m) {
        final digits = m.group(1)!;
        return '.${digits.substring(0, 6)}';
      });
    }

    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
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
