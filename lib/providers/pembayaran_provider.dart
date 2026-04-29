import 'package:flutter/foundation.dart';
import '../models/pembayaran_model.dart';
import '../services/api_service.dart';

class PembayaranProvider with ChangeNotifier {
  String? _token;
  List<PembayaranModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  List<PembayaranModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchPembayaran({bool refresh = false}) async {
    if (_token == null) return;
    if (refresh) {
      _currentPage = 1;
      _items = [];
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final params = <String, String>{'page': _currentPage.toString()};
      final response = await api.get('pembayaran', params: params);
      final List data = response['data'] ?? [];
      final newItems = data.map((e) => PembayaranModel.fromJson(e)).toList();

      if (refresh) {
        _items = newItems;
      } else {
        _items.addAll(newItems);
      }
      _currentPage = response['current_page'] ?? 1;
      _lastPage = response['last_page'] ?? 1;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || _isLoading) return;
    _currentPage++;
    await fetchPembayaran();
  }

  Future<PembayaranModel> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('pembayaran/$id');
    final json = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    return PembayaranModel.fromJson(json);
  }

  Future<List<dynamic>> getPenjualanByGudang(int gudangId) async {
    final api = ApiService(token: _token);
    final response = await api.get('pembayaran/penjualan-by-gudang/$gudangId');
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> getPenjualanDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('pembayaran/penjualan-detail/$id');
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data);
      }
      return response;
    }
    return {};
  }

  Future<PembayaranModel> createPembayaran(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.post('pembayaran', body: data);
    final pembayaran = PembayaranModel.fromJson(response['data']);
    _items.insert(0, pembayaran);
    notifyListeners();
    return pembayaran;
  }

  Future<PembayaranModel> createPembayaranMultipart({
    required Map<String, String> fields,
    List<String>? lampiran,
  }) async {
    final api = ApiService(token: _token);
    final response = await api.postMultipart(
      'pembayaran',
      fields: fields,
      fileListPaths: lampiran != null ? {'lampiran[]': lampiran} : null,
    );
    final pembayaran = PembayaranModel.fromJson(response['data']);
    _items.insert(0, pembayaran);
    notifyListeners();
    return pembayaran;
  }

  Future<void> approvePembayaran(int id) async {
    final api = ApiService(token: _token);
    await api.post('pembayaran/$id/approve');
    await fetchPembayaran(refresh: true);
  }

  Future<void> cancelPembayaran(int id) async {
    final api = ApiService(token: _token);
    await api.post('pembayaran/$id/cancel');
    await fetchPembayaran(refresh: true);
  }

  Future<void> uncancelPembayaran(int id) async {
    final api = ApiService(token: _token);
    await api.post('pembayaran/$id/uncancel');
    await fetchPembayaran(refresh: true);
  }

  Future<List<int>> downloadHarianPdf({required String date}) async {
    final api = ApiService(token: _token);
    return await api.getBytes('pembayaran/export-harian-pdf', params: {'tanggal': date});
  }
}
