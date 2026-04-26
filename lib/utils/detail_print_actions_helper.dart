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
      final printData = {
        ...data,
        'type': type,
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

  static Future<bool?> _showPreviewDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final title = _receiptTitle(data);
    final lines = _buildReceiptLines(data);

    final sb = StringBuffer();
    // Simulate paper width of 32 chars
    String padCenter(String text) {
      if (text.length >= 32) return text;
      final leftPad = ((32 - text.length) / 2).floor();
      return ' ' * leftPad + text;
    }

    sb.writeln(padCenter('HIBISCUS EFSYA'));
    if (title.isNotEmpty) {
      sb.writeln(padCenter(title));
    }
    sb.writeln('-' * 32);

    for (final line in lines) {
      if (line == null) {
        sb.writeln('');
      } else {
        sb.writeln(line);
      }
    }

    sb.writeln('-' * 32);
    sb.writeln(padCenter('marketing@hibiscusefsya.com'));
    sb.writeln();
    sb.writeln(padCenter('Terima kasih'));

    final receiptText = sb.toString();

    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Preview Struk'),
          content: Container(
            width: double.maxFinite,
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Text(
                receiptText,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.print),
              label: const Text('Pilih Printer'),
            ),
          ],
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
      bytes.addAll(generator.text(
        line,
        styles: const PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      'marketing@hibiscusefsya.com',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'Terima kasih',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.feed(2));
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

  static List<String?> _buildReceiptLines(Map<String, dynamic> data) {
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
      _kvLine('Pelanggan', _stringValue(data['pelanggan'])),
    ]);
    if (_stringValue(data['email']).isNotEmpty) {
      lines.add(_kvLine('Email', _stringValue(data['email'])));
    }
    if (_stringValue(data['alamat_penagihan']).isNotEmpty) {
      lines.add(_kvLine('Alamat', _stringValue(data['alamat_penagihan'])));
    }
    if (_stringValue(data['tipe_harga']).isNotEmpty) {
      lines.add(_kvLine('Tipe Harga', _stringValue(data['tipe_harga'])));
    }
    lines.addAll([
      _kvLine('Sales', _stringValue(data['sales'])),
      _kvLine('Gudang', _stringValue(data['gudang'])),
      _kvLine('Status', _stringValue(data['status'])),
    ]);
    if (_stringValue(data['no_referensi']).isNotEmpty) {
      lines.add(_kvLine('No. Ref', _stringValue(data['no_referensi'])));
    }
    if (_stringValue(data['tag']).isNotEmpty) {
      lines.add(_kvLine('Tag', _stringValue(data['tag'])));
    }
    if (_stringValue(data['koordinat']).isNotEmpty) {
      lines.add(_kvLine('Koordinat', _stringValue(data['koordinat'])));
    }
    if (_stringValue(data['memo']).isNotEmpty) {
      lines.add(_kvLine('Memo', _stringValue(data['memo'])));
    }
    lines.add(null);

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      lines.add(_wrapText(_itemName(item)));
      lines.add(_wrapText(_itemQuantityPrice(item)));
      final diskon = _numValue(item['diskon']);
      if (diskon > 0) {
        lines.add(_twoColumn('Diskon', '${diskon.toStringAsFixed(diskon % 1 == 0 ? 0 : 2)}%'));
      }
      if (_stringValue(item['batch']).isNotEmpty) {
        lines.add(_kvLine('Batch', _stringValue(item['batch'])));
      }
      if (_stringValue(item['exp']).isNotEmpty) {
        lines.add(_kvLine('Exp', _stringValue(item['exp'])));
      }
      if (_stringValue(item['deskripsi']).isNotEmpty) {
        lines.add(_kvLine('Ket', _stringValue(item['deskripsi'])));
      }
      lines.add(_twoColumn('Jumlah', _currency(_numValue(item['jumlah']))));
      lines.add(null);
    }

    lines.addAll([
      _twoColumn('Subtotal', _currency(_numValue(data['subtotal']))),
      if (_numValue(data['diskon_akhir']) > 0)
        _twoColumn('Diskon', '- ${_currency(_numValue(data['diskon_akhir']))}'),
      if (_numValue(data['pajak']) > 0)
        _twoColumn(
          'Pajak (${_numValue(data['tax_percentage']).toStringAsFixed(_numValue(data['tax_percentage']) % 1 == 0 ? 0 : 2)}%)',
          _currency(_numValue(data['pajak'])),
        ),
      _twoColumn('GRAND TOTAL', _currency(_numValue(data['grand_total'])), boldRight: true),
    ]);
    return lines;
  }

  static List<String?> _buildKunjunganLines(Map<String, dynamic> data) {
    final lines = <String?>[];
    lines.addAll([
      _kvLine('Nomor', _stringValue(data['nomor'])),
      _kvLine('Tanggal', _stringValue(data['tanggal'])),
      _kvLine('Tujuan', _stringValue(data['tujuan'])),
      _kvLine('Gudang', _stringValue(data['gudang'])),
    ]);
    // Pembuat (user yang login)
    String pembuatNama = _stringValue(data['dibuat_oleh']);
    if (pembuatNama.isEmpty) {
      final user = data['user'];
      if (user is Map) pembuatNama = _stringValue(user['name']);
    }
    if (pembuatNama.isEmpty) pembuatNama = _stringValue(data['pembuat']);
    if (pembuatNama.isNotEmpty) lines.add(_kvLine('Pembuat', pembuatNama));
    lines.add(_kvLine('Status', _stringValue(data['status'])));
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
      lines.add(_kvLine('Pelanggan', pelangganNama));
    }
    if (_stringValue(data['sales_email']).isNotEmpty) {
      lines.add(_kvLine('Email', _stringValue(data['sales_email'])));
    }
    if (_stringValue(data['sales_alamat']).isNotEmpty) {
      lines.add(_kvLine('Alamat', _stringValue(data['sales_alamat'])));
    }
    if (_stringValue(data['koordinat']).isNotEmpty) {
      lines.add(_kvLine('Koordinat', _stringValue(data['koordinat'])));
    }
    if (_stringValue(data['memo']).isNotEmpty) {
      lines.add(_kvLine('Memo', _stringValue(data['memo'])));
    }
    lines.add(null);

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      // Nama produk bisa dari nested 'produk' map
      String produkNama = _stringValue(item['nama']);
      if (produkNama.isEmpty) produkNama = _stringValue(item['nama_produk']);
      if (produkNama.isEmpty) {
        final produkMap = item['produk'];
        if (produkMap is Map) produkNama = _stringValue(produkMap['nama_produk']);
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
      lines.add(_twoColumn('Qty', '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)} $satuan'));

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
      _kvLine('Dibuat oleh', _stringValue(data['sales'])),
      _kvLine('Gudang', _stringValue(data['gudang'])),
      _kvLine('Status', _stringValue(data['status'])),
    ]);
    if (_stringValue(data['tahun_anggaran']).isNotEmpty) {
      lines.add(_kvLine('Thn Anggaran', _stringValue(data['tahun_anggaran'])));
    }
    if (_stringValue(data['staf_penyetuju']).isNotEmpty) {
      lines.add(_kvLine('Staf Penyetuju', _stringValue(data['staf_penyetuju'])));
    }
    if (_stringValue(data['memo']).isNotEmpty) {
      lines.add(_kvLine('Memo', _stringValue(data['memo'])));
    }
    lines.add(null);

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      lines.add(_wrapText(_itemName(item)));
      final qty = _numValue(item['qty'] ?? item['kuantitas']);
      final unit = _stringValue(item['unit']).isNotEmpty
          ? _stringValue(item['unit'])
          : (_stringValue(item['satuan']).isNotEmpty ? _stringValue(item['satuan']) : 'Pcs');
      lines.add(_twoColumn('Qty', '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)} $unit'));
      // Diskon item (bisa dalam % atau nominal)
      final diskonPct = _numValue(item['diskon']);
      if (diskonPct > 0) {
        lines.add(_twoColumn('Diskon', '${diskonPct.toStringAsFixed(diskonPct % 1 == 0 ? 0 : 2)}%'));
      }
      if (_stringValue(item['batch_number']).isNotEmpty) {
        lines.add(_kvLine('Batch', _stringValue(item['batch_number'])));
      }
      if (_stringValue(item['batch']).isNotEmpty) {
        lines.add(_kvLine('Batch', _stringValue(item['batch'])));
      }
      if (_stringValue(item['expired_date']).isNotEmpty) {
        lines.add(_kvLine('Exp', _stringValue(item['expired_date'])));
      }
      if (_stringValue(item['exp']).isNotEmpty) {
        lines.add(_kvLine('Exp', _stringValue(item['exp'])));
      }
      if (_stringValue(item['deskripsi']).isNotEmpty) {
        lines.add(_kvLine('Ket', _stringValue(item['deskripsi'])));
      }
      lines.add(_twoColumn('Jumlah', _currency(_numValue(item['jumlah']))));
      lines.add(null);
    }

    lines.addAll([
      _twoColumn('Subtotal', _currency(_numValue(data['subtotal']))),
      if (_numValue(data['diskon_akhir']) > 0)
        _twoColumn('Diskon', '- ${_currency(_numValue(data['diskon_akhir']))}'),
      if (_numValue(data['pajak']) > 0)
        _twoColumn(
          'Pajak (${_numValue(data['tax_percentage']).toStringAsFixed(_numValue(data['tax_percentage']) % 1 == 0 ? 0 : 2)}%)',
          _currency(_numValue(data['pajak'])),
        ),
      _twoColumn('GRAND TOTAL', _currency(_numValue(data['grand_total'])), boldRight: true),
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
      _kvLine('Dibuat oleh', _stringValue(data['sales'])),
      _kvLine('Status', _stringValue(data['status'])),
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
    lines.add(null);

    final items = _listOfMaps(data['items']);
    for (final item in items) {
      lines.add(_wrapText(_stringValue(item['kategori'])));
      if (_stringValue(item['deskripsi']).isNotEmpty) {
        lines.add(_kvLine('Ket', _stringValue(item['deskripsi'])));
      }
      lines.add(_twoColumn('Jumlah', _currency(_numValue(item['jumlah']))));
      lines.add(null);
    }

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
    lines.add(_twoColumn('GRAND TOTAL', _currency(_numValue(data['grand_total'])), boldRight: true));
    return lines;
  }

  static List<String?> _buildGenericLines(Map<String, dynamic> data) {
    final lines = <String?>[];
    data.forEach((key, value) {
      if (key == 'items') return;
      lines.add(_kvLine(key.replaceAll('_', ' ').toUpperCase(), _stringValue(value)));
    });
    return lines;
  }

  static String _itemName(Map<String, dynamic> item) {
    final name = _stringValue(item['nama']);
    if (name.isNotEmpty) return name;
    return _stringValue(item['nama_produk']).isNotEmpty
        ? _stringValue(item['nama_produk'])
        : '-';
  }

  static String _itemQuantityPrice(Map<String, dynamic> item) {
    final qty = _numValue(item['qty']);
    final unit = _stringValue(item['unit']).isNotEmpty ? _stringValue(item['unit']) : 'Pcs';
    final harga = _numValue(item['harga']);
    final qtyText = qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2);
    return '$qtyText $unit x ${_currency(harga)}';
  }

  static String _kvLine(String label, String value) {
    return _twoColumn(label, value.isEmpty ? '-' : value);
  }

  static String _twoColumn(String left, String right, {bool boldRight = false}) {
    const width = 32;
    final leftText = left.trim();
    final rightText = right.trim().isEmpty ? '-' : right.trim();
    final available = width - leftText.length - rightText.length;
    if (available <= 1) {
      return '$leftText $rightText';
    }
    return '$leftText${' ' * available}$rightText';
  }

  static String _wrapText(String value, {int width = 32}) {
    final text = value.trim();
    if (text.isEmpty) return '';
    if (text.length <= width) return text;

    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if (current.isEmpty) {
        current = word;
        continue;
      }
      if ((current.length + 1 + word.length) <= width) {
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

  static num _numValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static String _currency(num value) {
    return 'Rp ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}' ;
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
