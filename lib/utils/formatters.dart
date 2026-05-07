import 'package:flutter/services.dart';
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
        symbol: 'Rp',
        decimalDigits: 2,
      );
    } catch (_) {
      return NumberFormat.currency(
        symbol: 'Rp',
        decimalDigits: 2,
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

  /// Formats a number as Indonesian Rupiah with 2 decimal digits.
  /// Correct format example: 50000 -> "Rp50.000,00".
  /// Example: 12345.678 → "Rp 12.345,678"
  /// If the fractional part is all zeros, still shows 2 digits: "Rp50.000,00"
  static String currency(dynamic amount) {
    if (amount == null) return 'Rp0,00';
    if (amount is String) {
      final parsed = parseRupiah(amount);
      if (parsed == null) return 'Rp0,00';
      return _currencyFormat.format(parsed);
    }
    return _currencyFormat.format(amount);
  }

  /// Formats a number for display in a Rupiah input field.
  /// Uses dot as thousands separator and comma as decimal separator.
  /// Keeps up to 2 decimal digits.
  /// Correct input example: 12345.67 -> "12.345,67".
  /// Example: 12345.678 → "12.345,678"
  static String rupiahInput(num amount) {
    if (amount == 0) return '';
    try {
      // Use id_ID locale: dot for thousands, comma for decimals
      final fmt = NumberFormat('#,##0.##', 'id_ID');
      return fmt.format(amount);
    } catch (_) {
      // Manual fallback
      return _manualRupiahFormat(amount);
    }
  }

  /// Manual fallback for formatting Rupiah input
  static String _manualRupiahFormat(num amount) {
    final isNegative = amount < 0;
    final absVal = amount.abs();

    final intPart = absVal.truncate();
    final fracPart = absVal - intPart;

    // Format integer part with dots as thousands separator
    final intStr = intPart.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );

    // Format fractional part (up to 3 digits, trim trailing zeros)
    String fracStr = '';
    if (fracPart > 0) {
      // Round to 2 decimal places to avoid floating point artifacts
      final rounded = (fracPart * 100).round();
      if (rounded > 0) {
        fracStr = ',${'$rounded'.padLeft(2, '0')}';
        // Trim trailing zeros
        fracStr = fracStr.replaceAll(RegExp(r'0+$'), '');
        if (fracStr == ',') fracStr = '';
      }
    }

    return '${isNegative ? '-' : ''}$intStr$fracStr';
  }

  /// Parses a Rupiah-formatted string back to a double value.
  /// Handles Indonesian format: dot as thousands separator, comma as decimal.
  /// Examples:
  ///   "12.345,678" → 12345.678
  ///   "12.345"     → 12345.0 (dots are thousands separators)
  ///   "12345.678"  → 12345.678 (if dot is clearly decimal)
  static double? parseRupiah(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9,.\\-]'), '');
    if (cleaned.isEmpty || cleaned == '-') return null;

    // Indonesian format: dot = thousands, comma = decimal
    if (cleaned.contains(',')) {
      // "12.345,678" → remove dots, replace comma with period
      return double.tryParse(cleaned.replaceAll('.', '').replaceAll(',', '.'));
    }

    // No comma: check if dots are used as thousands separators
    // Pattern like "12.345" or "1.234.567" = grouped thousands
    final isDotGrouped = RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(cleaned);
    if (isDotGrouped) {
      return double.tryParse(cleaned.replaceAll('.', ''));
    }

    // Otherwise treat dot as decimal: "12345.678"
    return double.tryParse(cleaned);
  }

  static double? parseDecimal(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw.replaceAll(',', '.'));
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
      final d =
          '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year.toString().padLeft(4, '0')}';
      final t =
          '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
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
      return 'Rp${amount.toStringAsFixed(2)}';
    }
  }
}

/// Input formatter for Rupiah fields that preserves decimal fractions.
/// Allows digits, one comma (as decimal separator), and formats thousands
/// with dots. Example input flow: "12345,678" → "12.345,678"
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits and one comma (for decimal separator)
    String text = newValue.text;

    // Strip everything except digits and comma
    text = text.replaceAll(RegExp(r'[^0-9,]'), '');

    if (text.isEmpty) {
      return const TextEditingValue();
    }

    // Ensure at most one comma
    final commaCount = ','.allMatches(text).length;
    if (commaCount > 1) {
      // Keep only the first comma
      final firstComma = text.indexOf(',');
      text = text.substring(0, firstComma + 1) +
          text.substring(firstComma + 1).replaceAll(',', '');
    }

    // Split into integer and decimal parts
    final parts = text.split(',');
    String intPart = parts[0];
    String? decPart = parts.length > 1 ? parts[1] : null;

    // Remove leading zeros from integer part (but keep at least one digit)
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (intPart.isEmpty) intPart = '0';

    // Limit decimal part to 2 digits max
    if (decPart != null && decPart.length > 2) {
      decPart = decPart.substring(0, 2);
    }

    // Format integer part with dot as thousands separator
    intPart = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    // Reconstruct
    final formatted = decPart != null ? '$intPart,$decPart' : intPart;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
