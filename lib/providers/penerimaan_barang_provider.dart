import 'package:flutter/foundation.dart';
import '../models/penerimaan_barang_model.dart';
import '../services/api_service.dart';

class PenerimaanBarangProvider with ChangeNotifier {
  String? _token;
  List<PenerimaanBarangModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  List<PenerimaanBarangModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchPenerimaan({String? status, bool refresh = false}) async {
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

      final response = await api.get('penerimaan-barang', params: params);
      final List data = response['data'] ?? [];
      final newItems =
          data.map((e) => PenerimaanBarangModel.fromJson(e)).toList();

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
    await fetchPenerimaan(status: status);
  }

  Future<PenerimaanBarangModel> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('penerimaan-barang/$id');
    final json = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    return PenerimaanBarangModel.fromJson(json);
  }

  Future<List<dynamic>> getPembelianByGudang(int gudangId) async {
    final api = ApiService(token: _token);
    final response =
        await api.get('penerimaan-barang/pembelian-by-gudang/$gudangId');
    return response is List ? response : [];
  }

  Future<Map<String, dynamic>> getPembelianDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('penerimaan-barang/pembelian-detail/$id');
    return response;
  }

  Future<PenerimaanBarangModel> createPenerimaan(
      Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    final response = await api.post('penerimaan-barang', body: data);
    final penerimaan = PenerimaanBarangModel.fromJson(response['data']);
    _items.insert(0, penerimaan);
    notifyListeners();
    return penerimaan;
  }

  Future<PenerimaanBarangModel> createPenerimaanMultipart({
    required Map<String, String> fields,
    List<String>? lampiran,
  }) async {
    final api = ApiService(token: _token);
    final response = await api.postMultipart(
      'penerimaan-barang',
      fields: fields,
      fileListPaths: lampiran != null ? {'lampiran[]': lampiran} : null,
    );
    final penerimaan = PenerimaanBarangModel.fromJson(response['data']);
    _items.insert(0, penerimaan);
    notifyListeners();
    return penerimaan;
  }

  Future<void> approvePenerimaan(int id) async {
    final api = ApiService(token: _token);
    await api.post('penerimaan-barang/$id/approve');
    await fetchPenerimaan(refresh: true);
  }

  Future<void> cancelPenerimaan(int id) async {
    final api = ApiService(token: _token);
    await api.post('penerimaan-barang/$id/cancel');
    await fetchPenerimaan(refresh: true);
  }
}
