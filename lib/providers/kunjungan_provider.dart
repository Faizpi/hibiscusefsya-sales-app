import 'package:flutter/foundation.dart';
import '../models/kunjungan_model.dart';
import '../services/api_service.dart';

class KunjunganProvider with ChangeNotifier {
  String? _token;
  List<KunjunganModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  List<KunjunganModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchKunjungan({String? status, bool refresh = false}) async {
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

      final response = await api.get('kunjungan', params: params);
      final List data = response['data'] ?? [];
      final newItems = data.map((e) => KunjunganModel.fromJson(e)).toList();

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

  Future<void> loadMore({String? status}) async {
    if (!hasMore || _isLoading) return;
    _currentPage++;
    await fetchKunjungan(status: status);
  }

  Future<KunjunganModel> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('kunjungan/$id');
    final json = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    return KunjunganModel.fromJson(json);
  }

  Future<KunjunganModel> createKunjungan(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.post('kunjungan', body: data);
    await fetchKunjungan(refresh: true);
    return KunjunganModel.fromJson(response['data'] ?? response);
  }

  Future<KunjunganModel> createKunjunganMultipart({
    required Map<String, String> fields,
    List<String>? lampiran,
  }) async {
    final api = ApiService(token: _token);
    final response = await api.postMultipart(
      'kunjungan',
      fields: fields,
      fileListPaths: lampiran != null ? {'lampiran[]': lampiran} : null,
    );
    await fetchKunjungan(refresh: true);
    return KunjunganModel.fromJson(response['data'] ?? response);
  }

  Future<void> approveKunjungan(int id) async {
    final api = ApiService(token: _token);
    await api.post('kunjungan/$id/approve');
    await fetchKunjungan(refresh: true);
  }

  Future<void> cancelKunjungan(int id) async {
    final api = ApiService(token: _token);
    await api.post('kunjungan/$id/cancel');
    await fetchKunjungan(refresh: true);
  }

  Future<void> uncancelKunjungan(int id) async {
    final api = ApiService(token: _token);
    await api.post('kunjungan/$id/uncancel');
    await fetchKunjungan(refresh: true);
  }

  Future<void> updateKunjungan(int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.put('kunjungan/$id', body: data);
    await fetchKunjungan(refresh: true);
  }
}
