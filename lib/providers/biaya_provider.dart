import 'package:flutter/foundation.dart';
import '../models/biaya_model.dart';
import '../services/api_service.dart';

class BiayaProvider with ChangeNotifier {
  String? _token;
  List<BiayaModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  List<BiayaModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchBiaya(
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
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      final response = await api.get('biaya', params: params);
      final List data = response['data'] ?? [];
      final newItems = data.map((e) => BiayaModel.fromJson(e)).toList();

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
    await fetchBiaya(status: status, search: search);
  }

  Future<BiayaModel> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('biaya/$id');
    final json = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    return BiayaModel.fromJson(json);
  }

  Future<BiayaModel> createBiaya(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.post('biaya', body: data);
    final biaya = BiayaModel.fromJson(response['data']);
    _items.insert(0, biaya);
    notifyListeners();
    return biaya;
  }

  Future<BiayaModel> createBiayaMultipart({
    required Map<String, String> fields,
    List<String>? lampiran,
  }) async {
    final api = ApiService(token: _token);
    final response = await api.postMultipart(
      'biaya',
      fields: fields,
      fileListPaths: lampiran != null ? {'lampiran[]': lampiran} : null,
    );
    final biaya = BiayaModel.fromJson(response['data']);
    _items.insert(0, biaya);
    notifyListeners();
    return biaya;
  }

  Future<void> approveBiaya(int id) async {
    final api = ApiService(token: _token);
    await api.post('biaya/$id/approve');
    await fetchBiaya(refresh: true);
  }

  Future<void> cancelBiaya(int id) async {
    final api = ApiService(token: _token);
    await api.post('biaya/$id/cancel');
    await fetchBiaya(refresh: true);
  }

  Future<void> uncancelBiaya(int id) async {
    final api = ApiService(token: _token);
    await api.post('biaya/$id/uncancel');
    await fetchBiaya(refresh: true);
  }

  Future<BiayaModel> updateBiaya(int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.put('biaya/$id', body: data);
    final updated = BiayaModel.fromJson(response['data'] ?? response);
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _items[idx] = updated;
      notifyListeners();
    }
    return updated;
  }
}
