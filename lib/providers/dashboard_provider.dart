import 'package:flutter/foundation.dart';
import '../models/export_options_model.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic> _data = {};
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  Map<String, dynamic> get data => _data;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchDashboard() async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final response = await api.get('dashboard');
      // Unwrap {data: {...}} if API wraps the response
      if (response is Map<String, dynamic> &&
          response.containsKey('data') &&
          response['data'] is Map<String, dynamic>) {
        _data = Map<String, dynamic>.from(response['data']);
      } else if (response is Map<String, dynamic>) {
        _data = Map<String, dynamic>.from(response);
      }

      // Fetch kunjungan count if not provided by dashboard API
      final kunjunganKey = _data['kunjungan_bulan_ini'] ??
          _data['jumlah_kunjungan'] ??
          _data['total_kunjungan'];
      if (kunjunganKey == null || kunjunganKey == 0) {
        try {
          final kunjunganResponse = await api.get('kunjungan');
          List kunjunganList = [];
          if (kunjunganResponse is Map<String, dynamic> &&
              kunjunganResponse.containsKey('data')) {
            final kData = kunjunganResponse['data'];
            if (kData is List) {
              kunjunganList = kData;
            } else if (kData is Map && kData.containsKey('data')) {
              kunjunganList = kData['data'] is List ? kData['data'] : [];
            }
          } else if (kunjunganResponse is List) {
            kunjunganList = kunjunganResponse;
          }
          _data['kunjungan_bulan_ini'] = kunjunganList.length;
        } catch (_) {
          // Silently ignore if kunjungan fetch fails
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> generateReport({
    String? tanggalDari,
    String? tanggalSampai,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final api = ApiService(token: _token);
      final params = <String, String>{};
      if (tanggalDari != null) params['tanggal_dari'] = tanggalDari;
      if (tanggalSampai != null) params['tanggal_sampai'] = tanggalSampai;
      final result = await api.get('dashboard/daily-report', params: params);
      return result is Map<String, dynamic> ? result : {};
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Get export form options and permission flags
  Future<ExportOptionsModel> fetchExportOptions() async {
    final api = ApiService(token: _token);
    final result = await api.get('dashboard/export/options');
    if (result is Map<String, dynamic>) {
      return ExportOptionsModel.fromJson(result);
    }
    return ExportOptionsModel.fromJson(const {});
  }

  /// Export report as binary PDF/Excel (POST /api/v1/dashboard/export)
  Future<List<int>> exportReport({
    required String dateFrom,
    required String dateTo,
    required String transactionType,
    String? statusFilter,
    String? exportFormat,
    String? biayaJenis,
    String? tujuanFilter,
    int? gudangId,
    int? salesId,
  }) async {
    final api = ApiService(token: _token);
    return await api.postBytes('dashboard/export', body: {
      'date_from': dateFrom,
      'date_to': dateTo,
      'transaction_type': transactionType,
      if (statusFilter != null) 'status_filter': statusFilter,
      'export_format': exportFormat ?? 'excel',
      if (biayaJenis != null) 'biaya_jenis': biayaJenis,
      if (tujuanFilter != null) 'tujuan_filter': tujuanFilter,
      if (gudangId != null) 'gudang_id': gudangId,
      if (salesId != null) 'sales_id': salesId,
    });
  }

  /// Download daily report PDF (GET /api/v1/dashboard/daily-report/pdf)
  Future<List<int>> downloadDailyReportPdf({String? date}) async {
    final api = ApiService(token: _token);
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    return await api.getBytes('dashboard/daily-report/pdf', params: params);
  }

  /// Export stok to Excel (GET /api/v1/gudang/stok/export)
  Future<List<int>> exportStokExcel({required int gudangId}) async {
    final api = ApiService(token: _token);
    return await api.getBytes('gudang/stok/export',
        params: {'gudang_id': gudangId.toString()});
  }
}
