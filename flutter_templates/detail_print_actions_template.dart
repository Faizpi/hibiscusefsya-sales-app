import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DetailPrintApi {
  final String apiBaseUrl; // contoh: https://domain.com/api/v1
  final String webBaseUrl; // contoh: https://domain.com
  final Future<String?> Function() getToken;

  DetailPrintApi({
    required this.apiBaseUrl,
    required this.webBaseUrl,
    required this.getToken,
  });

  Future<Map<String, dynamic>> getQrData({
    required String type,
    required int id,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$apiBaseUrl/print/$type/$id/qr');

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Gagal ambil QR data (${res.statusCode}): ${res.body}');
  }

  Future<Map<String, dynamic>> getBluetoothData({
    required String type,
    required int id,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$apiBaseUrl/print/$type/$id/bluetooth');

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Gagal ambil bluetooth data (${res.statusCode}): ${res.body}',
    );
  }

  Uri buildWebPrintUri({required String type, required int id}) {
    // Fallback jika masih pakai endpoint print web lama.
    // Catatan: endpoint ini butuh session login web, bukan bearer API.
    return Uri.parse('$webBaseUrl/$type/$id/print');
  }

  Future<void> openPublicInvoice(String invoiceUrl) async {
    final uri = Uri.parse(invoiceUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak bisa membuka invoice URL');
    }
  }
}

class DetailActionButtonConfig {
  final bool showPrint;
  final bool showBluetooth;
  final bool showQr;

  const DetailActionButtonConfig({
    required this.showPrint,
    required this.showBluetooth,
    required this.showQr,
  });

  factory DetailActionButtonConfig.fromRole(String role) {
    // Semua role boleh lihat tombol ini, selama datanya bisa diakses.
    // Backend tetap jadi source-of-truth jika unauthorized.
    return const DetailActionButtonConfig(
      showPrint: true,
      showBluetooth: true,
      showQr: true,
    );
  }
}
