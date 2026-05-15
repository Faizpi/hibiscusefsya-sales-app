// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'dart:io' as io;

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/print_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/camera_lampiran_capture_screen.dart';

class DetailPrintActionsHelper {
  static Future<CapabilityProfile>? _capabilityProfileFuture;

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

  static Future<void> uploadLampiran(
    BuildContext context, {
    required String type,
    required int id,
  }) async {
    final result = await Navigator.push<CameraLampiranResult>(
      context,
      MaterialPageRoute(builder: (_) => const CameraLampiranCaptureScreen()),
    );
    if (result == null || !context.mounted) return;
    final file = io.File(result.imagePath);
    final sizeInBytes = await file.length();
    if (sizeInBytes > 2 * 1024 * 1024) {
      if (!context.mounted) return;
      _snack(context,
          'Ukuran foto terlalu besar (${(sizeInBytes / 1024 / 1024).toStringAsFixed(1)} MB). Maksimal 2MB.',
          isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if ((auth.token ?? '').isEmpty) {
        Navigator.pop(context);
        _snack(context, 'Sesi login tidak valid.', isError: true);
        return;
      }

      final api = ApiService(token: auth.token);
      await api.postMultipart(
        '$type/$id',
        fields: {
          '_method': 'PUT',
        },
        fileListPaths: {
          'lampiran[]': [result.imagePath]
        },
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading
      _snack(context, 'Lampiran berhasil ditambahkan!');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading
      _handleError(context, e, fallback: 'Gagal menambah lampiran.');
    }
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
      // Langkah 1: Pilih ukuran kertas
      if (!context.mounted) return;
      final paperSize = await _showPaperSizeDialog(context);
      if (paperSize == null) return;

      final service = await _serviceFromContext(context);
      if (service == null) return;

      final response = await service.getBluetoothData(type: type, id: id);
      final data = _unwrapData(response);
      final invoiceUrl = _resolveInvoiceUrl(data, fallback: response);

      final printData = {
        ...data,
        'type': type,
        '_source_type': type,
        '_source_id': id,
        'paper_size': paperSize, // '58mm' atau '80mm'
        if (invoiceUrl.isNotEmpty) '_invoice_url': invoiceUrl,
      };

      if (!context.mounted) return;
      final proceed = await _showPreviewDialog(context, printData);
      if (proceed != true) return;

      if (!context.mounted) return;
      await _printViaBluetoothDevicePicker(
        context,
        printData,
      );
    } catch (e) {
      _handleError(context, e, fallback: 'Gagal memuat data print Bluetooth.');
    }
  }

  /// Dialog pilih ukuran kertas thermal printer
  static Future<String?> _showPaperSizeDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.straighten_rounded,
                        color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ukuran Kertas Printer',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Pilih sesuai printer Bluetooth Anda',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _PaperSizeOption(
                label: '58 mm',
                subtitle: 'Printer kecil / standar',
                icon: Icons.receipt_outlined,
                onTap: () => Navigator.pop(ctx, '58mm'),
              ),
              const SizedBox(height: 10),
              _PaperSizeOption(
                label: '80 mm',
                subtitle: 'Printer lebar / kasir',
                icon: Icons.receipt_long_outlined,
                onTap: () => Navigator.pop(ctx, '80mm'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal',
                    style: TextStyle(color: Color(0xFF888888))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> _showPreviewDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final title = _receiptTitle(data);
    final paperSizeKey = _stringValue(data['paper_size']);
    final is80mm = paperSizeKey == '80mm';
    // Preview width: 80mm ≈ 380px, 58mm ~ narrower
    // For 58mm use dynamic width to match screen
    final lines = _buildReceiptLines(data);

    // Build preview line widgets – mirrors ESC/POS layout visually
    final previewWidgets = <Widget>[];

    final double fontSize = is80mm ? 11.5 : 10.0;
    final mono = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: fontSize,
      color: const Color(0xFF1A1A1A),
      height: 1.45,
      letterSpacing: 0.1,
    );
    final monoCenter = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: fontSize,
      color: const Color(0xFF1A1A1A),
      height: 1.45,
      letterSpacing: 0.1,
    );
    const monoBigBold = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: Color(0xFF1A1A1A),
      height: 1.3,
      letterSpacing: 0.4,
    );
    previewWidgets.add(
      Text('HIBISCUS EFSYA', style: monoBigBold, textAlign: TextAlign.center),
    );
    if (title.isNotEmpty) {
      previewWidgets.add(const SizedBox(height: 2));
      previewWidgets.add(
        Text(title,
            style: monoCenter.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
      );
    }
    previewWidgets.add(const SizedBox(height: 6));
    previewWidgets.add(
        Text('-' * 150, style: mono, maxLines: 1, overflow: TextOverflow.clip));
    previewWidgets.add(const SizedBox(height: 4));

    for (final line in lines) {
      if (line == null) {
        previewWidgets.add(const SizedBox(height: 6));
      } else if (line == '---HR---') {
        previewWidgets.add(const SizedBox(height: 4));
        previewWidgets.add(Text('-' * 150,
            style: mono, maxLines: 1, overflow: TextOverflow.clip));
        previewWidgets.add(const SizedBox(height: 4));
      } else if (line.startsWith(' R:')) {
        // Baris lanjutan rata kanan (wrap dari _rightAlignLines)
        previewWidgets.add(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              line.substring(3),
              style: mono,
              textAlign: TextAlign.right,
            ),
          ),
        );
      } else {
        final match = RegExp(r'^(.+?)\s{2,}(.+)$').firstMatch(line);
        if (match != null) {
          previewWidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.group(1)!, style: mono),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    match.group(2)!,
                    style: mono,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        } else {
          previewWidgets.add(Text(line, style: mono));
        }
      }
    }

    previewWidgets.add(const SizedBox(height: 4));
    previewWidgets.add(
        Text('-' * 150, style: mono, maxLines: 1, overflow: TextOverflow.clip));
    previewWidgets.add(SizedBox(height: is80mm ? 10 : 6));
    final footerFontSize = is80mm ? 9.5 : 8.5;
    final footerMono = monoCenter.copyWith(fontSize: footerFontSize);
    final footerMuted = footerMono.copyWith(color: const Color(0xFF555555));

    // Teks promosi
    previewWidgets.add(
      Text(
        'Periksa Invoice & Ambil Promo !',
        style: footerMono.copyWith(
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
    previewWidgets.add(const SizedBox(height: 6));
    // Garis putus-putus pemisah sebelum QR
    previewWidgets.add(
      Text('- ' * 20,
          style: mono.copyWith(
            color: const Color(0xFF999999),
            fontSize: footerFontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center),
    );
    previewWidgets.add(const SizedBox(height: 6));
    // QR Code website pelanggan
    previewWidgets.add(
      Center(
        child: QrImageView(
          data: 'https://customer.hibiscusefsya.com/',
          size: is80mm ? 110 : 94,
          version: QrVersions.auto,
          backgroundColor: Colors.white,
        ),
      ),
    );
    previewWidgets.add(const SizedBox(height: 6));
    previewWidgets.add(
      Text('customer.hibiscusefsya.com',
          style: footerMuted, textAlign: TextAlign.center),
    );
    previewWidgets.add(const SizedBox(height: 4));
    // Garis putus-putus pemisah setelah QR
    previewWidgets.add(
      Text('- ' * 20,
          style: mono.copyWith(
            color: const Color(0xFF999999),
            fontSize: footerFontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center),
    );
    previewWidgets.add(const SizedBox(height: 6));
    previewWidgets.add(
      Text('marketing@hibiscusefsya.com',
          style: footerMono, textAlign: TextAlign.center),
    );
    previewWidgets.add(const SizedBox(height: 6));
    previewWidgets.add(
      Text(
        'Official WA Chat:\n${_formatPhone("+6285195550202")}',
        style: footerMono,
        textAlign: TextAlign.center,
      ),
    );
    previewWidgets.add(const SizedBox(height: 8));
    previewWidgets.add(
      Text('Terima kasih',
          style: footerMono.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
    );
    previewWidgets.add(const SizedBox(height: 12));

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final maxH = media.size.height * 0.85;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Sheet card
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header bar
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 18, color: Color(0xFF555555)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Preview Struk',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Batal',
                                      style:
                                          TextStyle(color: Color(0xFF888888))),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          const Divider(height: 1),
                          // Receipt paper area
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: LayoutBuilder(
                                  builder: (lbCtx, constraints) {
                                    final maxPaperWidth =
                                        is80mm ? 380.0 : 276.0;
                                    final paperWidth = maxPaperWidth.clamp(
                                        0.0, constraints.maxWidth - 16);
                                    return Container(
                                      width: paperWidth,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(20),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        // Torn-paper top edge
                                        children: [
                                          // Top jagged edge simulation
                                          CustomPaint(
                                            size:
                                                const Size(double.infinity, 10),
                                            painter:
                                                _TornEdgePainter(isTop: true),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: is80mm ? 12 : 8,
                                                vertical: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: previewWidgets,
                                            ),
                                          ),
                                          // Bottom jagged edge
                                          CustomPaint(
                                            size:
                                                const Size(double.infinity, 10),
                                            painter:
                                                _TornEdgePainter(isTop: false),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Action buttons
                          Container(height: 1, color: const Color(0xFFE0E0E0)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  icon: const Icon(Icons.print_outlined),
                                  label: const Text('Pilih Printer Bluetooth'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                Builder(builder: (btnCtx) {
                                  final noTelepon = _resolveCustomerPhone(data);
                                  if (noTelepon.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      // Tombol WhatsApp dengan logo official
                                      Material(
                                        color: const Color(0xFF25D366),
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () async {
                                            Navigator.pop(ctx, false);
                                            await _shareInvoiceViaWhatsApp(
                                                context, data);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 13, horizontal: 16),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const FaIcon(
                                                  FontAwesomeIcons.whatsapp,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                const Text(
                                                  'Kirim Invoice ke WhatsApp',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(100),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Icon(Icons.print_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Pilih Printer Bluetooth',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...bondedDevices.map(
                      (d) => ListTile(
                        leading: const Icon(Icons.bluetooth_outlined),
                        title: Text(d.name ?? 'Unnamed Device'),
                        subtitle: Text(d.address,
                            style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => Navigator.pop(ctx, d),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
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
      _snack(context,
          'Gagal print bluetooth. Pastikan printer menyala & terhubung.',
          isError: true);
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
    final profile =
        await (_capabilityProfileFuture ??= CapabilityProfile.load());
    final is80mm = _stringValue(data['paper_size']) == '80mm';
    final generator =
        Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    bytes.addAll(generator.text(
      'HIBISCUS EFSYA',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    final title = _receiptTitle(data);
    if (title.isNotEmpty) {
      bytes.addAll(generator.text(
        title,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ));
    }
    bytes.addAll(generator.hr());

    final lines = _buildReceiptLines(data);
    for (final line in lines) {
      if (line == null) {
        bytes.addAll(generator.feed(1));
        continue;
      }
      if (line == '---HR---') {
        bytes.addAll(generator.hr());
        continue;
      }
      if (line.startsWith('\x00R:')) {
        bytes.addAll(generator.text(
          line.substring(3),
          styles: const PosStyles(align: PosAlign.right),
        ));
        continue;
      }
      bytes.addAll(generator.text(
        line,
        styles: const PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'Periksa Invoice & Ambil Promo !',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        fontType: PosFontType.fontB,
      ),
    ));
    bytes.addAll(generator.feed(1));
    // Garis putus-putus pemisah sebelum QR
    final dashLine = '- ' * (is80mm ? 24 : 16);
    bytes.addAll(generator.text(
      dashLine,
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    ));
    bytes.addAll(generator.feed(1));
    // QR Code website pelanggan
    bytes.addAll(generator.qrcode(
      'https://customer.hibiscusefsya.com/',
      size: is80mm ? QRSize.size7 : QRSize.size6,
    ));
    bytes.addAll(generator.feed(1));
    // Garis putus-putus pemisah setelah QR
    bytes.addAll(generator.text(
      dashLine,
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    ));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'marketing@hibiscusefsya.com',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    ));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'Official WA Chat:\n${_formatPhone("+6285195550202")}',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    ));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'Terima kasih',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    ));
    bytes.addAll(generator.feed(is80mm ? 3 : 2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  static String _receiptTitle(Map<String, dynamic> data) {
    final type = _stringValue(data['type']).toLowerCase();
    if (type.contains('penjualan')) return 'INVOICE PENJUALAN';
    if (type.contains('kunjungan')) return 'STRUK KUNJUNGAN';
    if (type.contains('pembelian')) return 'INVOICE PEMBELIAN';
    if (type.contains('biaya')) return 'STRUK BIAYA';
    return 'STRUK';
  }

  static int _currentPrintWidth = 32;

  static List<String?> _buildReceiptLines(Map<String, dynamic> data) {
    _currentPrintWidth = _stringValue(data['paper_size']) == '80mm' ? 48 : 32;
    final type = _stringValue(data['type']).toLowerCase();
    if (type.contains('penjualan')) return _buildPenjualanLines(data);
    if (type.contains('kunjungan')) return _buildKunjunganLines(data);
    if (type.contains('pembelian')) return _buildPembelianLines(data);
    if (type.contains('biaya')) return _buildBiayaLines(data);
    return _buildGenericLines(data);
  }

  static List<String?> _buildPenjualanLines(Map<String, dynamic> data) {
    final lines = <String?>[];
    lines.addAll([
      _kvLine('Nomor', _stringValue(data['nomor'])),
      _kvLine('Tanggal', _stringValue(data['tanggal'])),
      _kvLine('Jatuh Tempo', _stringValue(data['jatuh_tempo'])),
      _kvLine('Pembayaran', _stringValue(data['pembayaran'])),
      _kvLine('Pelanggan', _limitReceiptText(data['pelanggan'])),
      // Selalu tampilkan No. Telepon, N/A jika kosong
      _kvLine(
          'No. Telepon',
          _stringValue(data['no_telepon']).isNotEmpty
              ? _formatPhone(data['no_telepon'])
              : 'N/A'),
      _kvLine('Sales', _limitReceiptText(data['sales'])),
      // Selalu tampilkan No. Telp Sales, N/A jika kosong
      _kvLine(
          'No. Telp Sales',
          _stringValue(data['sales_no_telp']).isNotEmpty
              ? _formatPhone(data['sales_no_telp'])
              : 'N/A'),
    ]);
    if (_stringValue(data['no_referensi']).isNotEmpty) {
      lines.add(_kvLine('No. Ref', _stringValue(data['no_referensi'])));
    }
    if (_stringValue(data['memo']).isNotEmpty) {
      lines.add(_kvLine('Memo', _stringValue(data['memo'])));
    }
    lines.add('---HR---');

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      lines.add(_wrapText(_itemName(item)));
      // Batch & Exp tetap tampil (N/A jika kosong).
      final rawBatch = _stringValue(item['batch']).isNotEmpty
          ? _stringValue(item['batch'])
          : _stringValue(item['batch_number']);
      final batchVal = rawBatch.isNotEmpty ? rawBatch : 'N/A';
      final rawExp = _stringValue(item['exp']).isNotEmpty
          ? _stringValue(item['exp'])
          : _stringValue(item['expired_date']);
      final expVal = _formatExpDate(rawExp);
      lines.add(_twoColumn('Batch', '$batchVal - $expVal'));
      lines.add(_twoColumn('Qty', _itemQuantityPrice(item)));
      final diskon = _numValue(item['diskon']);
      if (diskon > 0) {
        lines.add(_twoColumn(
            'Diskon', '${diskon.toStringAsFixed(diskon % 1 == 0 ? 0 : 2)}%'));
      }
      final diskonNominal = _numValue(item['diskon_nominal']);
      if (diskonNominal > 0) {
        lines.add(_twoColumn('Disk. Nominal', '- ${_currency(diskonNominal)}'));
      }
      if (_stringValue(item['deskripsi']).isNotEmpty) {
        lines.add(_kvLine('Ket', _stringValue(item['deskripsi'])));
      }
      lines.add(_twoColumn('Jumlah', _currency(_numValue(item['jumlah']))));
      lines.add(null);
    }

    if (lines.isNotEmpty && lines.last == null) {
      lines.removeLast();
    }
    lines.add('---HR---');

    lines.addAll([
      _twoColumn('Subtotal', _currency(_numValue(data['subtotal']))),
      if (_numValue(data['diskon_akhir']) > 0)
        _twoColumn('Diskon', '- ${_currency(_numValue(data['diskon_akhir']))}'),
      if (_numValue(data['pajak']) > 0)
        _twoColumn(
          'Pajak (${_numValue(data['tax_percentage']).toStringAsFixed(_numValue(data['tax_percentage']) % 1 == 0 ? 0 : 2)}%)',
          _currency(_numValue(data['pajak'])),
        ),
      '---HR---',
      _twoColumn('GRAND TOTAL', _currency(_numValue(data['grand_total'])),
          boldRight: true),
    ]);
    return lines;
  }

  static List<String?> _buildKunjunganLines(Map<String, dynamic> data) {
    final lines = <String?>[];
    lines.addAll([
      _kvLine('Nomor', _stringValue(data['nomor'])),
      _kvLine('Tanggal', _stringValue(data['tanggal'])),
      _kvLine('Tujuan', _stringValue(data['tujuan'])),
    ]);
    // Pembuat (user yang login)
    String pembuatNama = _stringValue(data['dibuat_oleh']);
    if (pembuatNama.isEmpty) {
      final user = data['user'];
      if (user is Map) pembuatNama = _stringValue(user['name']);
    }
    if (pembuatNama.isEmpty) pembuatNama = _stringValue(data['pembuat']);
    if (pembuatNama.isNotEmpty) {
      lines.add(_kvLine('Pembuat', _limitReceiptText(pembuatNama)));
    }
    // Pelanggan (dari sales_nama atau kontak nested)
    String pelangganNama = _stringValue(data['sales_nama']);
    if (pelangganNama.isEmpty) {
      final kontak = data['kontak'];
      if (kontak is Map) {
        pelangganNama = _stringValue(kontak['nama']);
      }
      if (pelangganNama.isEmpty) {
        pelangganNama = _stringValue(data['kontak_nama']);
      }
    }
    if (pelangganNama.isNotEmpty) {
      lines.add(_kvLine('Pelanggan', _limitReceiptText(pelangganNama)));
    }
    if (_stringValue(data['sales_no_telepon']).isNotEmpty) {
      lines.add(_kvLine('No. Telepon', _formatPhone(data['sales_no_telepon'])));
    }
    final alamat = _stringValue(data['sales_alamat']);
    if (alamat.isNotEmpty) {
      lines.addAll(_rightAlignLines('Alamat', alamat));
    }
    final koordinat = _stringValue(data['koordinat']);
    if (koordinat.isNotEmpty) {
      lines.addAll(_rightAlignLines('Koordinat', koordinat));
    }
    if (_stringValue(data['memo']).isNotEmpty) {
      lines.add(_kvLine('Memo', _stringValue(data['memo'])));
    }
    lines.add('---HR---');

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      // Nama produk bisa dari nested 'produk' map
      String produkNama = _stringValue(item['nama']);
      if (produkNama.isEmpty) produkNama = _stringValue(item['nama_produk']);
      if (produkNama.isEmpty) {
        final produkMap = item['produk'];
        if (produkMap is Map)
          produkNama = _stringValue(produkMap['nama_produk']);
      }
      if (produkNama.isEmpty) produkNama = '-';
      lines.add(_wrapText(produkNama));

      // Satuan bisa dari nested 'produk' map
      String satuan = _stringValue(item['unit']);
      if (satuan.isEmpty) satuan = _stringValue(item['satuan']);
      if (satuan.isEmpty) {
        final produkMap = item['produk'];
        if (produkMap is Map) satuan = _stringValue(produkMap['satuan']);
      }
      if (satuan.isEmpty) satuan = 'Pcs';

      final qty = _numValue(item['qty'] ?? item['kuantitas']);
      lines.add(_twoColumn(
          'Qty', '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)} $satuan'));

      // Tipe stok
      final tipeStok = _stringValue(item['tipe_stok']);
      if (tipeStok.isNotEmpty) lines.add(_kvLine('Tipe', tipeStok));

      if (_stringValue(item['batch']).isNotEmpty) {
        lines.add(_kvLine('Batch', _stringValue(item['batch'])));
      }
      if (_stringValue(item['batch_number']).isNotEmpty) {
        lines.add(_kvLine('Batch', _stringValue(item['batch_number'])));
      }
      if (_stringValue(item['exp']).isNotEmpty) {
        lines.add(_kvLine('Exp', _stringValue(item['exp'])));
      }
      if (_stringValue(item['expired_date']).isNotEmpty) {
        lines.add(_kvLine('Exp', _stringValue(item['expired_date'])));
      }
      if (_stringValue(item['keterangan']).isNotEmpty) {
        lines.add(_kvLine('Ket', _stringValue(item['keterangan'])));
      }
      lines.add(null);
    }

    if (lines.isNotEmpty && lines.last == null) {
      lines.removeLast();
    }
    return lines;
  }

  static List<String?> _buildPembelianLines(Map<String, dynamic> data) {
    final lines = <String?>[];
    lines.addAll([
      _kvLine('Nomor', _stringValue(data['nomor'])),
      _kvLine('Tanggal', _stringValue(data['tanggal'])),
      _kvLine('Jatuh Tempo', _stringValue(data['jatuh_tempo'])),
      _kvLine('Pembayaran', _stringValue(data['pembayaran'])),
    ]);
    // Urgensi
    if (_stringValue(data['urgensi']).isNotEmpty) {
      lines.add(_kvLine('Urgensi', _stringValue(data['urgensi'])));
    }
    lines.addAll([
      _kvLine('Vendor', _stringValue(data['vendor'])),
      _kvLine('Dibuat oleh', _limitReceiptText(data['sales'])),
    ]);
    if (_stringValue(data['tahun_anggaran']).isNotEmpty) {
      lines.add(_kvLine('Thn Anggaran', _stringValue(data['tahun_anggaran'])));
    }
    if (_stringValue(data['staf_penyetuju']).isNotEmpty) {
      lines
          .add(_kvLine('Staf Penyetuju', _stringValue(data['staf_penyetuju'])));
    }
    if (_stringValue(data['memo']).isNotEmpty) {
      lines.add(_kvLine('Memo', _stringValue(data['memo'])));
    }
    lines.add('---HR---');

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      lines.add(_wrapText(_itemName(item)));
      final rawBatch = _stringValue(item['batch_number']).isNotEmpty
          ? _stringValue(item['batch_number'])
          : _stringValue(item['batch']);
      final batchVal = rawBatch.isNotEmpty ? rawBatch : 'N/A';
      final rawExp = _stringValue(item['expired_date']).isNotEmpty
          ? _stringValue(item['expired_date'])
          : _stringValue(item['exp']);
      final expVal = _formatExpDate(rawExp);
      lines.add(_twoColumn('Batch', '$batchVal - $expVal'));
      lines.add(_twoColumn('Qty', _itemQuantityPrice(item)));
      // Diskon item (bisa dalam % atau nominal)
      final diskonPct = _numValue(item['diskon']);
      if (diskonPct > 0) {
        lines.add(_twoColumn('Diskon',
            '${diskonPct.toStringAsFixed(diskonPct % 1 == 0 ? 0 : 2)}%'));
      }
      if (_stringValue(item['deskripsi']).isNotEmpty) {
        lines.add(_kvLine('Ket', _stringValue(item['deskripsi'])));
      }
      lines.add(_twoColumn('Jumlah', _currency(_numValue(item['jumlah']))));
      lines.add(null);
    }

    if (lines.isNotEmpty && lines.last == null) {
      lines.removeLast();
    }
    lines.add('---HR---');

    lines.addAll([
      _twoColumn('Subtotal', _currency(_numValue(data['subtotal']))),
      if (_numValue(data['diskon_akhir']) > 0)
        _twoColumn('Diskon', '- ${_currency(_numValue(data['diskon_akhir']))}'),
      if (_numValue(data['pajak']) > 0)
        _twoColumn(
          'Pajak (${_numValue(data['tax_percentage']).toStringAsFixed(_numValue(data['tax_percentage']) % 1 == 0 ? 0 : 2)}%)',
          _currency(_numValue(data['pajak'])),
        ),
      '---HR---',
      _twoColumn('GRAND TOTAL', _currency(_numValue(data['grand_total'])),
          boldRight: true),
    ]);
    return lines;
  }

  static List<String?> _buildBiayaLines(Map<String, dynamic> data) {
    final lines = <String?>[];
    lines.addAll([
      _kvLine('Nomor', _stringValue(data['nomor'])),
      _kvLine('Tanggal', _stringValue(data['tanggal'])),
      _kvLine('Jenis Biaya', _stringValue(data['jenis_biaya'])),
      _kvLine('Bayar Dari', _stringValue(data['bayar_dari'])),
    ]);
    if (_stringValue(data['cara_pembayaran']).isNotEmpty) {
      lines.add(_kvLine('Cara Bayar', _stringValue(data['cara_pembayaran'])));
    }
    lines.add(_kvLine('Penerima', _stringValue(data['penerima'])));
    if (_stringValue(data['alamat_penagihan']).isNotEmpty) {
      lines.add(_kvLine('Alamat', _stringValue(data['alamat_penagihan'])));
    }
    lines.addAll([
      _kvLine('Dibuat oleh', _limitReceiptText(data['sales'])),
    ]);
    if (_stringValue(data['tag']).isNotEmpty) {
      lines.add(_kvLine('Tag', _stringValue(data['tag'])));
    }
    if (_stringValue(data['koordinat']).isNotEmpty) {
      lines.add(_kvLine('Koordinat', _stringValue(data['koordinat'])));
    }
    if (_stringValue(data['memo']).isNotEmpty) {
      lines.add(_kvLine('Memo', _stringValue(data['memo'])));
    }
    lines.add('---HR---');

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      lines.add(_wrapText(_stringValue(item['kategori'])));
      if (_stringValue(item['deskripsi']).isNotEmpty) {
        lines.add(_kvLine('Ket', _stringValue(item['deskripsi'])));
      }
      lines.add(_twoColumn('Jumlah', _currency(_numValue(item['jumlah']))));
      lines.add(null);
    }

    if (lines.isNotEmpty && lines.last == null) {
      lines.removeLast();
    }
    lines.add('---HR---');

    // Biaya: tampilkan subtotal + pajak + grand total
    final subtotal = _numValue(data['subtotal']);
    if (subtotal > 0) {
      lines.add(_twoColumn('Subtotal', _currency(subtotal)));
    }
    if (_numValue(data['pajak']) > 0) {
      lines.add(_twoColumn(
        'Pajak (${_numValue(data['tax_percentage']).toStringAsFixed(_numValue(data['tax_percentage']) % 1 == 0 ? 0 : 2)}%)',
        _currency(_numValue(data['pajak'])),
      ));
    }
    lines.add('---HR---');
    lines.add(_twoColumn(
        'GRAND TOTAL', _currency(_numValue(data['grand_total'])),
        boldRight: true));
    return lines;
  }

  static List<String?> _buildGenericLines(Map<String, dynamic> data) {
    final lines = <String?>[];
    data.forEach((key, value) {
      if (key == 'items') return;
      lines.add(
          _kvLine(key.replaceAll('_', ' ').toUpperCase(), _stringValue(value)));
    });
    return lines;
  }

  static String _itemName(Map<String, dynamic> item) {
    final name = _stringValue(item['nama']);
    if (name.isNotEmpty) return name;
    final productName = _stringValue(item['nama_produk']);
    return productName.isNotEmpty ? productName : '-';
  }

  static String _itemQuantityPrice(Map<String, dynamic> item,
      {String? batchVal, String? expVal}) {
    final qty = _numValue(item['qty'] ?? item['kuantitas']);
    final unit = _stringValue(item['unit']).isNotEmpty
        ? _stringValue(item['unit'])
        : (_stringValue(item['satuan']).isNotEmpty
            ? _stringValue(item['satuan'])
            : 'Pcs');
    final harga = _numValue(item['harga'] ?? item['harga_satuan']);
    final qtyText = qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2);
    if (batchVal != null && expVal != null) {
      return '$batchVal - $expVal  $qtyText x ${_currency(harga)}';
    }
    return '$qtyText $unit x ${_currency(harga)}';
  }

  static String _kvLine(String label, String value) {
    return _twoColumn(label, value.isEmpty ? '-' : value);
  }

  static String _twoColumn(String left, String right,
      {bool boldRight = false, int? width}) {
    final int w = width ?? _currentPrintWidth;
    final leftText = left.trim();
    final rightText = right.trim().isEmpty ? '-' : right.trim();
    final available = w - leftText.length - rightText.length;
    if (available <= 1) {
      return '$leftText $rightText';
    }
    return '$leftText${' ' * available}$rightText';
  }

  /// Menghasilkan list baris: baris pertama [label  ...  value_awal],
  /// baris berikutnya (wrap) rata kanan (diisi spasi di kiri).
  static List<String> _rightAlignLines(String label, String value,
      {int? width}) {
    final int w = width ?? _currentPrintWidth;
    final lbl = label.trim();
    final val = value.trim().isEmpty ? '-' : value.trim();
    final maxValWidth = w - lbl.length - 1;

    final chunks = <String>[];
    var remaining = val;
    while (remaining.isNotEmpty) {
      if (remaining.length <= maxValWidth) {
        chunks.add(remaining);
        break;
      }
      int cut = maxValWidth;
      while (cut > 0 && remaining[cut] != ' ') cut--;
      if (cut == 0) cut = maxValWidth;
      chunks.add(remaining.substring(0, cut).trim());
      remaining = remaining.substring(cut).trim();
    }

    final result = <String>[];
    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final pad = w - (i == 0 ? lbl.length + 1 : 0) - chunk.length;
      if (i == 0) {
        // Baris pertama: label kiri, value kanan — pakai 2+ spasi agar regex preview aktif
        result.add('$lbl${' ' * (pad < 2 ? 2 : pad)}$chunk');
      } else {
        // Baris lanjutan: tandai dengan sentinel \x00R: agar preview render rata kanan
        result.add('\x00R:$chunk');
      }
    }
    return result;
  }

  static String _wrapText(String value, {int? width}) {
    final int w = width ?? _currentPrintWidth;
    final text = value.trim();
    if (text.isEmpty) return '';
    if (text.length <= w) return text;

    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if (current.isEmpty) {
        current = word;
        continue;
      }
      if ((current.length + 1 + word.length) <= w) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines.join('\n');
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    return value.toString().trim();
  }

  static String _limitReceiptText(dynamic value, {int max = 20}) {
    final text = _stringValue(value);
    if (text.length <= max) return text;
    if (max <= 3) return text.substring(0, max);
    return '${text.substring(0, max - 3)}...';
  }

  static String _formatPhone(dynamic value) {
    final raw = _stringValue(value);
    if (raw.isEmpty) return '';
    final digitBuffer = StringBuffer();
    for (final codeUnit in raw.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        digitBuffer.writeCharCode(codeUnit);
      }
    }
    var digits = digitBuffer.toString();
    if (digits.isEmpty) return raw;

    if (digits.startsWith('620')) {
      digits = '62${digits.substring(3)}';
    }
    if (digits.startsWith('62')) {
      return '+62 ${_groupPhoneDigits(digits.substring(2))}';
    }
    if (digits.startsWith('0')) {
      return _groupPhoneDigits(digits);
    }
    if (digits.startsWith('8') && digits.length >= 9) {
      return '+62 ${_groupPhoneDigits(digits)}';
    }
    if (raw.startsWith('+')) {
      return '+${_groupPhoneDigits(digits)}';
    }
    return _groupPhoneDigits(digits);
  }

  static String _groupPhoneDigits(String digits) {
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      final end = (i + 4 < digits.length) ? i + 4 : digits.length;
      groups.add(digits.substring(i, end));
    }
    return groups.join('-');
  }

  static num _numValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return 0;
      final cleaned = raw.replaceAll(RegExp(r'[^0-9,.\-]'), '');
      if (cleaned.isEmpty || cleaned == '-') return 0;
      if (cleaned.contains(',')) {
        return num.tryParse(
              cleaned.replaceAll('.', '').replaceAll(',', '.'),
            ) ??
            0;
      }
      final dotGrouped = RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(cleaned);
      if (dotGrouped) return num.tryParse(cleaned.replaceAll('.', '')) ?? 0;
      return num.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  /// Format tanggal expired dari YYYY-MM-DD → DD/MM/YYYY.
  /// Jika kosong atau tidak valid, kembalikan 'N/A'.
  static String _formatExpDate(String raw) {
    if (raw.isEmpty) return 'N/A';
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw; // kembalikan apa adanya jika format tidak dikenal
  }

  static String _currency(num value) {
    final isNeg = value < 0;
    final cents = (value.abs() * 100).round();
    final intPart = cents ~/ 100;
    final fracPart = cents % 100;
    final intStr = intPart.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
    final fracStr = fracPart.toString().padLeft(2, '0');
    return '${isNeg ? '-' : ''}Rp$intStr,$fracStr';
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
      // Untuk 403, tampilkan pesan dari backend (sudah informatif)
      // Misal: 'Unauthorized' atau pesan khusus dari controller
      _snack(
          context,
          e.message.isNotEmpty
              ? e.message
              : 'Anda tidak punya akses ke data ini.',
          isError: true);
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

  // ─────────────────────────────────────────────────────────────────────────────
  // WhatsApp PDF Share
  // ─────────────────────────────────────────────────────────────────────────────

  /// Generate PDF struk persis seperti preview dan share via WhatsApp
  static Future<void> _shareInvoiceViaWhatsApp(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      final service = await _serviceFromContext(context);
      if (service == null) return;

      final sourceType = _stringValue(data['_source_type']).isNotEmpty
          ? _stringValue(data['_source_type'])
          : _stringValue(data['type']);
      final sourceId = _intValue(data['_source_id'] ?? data['id']);
      if (sourceType.isEmpty || sourceId <= 0) {
        _snack(context, 'Data transaksi untuk ambil link invoice tidak valid.',
            isError: true);
        return;
      }

      var invoiceUrl = _resolveInvoiceUrl(data);
      if (invoiceUrl.isEmpty) {
        final qrResponse =
            await service.getQrData(type: sourceType, id: sourceId);
        final qrData = _unwrapData(qrResponse);
        invoiceUrl = _resolveInvoiceUrl(qrData, fallback: qrResponse);
      }
      if (invoiceUrl.isEmpty) {
        _snack(context, 'Link invoice tidak tersedia.', isError: true);
        return;
      }

      // Normalisasi nomor telepon pelanggan
      final noTelepon = _resolveCustomerPhone(data);
      final phone = _normalizePhoneForWhatsApp(noTelepon);
      if (phone.isEmpty) {
        _snack(context, 'Nomor telepon pelanggan tidak tersedia.',
            isError: true);
        return;
      }

      final pelanggan = _stringValue(data['pelanggan']);
      final grandTotal = _currency(_numValue(data['grand_total']));
      final nomorInvoice = _stringValue(data['nomor']);
      final jatuhTempo = _firstStringValue(data, const [
        'jatuh_tempo',
        'tgl_jatuh_tempo',
        'tanggal_jatuh_tempo',
        'due_date',
      ]);
      final jenisPembayaran = _firstStringValue(data, const [
        'jenis_pembayaran',
        'pembayaran',
        'syarat_pembayaran',
        'metode_pembayaran',
        'cara_pembayaran',
      ]);

      final message =
          'Halo ${pelanggan.isNotEmpty ? pelanggan : 'Pelanggan'},\n\n'
          'Berikut invoice transaksi Anda:\n'
          'No. Invoice: $nomorInvoice\n'
          'Jatuh Tempo: ${jatuhTempo.isNotEmpty ? jatuhTempo : '-'}\n'
          'Pembayaran: ${jenisPembayaran.isNotEmpty ? jenisPembayaran : '-'}\n'
          'Total: $grandTotal\n\n'
          'Silakan buka invoice melalui link berikut:\n'
          '$invoiceUrl\n\n'
          'Terima kasih telah berbelanja di Hibiscus Efsya.';

      final waUri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
      final launched =
          await launchUrl(waUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _snack(context, 'Gagal membuka WhatsApp.', isError: true);
      }
    } catch (e) {
      _snack(context, 'Gagal menyiapkan WhatsApp: $e', isError: true);
    }
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String _firstStringValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _stringValue(data[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _resolveInvoiceUrl(
    Map<String, dynamic> data, {
    Map<String, dynamic>? fallback,
  }) {
    const keys = [
      '_invoice_url',
      'download_url',
      'receipt_url',
      'pdf_url',
      'struk_url',
      'invoice_url',
      'public_url',
      'url',
    ];

    for (final key in keys) {
      final value = _findString(data, key);
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }

    if (fallback != null) {
      for (final key in keys) {
        final value = _findString(fallback, key);
        if (value != null && value.trim().isNotEmpty) return value.trim();
      }
    }

    return '';
  }

  static String _resolveCustomerPhone(Map<String, dynamic> data) {
    const directKeys = [
      'no_telepon',
      'no_telp',
      'telepon',
      'nomor_telepon',
      'phone',
      'no_hp',
      'hp',
      'whatsapp',
      'wa',
      'kontak_no_telepon',
      'kontak_no_telp',
      'kontak_phone',
      'pelanggan_no_telepon',
      'pelanggan_no_telp',
      'pelanggan_phone',
      'customer_no_telepon',
      'customer_no_telp',
      'customer_phone',
      'no_telp_kontak',
    ];

    final direct = _firstPhoneValue(data, directKeys);
    if (direct.isNotEmpty) return direct;

    for (final nestedKey in const ['kontak', 'pelanggan', 'customer']) {
      final nested = data[nestedKey];
      if (nested is Map) {
        final parsed = _findPhoneInMap(
          nested.map((k, v) => MapEntry(k.toString(), v)),
          allowSalesKeys: false,
        );
        if (parsed.isNotEmpty) return parsed;
      }
    }

    final type = _stringValue(data['_source_type']).isNotEmpty
        ? _stringValue(data['_source_type'])
        : _stringValue(data['type']);
    if (type.toLowerCase().contains('kunjungan')) {
      final salesPhone = _firstPhoneValue(data, const ['sales_no_telepon']);
      if (salesPhone.isNotEmpty) return salesPhone;
    }

    return _findPhoneInMap(data, allowSalesKeys: false);
  }

  static String _firstPhoneValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _phoneCandidate(data[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _findPhoneInMap(
    Map<String, dynamic> data, {
    required bool allowSalesKeys,
  }) {
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (!allowSalesKeys &&
          (key.contains('sales') ||
              key.contains('user') ||
              key.contains('approver'))) {
        continue;
      }

      final value = _phoneCandidate(entry.value);
      if (value.isNotEmpty &&
          (key.contains('telp') ||
              key.contains('telepon') ||
              key.contains('phone') ||
              key.contains('whatsapp') ||
              key == 'wa' ||
              key.endsWith('_wa'))) {
        return value;
      }

      final nested = entry.value;
      if (nested is Map) {
        final found = _findPhoneInMap(
          nested.map((k, v) => MapEntry(k.toString(), v)),
          allowSalesKeys: allowSalesKeys,
        );
        if (found.isNotEmpty) return found;
      }
    }
    return '';
  }

  static String _phoneCandidate(dynamic value) {
    final text = _stringValue(value);
    if (text.isEmpty) return '';
    final lower = text.toLowerCase();
    if (text == '-' ||
        lower == 'null' ||
        lower == 'n/a' ||
        lower == 'na' ||
        lower == 'tidak ada') {
      return '';
    }
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 8) return '';
    return text;
  }

  static String _normalizePhoneForWhatsApp(dynamic value) {
    final text = _phoneCandidate(value);
    if (text.isEmpty) return '';

    var digits = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('620')) {
      digits = '62${digits.substring(3)}';
    } else if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    } else if (!digits.startsWith('62')) {
      digits = '62$digits';
    }
    return digits.length >= 10 ? digits : '';
  }
}

/// Paints a simple zigzag torn-paper edge at the top or bottom of a receipt.
class _TornEdgePainter extends CustomPainter {
  final bool isTop;
  const _TornEdgePainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF7F7F7) // matches sheet background
      ..style = PaintingStyle.fill;

    final path = Path();
    const teethCount = 14;
    final teethWidth = size.width / teethCount;
    final teethHeight = size.height;

    if (isTop) {
      path.moveTo(0, 0);
      for (int i = 0; i < teethCount; i++) {
        final x = i * teethWidth;
        path.lineTo(x + teethWidth / 2, teethHeight);
        path.lineTo(x + teethWidth, 0);
      }
      path.lineTo(size.width, 0);
      path.close();
    } else {
      path.moveTo(0, teethHeight);
      for (int i = 0; i < teethCount; i++) {
        final x = i * teethWidth;
        path.lineTo(x + teethWidth / 2, 0);
        path.lineTo(x + teethWidth, teethHeight);
      }
      path.lineTo(size.width, teethHeight);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget pilihan ukuran kertas pada dialog pilih printer
class _PaperSizeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PaperSizeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF888888), size: 20),
          ],
        ),
      ),
    );
  }
}
