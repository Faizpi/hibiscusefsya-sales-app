import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  String? _token;
  List<dynamic> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  List<dynamic> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _lastPage;

  void updateToken(String? token) {
    _token = token;
  }

  Future<void> fetchUsers(
      {String? role, String? search, bool refresh = false}) async {
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
      if (role != null) params['role'] = role;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await api.get('users', params: params);
      final List data = response['data'] ?? [];

      if (refresh) {
        _items = data;
      } else {
        _items.addAll(data);
      }
      _currentPage = response['current_page'] ?? 1;
      _lastPage = response['last_page'] ?? 1;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore({String? role, String? search}) async {
    if (!hasMore || _isLoading) return;
    _currentPage++;
    await fetchUsers(role: role, search: search);
  }

  Future<Map<String, dynamic>> getDetail(int id) async {
    final api = ApiService(token: _token);
    final response = await api.get('users/$id');
    return response;
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.post('users', body: data);
    await fetchUsers(refresh: true);
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final api = ApiService(token: _token);
    await api.put('users/$id', body: data);
    await fetchUsers(refresh: true);
  }

  Future<void> deleteUser(int id) async {
    final api = ApiService(token: _token);
    await api.delete('users/$id');
    _items.removeWhere((e) => e['id'] == id);
    notifyListeners();
  }

  Future<void> resetPassword(int id) async {
    final api = ApiService(token: _token);
    await api.post('users/$id/reset-password');
  }
}
