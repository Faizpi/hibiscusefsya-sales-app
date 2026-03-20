import 'package:flutter/foundation.dart';
import '../models/pembelian_model.dart';
import '../services/api_service.dart';

class PembelianProvider with ChangeNotifier {
  String? _token;
  List<PembelianModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  List<PembelianModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchPembelian(
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
      final params = <String, String>{'page': _currentPage.toString()};
      if (status != null) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await api.get('pembelian', params: params);
      final List data = response['data'] ?? [];
      final newItems = data.map((e) => PembelianModel.fromJson(e)).toList();

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
    await fetchPembelian(status: status, search: search);
  }

  Future<PembelianModel> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('pembelian/$id');
    final json = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    return PembelianModel.fromJson(json);
  }

  Future<PembelianModel> createPembelian(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.post('pembelian', body: data);
    final pembelian = PembelianModel.fromJson(response['data']);
    _items.insert(0, pembelian);
    notifyListeners();
    return pembelian;
  }

  Future<PembelianModel> createPembelianMultipart({
    required Map<String, String> fields,
    List<String>? lampiran,
  }) async {
    final api = ApiService(token: _token);
    final response = await api.postMultipart(
      'pembelian',
      fields: fields,
      fileListPaths: lampiran != null ? {'lampiran[]': lampiran} : null,
    );
    final pembelian = PembelianModel.fromJson(response['data']);
    _items.insert(0, pembelian);
    notifyListeners();
    return pembelian;
  }

  Future<void> approvePembelian(int id) async {
    final api = ApiService(token: _token);
    await api.post('pembelian/$id/approve');
    await fetchPembelian(refresh: true);
  }

  Future<void> cancelPembelian(int id) async {
    final api = ApiService(token: _token);
    await api.post('pembelian/$id/cancel');
    await fetchPembelian(refresh: true);
  }

  Future<void> uncancelPembelian(int id) async {
    final api = ApiService(token: _token);
    await api.post('pembelian/$id/uncancel');
    await fetchPembelian(refresh: true);
  }

  Future<PembelianModel> updatePembelian(
      int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.put('pembelian/$id', body: data);
    final updated = PembelianModel.fromJson(response['data'] ?? response);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _items[idx] = updated;
      notifyListeners();
    }
    return updated;
  }
}
