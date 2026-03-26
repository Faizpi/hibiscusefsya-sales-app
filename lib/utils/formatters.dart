import 'package:intl/intl.dart';

class Formatters {
  static NumberFormat? _currencyFormatCached;
  static DateFormat? _dateFormatCached;
  static DateFormat? _dateTimeFormatCached;

  static NumberFormat get _currencyFormat {
    return _currencyFormatCached ??= _buildCurrencyFormat();
  }

  static DateFormat get _dateFormat {
    return _dateFormatCached ??= _buildDateFormat();
  }

  static DateFormat get _dateTimeFormat {
    return _dateTimeFormatCached ??= _buildDateTimeFormat();
  }

  static NumberFormat _buildCurrencyFormat() {
    try {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
    } catch (_) {
      return NumberFormat.currency(
        symbol: 'Rp ',
        decimalDigits: 0,
      );
    }
  }

  static DateFormat _buildDateFormat() {
    try {
      return DateFormat('dd/MM/yyyy', 'id_ID');
    } catch (_) {
      return DateFormat('dd/MM/yyyy');
    }
  }

  static DateFormat _buildDateTimeFormat() {
    try {
      return DateFormat('dd/MM/yyyy | HH:mm', 'id_ID');
    } catch (_) {
      return DateFormat('dd/MM/yyyy | HH:mm');
    }
  }

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
    try {
      return _dateFormat.format(parsed);
    } catch (_) {
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year.toString().padLeft(4, '0')}';
    }
  }

  static String dateTime(dynamic dateStr) {
    final parsed = _tryParseDate(dateStr);
    if (parsed == null) {
      if (dateStr == null) return '-';
      final raw = dateStr.toString().trim();
      return raw.isEmpty ? '-' : raw;
    }
    try {
      return _dateTimeFormat.format(parsed);
    } catch (_) {
      final d = '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year.toString().padLeft(4, '0')}';
      final t = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      return '$d | $t';
    }
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
    s = s.replaceFirst(RegExp(r'\s+00Z$'), 'Z');
    s = s.replaceFirst(RegExp(r'\s+00:00$'), '+00:00');
    s = s.replaceFirst(RegExp(r'\s+0000$'), '+0000');
    s = s.replaceFirst(RegExp(r'\s+Z$'), 'Z');
    s = s.replaceFirstMapped(
        RegExp(r'([+-]\d{2})(\d{2})$'), (m) => '${m.group(1)}:${m.group(2)}');
    s = s.replaceFirstMapped(
        RegExp(r'\s+([+-]\d{2}:\d{2})$'), (m) => m.group(1)!);

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
    try {
      return _currencyFormat.format(amount);
    } catch (_) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }
}
