class ExportOptionItem {
  final String value;
  final String label;

  const ExportOptionItem({required this.value, required this.label});

  @override
  String toString() => 'ExportOptionItem(value: $value, label: $label)';
}

class ExportOptionsModel {
  final bool canExportFullReport;
  final List<ExportOptionItem> transactionTypes;
  final List<ExportOptionItem> statusFilters;
  final List<ExportOptionItem> exportFormats;
  final List<ExportOptionItem> biayaJenisOptions;
  final List<ExportOptionItem> tujuanFilters;
  final List<ExportOptionItem> gudangOptions;
  final List<ExportOptionItem> salesOptions;
  final String defaultTransactionType;
  final String defaultStatusFilter;
  final String defaultExportFormat;

  const ExportOptionsModel({
    required this.canExportFullReport,
    required this.transactionTypes,
    required this.statusFilters,
    required this.exportFormats,
    required this.biayaJenisOptions,
    required this.tujuanFilters,
    required this.gudangOptions,
    required this.salesOptions,
    required this.defaultTransactionType,
    required this.defaultStatusFilter,
    required this.defaultExportFormat,
  });

  factory ExportOptionsModel.fromJson(Map<String, dynamic> rawJson) {
    final root = _unwrap(rawJson);

    final transactionTypes = _parseOptions(
      _pick(root, const ['transaction_types', 'transaction_type_options']),
      fallback: const [
        ExportOptionItem(value: 'all', label: 'Semua Transaksi'),
      ],
    );

    final statusFilters = _parseOptions(
      _pick(root, const ['status_filters', 'status_filter_options']),
      fallback: const [
        ExportOptionItem(value: 'all', label: 'Semua Status'),
        ExportOptionItem(value: 'Pending', label: 'Pending'),
        ExportOptionItem(value: 'Approved', label: 'Approved'),
        ExportOptionItem(value: 'Lunas', label: 'Lunas'),
        ExportOptionItem(value: 'Rejected', label: 'Rejected'),
        ExportOptionItem(value: 'Canceled', label: 'Canceled'),
      ],
    );

    final exportFormats = _parseOptions(
      _pick(root, const ['export_formats', 'export_format_options']),
      fallback: const [
        ExportOptionItem(value: 'pdf', label: 'PDF'),
        ExportOptionItem(value: 'excel', label: 'Excel'),
      ],
    );

    final biayaJenisOptions = _parseOptions(
      _pick(root, const ['biaya_jenis_options', 'biaya_types']),
      fallback: const [
        ExportOptionItem(value: 'masuk', label: 'Masuk'),
        ExportOptionItem(value: 'keluar', label: 'Keluar'),
      ],
    );

    final tujuanFilters = _parseOptions(
      _pick(root, const ['tujuan_filters', 'tujuan_filter_options']),
      fallback: const [
        ExportOptionItem(
            value: 'Pemeriksaan Stock', label: 'Pemeriksaan Stock'),
        ExportOptionItem(value: 'Penagihan', label: 'Penagihan'),
        ExportOptionItem(value: 'Promo', label: 'Promo'),
      ],
    );

    final gudangOptions = _parseOptions(
      _pick(root, const ['gudang_options', 'gudangs']),
    );

    final salesOptions = _parseOptions(
      _pick(root, const ['sales_options', 'sales_users', 'sales']),
    );

    final defaults = root['defaults'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(root['defaults'] as Map)
        : <String, dynamic>{};

    final defaultTransactionType = _resolveDefault(
      defaults['transaction_type']?.toString(),
      transactionTypes,
      fallback: 'all',
    );

    final defaultStatusFilter = _resolveDefault(
      defaults['status_filter']?.toString(),
      statusFilters,
      fallback: 'all',
    );

    final defaultExportFormat = _resolveDefault(
      defaults['export_format']?.toString(),
      exportFormats,
      fallback: 'pdf',
    );

    final permissions = root['permissions'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(root['permissions'] as Map)
        : <String, dynamic>{};

    final canExportFullReport = (root['can_export_full_report'] == true) ||
        (permissions['can_export_full_report'] == true);

    return ExportOptionsModel(
      canExportFullReport: canExportFullReport,
      transactionTypes: transactionTypes,
      statusFilters: statusFilters,
      exportFormats: exportFormats,
      biayaJenisOptions: biayaJenisOptions,
      tujuanFilters: tujuanFilters,
      gudangOptions: gudangOptions,
      salesOptions: salesOptions,
      defaultTransactionType: defaultTransactionType,
      defaultStatusFilter: defaultStatusFilter,
      defaultExportFormat: defaultExportFormat,
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> source) {
    if (source['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(source['data'] as Map);
    }
    return source;
  }

  static dynamic _pick(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key)) return source[key];
    }
    return null;
  }

  static List<ExportOptionItem> _parseOptions(
    dynamic raw, {
    List<ExportOptionItem> fallback = const [],
  }) {
    if (raw == null) return fallback;

    if (raw is List) {
      final result = <ExportOptionItem>[];
      for (final item in raw) {
        if (item is String || item is num || item is bool) {
          final value = item.toString();
          result.add(ExportOptionItem(value: value, label: _humanize(value)));
          continue;
        }

        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final value = _pick(map, const ['value', 'id', 'key', 'code', 'slug'])
                  ?.toString() ??
              '';
          if (value.isEmpty) continue;
          final label = _pick(map, const [
                'label',
                'name',
                'nama',
                'nama_gudang',
                'text',
                'title'
              ])?.toString() ??
              _humanize(value);
          result.add(ExportOptionItem(value: value, label: label));
        }
      }
      return result.isEmpty ? fallback : result;
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final result = map.entries.map((entry) {
        final value = entry.key;
        final label = entry.value?.toString() ?? _humanize(value);
        return ExportOptionItem(value: value, label: label);
      }).toList();
      return result.isEmpty ? fallback : result;
    }

    return fallback;
  }

  static String _resolveDefault(
    String? suggested,
    List<ExportOptionItem> options, {
    required String fallback,
  }) {
    if (suggested != null &&
        options.any((option) => option.value == suggested)) {
      return suggested;
    }

    if (options.any((option) => option.value == fallback)) {
      return fallback;
    }

    return options.isNotEmpty ? options.first.value : fallback;
  }

  static String _humanize(String raw) {
    final cleaned = raw.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return raw;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}
