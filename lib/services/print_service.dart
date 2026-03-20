import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PrintService {
  final String? token;

  PrintService({required this.token});

  Future<Map<String, dynamic>> getQrData({
    required String type,
    required int id,
  }) async {
    final api = ApiService(token: token);
    final response = await api.get('print/$type/$id/qr');
    return _asMap(response);
  }

  Future<Map<String, dynamic>> getBluetoothData({
    required String type,
    required int id,
  }) async {
    final api = ApiService(token: token);
    final response = await api.get('print/$type/$id/bluetooth');
    return _asMap(response);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    throw ApiException(
      'Format response print tidak valid.',
      statusCode: kDebugMode ? 500 : null,
    );
  }
}
