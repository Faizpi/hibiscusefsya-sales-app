import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_container.dart';

/// Reusable barcode/QR scanner screen.
///
/// Usage:
/// ```dart
/// final result = await Navigator.push(context,
///   MaterialPageRoute(builder: (_) => BarcodeScannerScreen(
///     scanType: 'produk', // or 'kontak'
///     dataList: [...],
///   )),
/// );
/// ```
class BarcodeScannerScreen extends StatefulWidget {
  /// 'produk' matches item_code, 'kontak' matches kode_kontak
  final String scanType;

  /// List of maps with 'id', 'item_code'/'kode_kontak', 'nama'/...
  final List<Map<String, dynamic>> dataList;

  /// Optional gudang ID for stock validation (produk only)
  final int? gudangId;

  /// produkId list per gudang (for stock availability check)
  final Map<int, List<int>>? gudangProduks;

  const BarcodeScannerScreen({
    super.key,
    required this.scanType,
    required this.dataList,
    this.gudangId,
    this.gudangProduks,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _cameraController;
  bool _isProcessing = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      formats: widget.scanType == 'produk'
          ? const [BarcodeFormat.ean13]
          : const [
              BarcodeFormat.qrCode,
              BarcodeFormat.code128,
              BarcodeFormat.code39,
              BarcodeFormat.ean13,
            ],
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _processScannedCode(String scannedCode) {
    if (widget.scanType == 'produk' && scannedCode.length != 13) {
      setState(() {
        _lastError =
            'Format barcode tidak sesuai. Gunakan barcode EAN-13 (13 digit).';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _lastError = null;
            _isProcessing = false;
          });
        }
      });
      return;
    }

    final keyField = widget.scanType == 'kontak' ? 'kode_kontak' : 'item_code';

    // 1. Exact match
    Map<String, dynamic>? foundItem;
    for (var item in widget.dataList) {
      if (item[keyField]?.toString() == scannedCode) {
        foundItem = item;
        break;
      }
    }

    // 2. Parse QR format "Kode: xxx" (for kontak)
    if (foundItem == null && widget.scanType == 'kontak') {
      final kodeMatch =
          RegExp(r'Kode:\s*(.+)', caseSensitive: false).firstMatch(scannedCode);
      if (kodeMatch != null) {
        final extractedKode = kodeMatch.group(1)!.trim();
        for (var item in widget.dataList) {
          if (item[keyField]?.toString() == extractedKode) {
            foundItem = item;
            break;
          }
        }
      }
    }

    if (foundItem != null) {
      // 3. Validate gudang stock for produk
      if (widget.scanType == 'produk' &&
          widget.gudangProduks != null &&
          widget.gudangId != null) {
        final produkIds = widget.gudangProduks![widget.gudangId] ?? [];
        if (!produkIds.contains(foundItem['id'])) {
          setState(() {
            _lastError =
                'Stok "${foundItem!['nama'] ?? foundItem['nama_produk']}" tidak tersedia di gudang.';
          });
          Future.delayed(
              const Duration(seconds: 2), () => _isProcessing = false);
          return;
        }
      }

      // Success: return item
      Navigator.pop(context, foundItem);
    } else {
      setState(() {
        _lastError = 'Kode "$scannedCode" tidak ditemukan.';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _lastError = null;
            _isProcessing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: Text(widget.scanType == 'kontak'
            ? 'Scan Kode Kontak'
            : 'Scan Kode Produk'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _cameraController,
              builder: (_, state, __) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              if (_isProcessing) return;
              _isProcessing = true;

              final barcode = capture.barcodes.firstOrNull;
              final String? code = barcode?.rawValue?.trim();

              if (code == null || code.isEmpty) {
                _isProcessing = false;
                return;
              }

              _processScannedCode(code);
            },
          ),
          // Scanning overlay
          Center(
            child: Container(
              width: widget.scanType == 'kontak' ? 250 : 300,
              height: widget.scanType == 'kontak' ? 250 : 120,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instruction text
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.scanType == 'kontak'
                      ? 'Arahkan kamera ke QR Code kontak'
                      : 'Arahkan kamera ke barcode produk',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          // Error message
          if (_lastError != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastError!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
