import 'package:flutter/foundation.dart';
import '../models/kontak_model.dart';
import '../services/api_service.dart';

class KontakProvider with ChangeNotifier {
  String? _token;
  List<KontakModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<KontakModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchKontak({String? search}) async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await api.get('kontak', params: params);
      final List data = response['data'] ?? [];
      _items = data.map((e) => KontakModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<KontakModel> createKontak(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.post('kontak', body: data);
    final kontak = KontakModel.fromJson(response['data']);
    _items.insert(0, kontak);
    notifyListeners();
    return kontak;
  }

  Future<KontakModel> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('kontak/$id');
    final json = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    return KontakModel.fromJson(json);
  }

  Future<void> updateKontak(int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.put('kontak/$id', body: data);
    await fetchKontak();
  }

  Future<void> deleteKontak(int id) async {
    final api = ApiService(token: _token);
    await api.delete('kontak/$id');
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
