import 'package:flutter/foundation.dart';
import '../models/penjualan_model.dart';
import '../services/api_service.dart';

class PenjualanProvider with ChangeNotifier {
  String? _token;
  List<PenjualanModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  List<PenjualanModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchPenjualan(
      {String? status, String? search, bool refresh = false}) async {
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
      final params = <String, String>{
        'page': _currentPage.toString(),
      };
      if (status != null) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await api.get('penjualan', params: params);
      final List data = response['data'] ?? [];
      final newItems = data.map((e) => PenjualanModel.fromJson(e)).toList();

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

  Future<void> loadMore({String? status, String? search}) async {
    if (!hasMore || _isLoading) return;
    _currentPage++;
    await fetchPenjualan(status: status, search: search);
  }

  Future<PenjualanModel> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('penjualan/$id');
    final json = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    return PenjualanModel.fromJson(json);
  }

  Future<PenjualanModel> createPenjualan(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.post('penjualan', body: data);
    final penjualan = PenjualanModel.fromJson(response['data']);
    _items.insert(0, penjualan);
    notifyListeners();
    return penjualan;
  }

  Future<PenjualanModel> createPenjualanMultipart({
    required Map<String, String> fields,
    List<String>? photoPaths,
  }) async {
    final api = ApiService(token: _token);
    final response = await api.postMultipart(
      'penjualan',
      fields: fields,
      fileListPaths: photoPaths != null ? {'lampiran[]': photoPaths} : null,
    );
    final penjualan = PenjualanModel.fromJson(response['data']);
    _items.insert(0, penjualan);
    notifyListeners();
    return penjualan;
  }

  Future<void> approvePenjualan(int id) async {
    final api = ApiService(token: _token);
    await api.post('penjualan/$id/approve');
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      await fetchPenjualan(refresh: true);
    }
  }

  Future<void> cancelPenjualan(int id) async {
    final api = ApiService(token: _token);
    await api.post('penjualan/$id/cancel');
    await fetchPenjualan(refresh: true);
  }

  Future<void> uncancelPenjualan(int id) async {
    final api = ApiService(token: _token);
    await api.post('penjualan/$id/uncancel');
    await fetchPenjualan(refresh: true);
  }

  Future<void> markAsPaid(int id) async {
    final api = ApiService(token: _token);
    await api.post('penjualan/$id/mark-paid');
    await fetchPenjualan(refresh: true);
  }

  Future<void> unmarkAsPaid(int id) async {
    final api = ApiService(token: _token);
    await api.post('penjualan/$id/unmark-paid');
    await fetchPenjualan(refresh: true);
  }

  Future<PenjualanModel> updatePenjualan(
      int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.put('penjualan/$id', body: data);
    final updated = PenjualanModel.fromJson(response['data'] ?? response);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _items[idx] = updated;
      notifyListeners();
    }
    return updated;
  }
}
