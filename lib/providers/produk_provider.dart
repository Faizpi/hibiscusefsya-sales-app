import 'package:flutter/foundation.dart';
import '../models/produk_model.dart';
import '../services/api_service.dart';

class ProdukProvider with ChangeNotifier {
  String? _token;
  List<ProdukModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ProdukModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchProduk({String? search}) async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await api.get('produk', params: params);
      final List data = response['data'] ?? [];
      _items = data.map((e) => ProdukModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('produk/$id');
    return response;
  }

  Future<void> createProduk(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.post('produk', body: data);
    await fetchProduk();
  }

  Future<void> updateProduk(int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.put('produk/$id', body: data);
    await fetchProduk();
  }

  Future<void> deleteProduk(int id) async {
    final api = ApiService(token: _token);
    await api.delete('produk/$id');
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
