import 'package:flutter/foundation.dart';
import '../models/produk_model.dart';
import '../services/api_service.dart';

class GudangProvider with ChangeNotifier {
  String? _token;
  List<GudangModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<GudangModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchGudang() async {
    if (_token == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final response = await api.get('gudang');
      final List data = response is List ? response : (response['data'] ?? []);
      _items = data.map((e) => GudangModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchGudang(int gudangId) async {
    final api = ApiService(token: _token);
    await api.post('gudang/switch', body: {'gudang_id': gudangId});
  }

  Future<void> createGudang(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.post('gudang', body: data);
    await fetchGudang();
  }

  Future<void> updateGudang(int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.put('gudang/$id', body: data);
    await fetchGudang();
  }

  Future<void> deleteGudang(int id) async {
    final api = ApiService(token: _token);
    await api.delete('gudang/$id');
    _items.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<List<StokModel>> fetchStok({int? gudangId}) async {
    final api = ApiService(token: _token);
    final params = <String, String>{};
    if (gudangId != null) params['gudang_id'] = gudangId.toString();
    final response = await api.get('gudang/stok', params: params);
    final List data = _extractList(response);
    return data.map((e) => StokModel.fromJson(e)).toList();
  }

  List _extractList(dynamic response) {
    if (response is List) return response;
    if (response is! Map) return [];

    final data = response['data'];
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
      if (data['rows'] is List) return data['rows'] as List;
    }

    if (response['items'] is List) return response['items'] as List;
    if (response['rows'] is List) return response['rows'] as List;
    return [];
  }
}
