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

  Future<void> fetchKontak({String? search, bool all = false}) async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: _token);
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;

      if (all) {
        _items = await _fetchAllKontak(api, params);
      } else {
        final response = await api.get('kontak', params: params);
        _items = _parseKontakList(response);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<KontakModel>> _fetchAllKontak(
    ApiService api,
    Map<String, String> baseParams,
  ) async {
    const maxPages = 1000;
    final allItems = <int, KontakModel>{};
    var page = 1;
    var lastPage = 1;

    do {
      final response = await api.get(
        'kontak',
        params: {
          ...baseParams,
          'page': page.toString(),
        },
      );

      for (final item in _parseKontakList(response)) {
        allItems[item.id] = item;
      }

      final currentPage = _extractPageValue(response, 'current_page') ?? page;
      lastPage = _extractPageValue(response, 'last_page') ?? currentPage;
      final nextPage = currentPage + 1;
      if (nextPage <= page) break;
      page = nextPage;
    } while (page <= lastPage && page <= maxPages);

    return allItems.values.toList();
  }

  List<KontakModel> _parseKontakList(dynamic response) {
    final data = _extractList(response);
    final parsed = <KontakModel>[];

    for (final item in data) {
      if (item is Map) {
        parsed.add(KontakModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return parsed;
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is! Map) return const [];

    final data = response['data'];
    if (data is List) return data;
    if (data is Map) {
      final nestedData = data['data'];
      if (nestedData is List) return nestedData;
    }

    return const [];
  }

  int? _extractPageValue(dynamic response, String key) {
    final directValue = _readIntFromMap(response, key);
    if (directValue != null) return directValue;

    if (response is Map) {
      final dataValue = _readIntFromMap(response['data'], key);
      if (dataValue != null) return dataValue;

      final metaValue = _readIntFromMap(response['meta'], key);
      if (metaValue != null) return metaValue;
    }

    return null;
  }

  int? _readIntFromMap(dynamic value, String key) {
    if (value is! Map) return null;
    return _parseInt(value[key]);
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
