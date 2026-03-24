import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class StokProvider with ChangeNotifier {
  String? _token;
  List<dynamic> _stokData = [];
  List<dynamic> _logData = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get stokData => _stokData;
  List<dynamic> get logData => _logData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? _lastGudangId;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchStok({int? gudangId}) async {
    if (_token == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final params = <String, String>{};
      if (gudangId != null) {
        params['gudang_id'] = gudangId.toString();
      }
      // The stock screen expects a flat list of stock rows with produk + gudang.
      // Use gudang/stok endpoint (not stok) and keep a fallback normalizer.
      final response = await api.get('gudang/stok', params: params);
      _stokData = _extractStokList(response);
      _lastGudangId = gudangId;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchLog({
    int? gudangId,
    int? produkId,
    String? tanggalDari,
    String? tanggalSampai,
  }) async {
    if (_token == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final params = <String, String>{};
      if (gudangId != null) params['gudang_id'] = gudangId.toString();
      if (produkId != null) params['produk_id'] = produkId.toString();
      if (tanggalDari != null) params['tanggal_dari'] = tanggalDari;
      if (tanggalSampai != null) params['tanggal_sampai'] = tanggalSampai;

      final response = await api.get('stok/log', params: params);
      _logData = _extractList(response);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStok(Map<String, dynamic> data,
      {int? refreshGudangId}) async {
    final api = ApiService(token: _token);
    await api.post('stok', body: data);
    await fetchStok(gudangId: refreshGudangId ?? _lastGudangId);
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is! Map) return [];

    final data = response['data'];
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'] as List<dynamic>;
      if (data['items'] is List) return data['items'] as List<dynamic>;
      if (data['rows'] is List) return data['rows'] as List<dynamic>;
    }

    if (response['items'] is List) return response['items'] as List<dynamic>;
    if (response['rows'] is List) return response['rows'] as List<dynamic>;
    return [];
  }

  List<dynamic> _extractStokList(dynamic response) {
    final list = _extractList(response);

    // Expected format from /gudang/stok: flat GudangProduk rows.
    final looksFlat = list.isNotEmpty &&
        list.first is Map &&
        (list.first['produk'] != null || list.first['gudang'] != null);
    if (looksFlat || list.isEmpty) return list;

    // Legacy format fallback from /stok: list of gudang with produk_stok.
    final flattened = <dynamic>[];
    for (final row in list) {
      if (row is! Map) continue;
      final gudangId = row['id'];
      final gudangName = row['nama_gudang'] ?? row['nama'] ?? row['name'];
      final stokRows = row['produk_stok'] ?? row['produkStok'];
      if (stokRows is! List) continue;

      for (final item in stokRows) {
        if (item is! Map) continue;
        final merged = Map<String, dynamic>.from(item);
        merged['gudang_id'] = merged['gudang_id'] ?? gudangId;
        merged['gudang'] = merged['gudang'] ??
            {
              'id': gudangId,
              'nama_gudang': gudangName,
            };
        flattened.add(merged);
      }
    }

    return flattened;
  }
}
