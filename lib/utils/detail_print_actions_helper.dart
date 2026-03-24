// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/print_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';

class DetailPrintActionsHelper {
  static List<Widget> buildAppBarActions({
    required BuildContext context,
    required String type,
    required int id,
    required bool bluetoothSupported,
  }) {
    return [
      IconButton(
        tooltip: 'Cetak Struk',
        icon: const Icon(Icons.receipt_long),
        onPressed: () => openReceipt(context, type: type, id: id),
      ),
      IconButton(
        tooltip: bluetoothSupported
            ? 'Print Bluetooth'
            : 'Bluetooth belum didukung untuk tipe ini',
        icon: const Icon(Icons.bluetooth),
        onPressed: bluetoothSupported
            ? () => printBluetooth(context, type: type, id: id)
            : null,
      ),
      IconButton(
        tooltip: 'QR Code Invoice',
        icon: const Icon(Icons.qr_code),
        onPressed: () => showQrDialog(context, type: type, id: id),
      ),
    ];
  }

  static Future<void> showQrDialog(
    BuildContext context, {
    required String type,
    required int id,
  }) async {
    try {
      final payload = await _getQrPayload(context, type: type, id: id);
      if (payload == null) return;

      final qr = payload['qr']!;
      final invoiceUrl = payload['invoiceUrl'];

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withAlpha(60),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: GlassContainer(
              variant: GlassVariant.modal,
              borderRadius: 28,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: AppTheme.mainGradient(context),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: AppTheme.elevatedShadow,
                          ),
                          child: const Icon(Icons.qr_code_2,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QR Code Invoice',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2),
                              ),
                              Text(
                                'Scan untuk lihat detail invoice publik',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(180)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(16),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: QrImageView(
                          data: qr,
                          size: 220,
                          version: QrVersions.auto,
                        ),
                      ),
                    ),
                    if (invoiceUrl != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context).withAlpha(210),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.borderColorOf(context)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                invoiceUrl,
                                style:
                                    const TextStyle(fontSize: 12, height: 1.3),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy URL',
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: invoiceUrl));
                                if (!context.mounted) return;
                                _snack(context, 'URL invoice disalin');
                              },
                              icon: const Icon(
                                Icons.content_copy_rounded,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tutup'),
                          ),
                        ),
                        if (invoiceUrl != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _openUrl(context, invoiceUrl);
                              },
                              icon: const Icon(Icons.open_in_new_rounded,
                                  size: 18),
                              label: const Text('Open Invoice'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      _handleError(context, e, fallback: 'Gagal memuat QR invoice.');
    }
  }

  static Future<void> openReceipt(
    BuildContext context, {
    required String type,
    required int id,
  }) async {
    try {
      final payload = await _getQrPayload(context, type: type, id: id);
      if (payload == null) return;
      final receiptUrl = payload['receiptUrl'];
      final invoiceUrl = payload['invoiceUrl'];
      final targetUrl = receiptUrl ?? invoiceUrl;
      if (targetUrl == null || targetUrl.isEmpty) {
        _snack(context, 'Invoice URL tidak tersedia untuk struk.',
            isError: true);
        return;
      }
      await _openUrl(context, targetUrl);
    } catch (e) {
      _handleError(context, e, fallback: 'Gagal membuka struk invoice.');
    }
  }

  static Future<void> printBluetooth(
    BuildContext context, {
    required String type,
    required int id,
  }) async {
    try {
      final service = await _serviceFromContext(context);
      if (service == null) return;

      final response = await service.getBluetoothData(type: type, id: id);
      final data = _unwrapData(response);
      await _printViaBluetoothDevicePicker(context, data);
    } catch (e) {
      _handleError(context, e, fallback: 'Gagal memuat data print Bluetooth.');
    }
  }

  static Future<void> _printViaBluetoothDevicePicker(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final granted = await _ensureBluetoothPermissions();
    if (!granted) {
      _snack(context, 'Izin bluetooth belum diberikan.', isError: true);
      return;
    }

    final bt = FlutterBluetoothSerial.instance;
    final enabled = await bt.isEnabled ?? false;
    if (!enabled) {
      final enabledNow = await bt.requestEnable() ?? false;
      if (!enabledNow) {
        _snack(context, 'Bluetooth harus aktif untuk print.', isError: true);
        return;
      }
    }

    final bondedDevices = await bt.getBondedDevices();
    if (bondedDevices.isEmpty) {
      _snack(
        context,
        'Tidak ada printer paired. Pair printer dulu di pengaturan Bluetooth HP.',
        isError: true,
      );
      return;
    }

    if (!context.mounted) return;
    final selected = await showModalBottomSheet<BluetoothDevice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Pilih Printer Bluetooth',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...bondedDevices.map(
              (d) => ListTile(
                leading: const Icon(Icons.print),
                title: Text(d.name ?? 'Unnamed Device'),
                subtitle: Text(d.address),
                onTap: () => Navigator.pop(ctx, d),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected == null) return;
    final bytes = await _buildEscPosBytes(data);

    BluetoothConnection? connection;
    try {
      connection = await BluetoothConnection.toAddress(selected.address);
      connection.output.add(Uint8List.fromList(bytes));
      await connection.output.allSent;
      if (!context.mounted) return;
      _snack(context,
          'Berhasil kirim data ke ${selected.name ?? selected.address}');
    } catch (e) {
      _snack(context, 'Gagal print bluetooth: $e', isError: true);
    } finally {
      await connection?.finish();
    }
  }

  static Future<bool> _ensureBluetoothPermissions() async {
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    return connect.isGranted && scan.isGranted;
  }

  static Future<List<int>> _buildEscPosBytes(Map<String, dynamic> data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(
      'Hibiscus Efsya',
      styles: const PosStyles(
          align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    bytes.addAll(generator.hr());

    final lines = _flattenForReceipt(data);
    for (final line in lines) {
      bytes.addAll(
          generator.text(line, styles: const PosStyles(align: PosAlign.left)));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      'Terima kasih',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  static List<String> _flattenForReceipt(Map<String, dynamic> data) {
    final lines = <String>[];

    void walk(String prefix, dynamic value) {
      if (value == null) return;
      if (value is Map<String, dynamic>) {
        value.forEach((k, v) {
          final key = prefix.isEmpty ? k : '$prefix.$k';
          walk(key, v);
        });
        return;
      }
      if (value is Map) {
        value.forEach((k, v) {
          final key = prefix.isEmpty ? k.toString() : '$prefix.${k.toString()}';
          walk(key, v);
        });
        return;
      }
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          walk('$prefix[$i]', value[i]);
        }
        return;
      }
      if (prefix.isNotEmpty) {
        lines.add('$prefix: ${value.toString()}');
      }
    }

    walk('', data);
    return lines.take(120).toList();
  }

  static Future<Map<String, String>?> _getQrPayload(
    BuildContext context, {
    required String type,
    required int id,
  }) async {
    final service = await _serviceFromContext(context);
    if (service == null) return null;

    final response = await service.getQrData(type: type, id: id);
    final data = _unwrapData(response);

    final qr = _findString(data, 'qr_payload') ??
        _findString(data, 'qr') ??
        _findString(data, 'qr_code') ??
        _findString(data, 'qr_data') ??
        _findString(data, 'qrcode') ??
        _findString(data, 'invoice_url') ??
        _findString(response, 'qr_payload') ??
        _findString(response, 'qr') ??
        _findString(response, 'qr_code');
    final invoiceUrl = _findString(data, 'invoice_url') ??
        _findString(data, 'public_url') ??
        _findString(data, 'url') ??
        _findString(response, 'invoice_url') ??
        _findString(response, 'public_url');
    final receiptUrl = _findString(data, 'receipt_url') ??
        _findString(data, 'struk_url') ??
        _findString(response, 'receipt_url') ??
        _findString(response, 'struk_url');

    if (qr == null || qr.trim().isEmpty) {
      _snack(context, 'QR payload tidak ditemukan.', isError: true);
      return null;
    }

    return {
      'qr': qr,
      if (receiptUrl != null && receiptUrl.isNotEmpty) 'receiptUrl': receiptUrl,
      if (invoiceUrl != null && invoiceUrl.isNotEmpty) 'invoiceUrl': invoiceUrl,
    };
  }

  static Future<PrintService?> _serviceFromContext(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if ((auth.token ?? '').isEmpty) {
      _snack(context, 'Sesi login tidak valid. Silakan login ulang.',
          isError: true);
      return null;
    }
    return PrintService(token: auth.token);
  }

  static Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return response;
  }

  static String? _findString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is num || value is bool) return value.toString();
    if (value is Map || value is List) {
      final encoded = jsonEncode(value);
      if (encoded.trim().isNotEmpty) return encoded;
    }

    for (final entry in data.entries) {
      final nested = entry.value;
      if (nested is Map<String, dynamic>) {
        final found = _findString(nested, key);
        if (found != null) return found;
      } else if (nested is Map) {
        final map = nested.map((k, v) => MapEntry(k.toString(), v));
        final found = _findString(map, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  static Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final trimmed = rawUrl.trim();
    final candidate =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';

    final uri = Uri.tryParse(candidate);
    if (uri == null) {
      _snack(context, 'URL invoice tidak valid.', isError: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _snack(context, 'Gagal membuka invoice URL.', isError: true);
    }
  }

  static void _handleError(BuildContext context, Object e,
      {required String fallback}) {
    if (e is ApiException) {
      if (e.statusCode == 401) {
        _snack(context, 'Sesi habis. Silakan login ulang.', isError: true);
        return;
      }
      if (e.statusCode == 403) {
        _snack(context, 'Anda tidak punya akses ke data ini.', isError: true);
        return;
      }
      if (e.statusCode == 400) {
        _snack(context, e.message, isError: true);
        return;
      }
      _snack(context, e.message, isError: true);
      return;
    }
    _snack(context, fallback, isError: true);
  }

  static void _snack(BuildContext context, String message,
      {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
