import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import '../../providers/auth_provider.dart';
import '../../providers/produk_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import 'produk_form_screen.dart';
import '../../widgets/glass_container.dart';

class ProdukDetailScreen extends StatefulWidget {
  final int id;
  const ProdukDetailScreen({super.key, required this.id});

  @override
  State<ProdukDetailScreen> createState() => _ProdukDetailScreenState();
}

class _ProdukDetailScreenState extends State<ProdukDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _stockComponent(dynamic item, String snakeKey, String camelKey) {
    if (item is! Map) return 0;
    return _asInt(item[snakeKey] ?? item[camelKey]);
  }

  int _resolveTotalStok(dynamic item) {
    if (item is! Map) return 0;
    final stokPenjualan =
        _stockComponent(item, 'stok_penjualan', 'stokPenjualan');
    final stokGratis = _stockComponent(item, 'stok_gratis', 'stokGratis');
    final stokSample = _stockComponent(item, 'stok_sample', 'stokSample');
    final hasComponentKey = item.containsKey('stok_penjualan') ||
        item.containsKey('stokPenjualan') ||
        item.containsKey('stok_gratis') ||
        item.containsKey('stokGratis') ||
        item.containsKey('stok_sample') ||
        item.containsKey('stokSample');
    if (hasComponentKey) {
      return stokPenjualan + stokGratis + stokSample;
    }
    return _asInt(item['stok']);
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      _data = await Provider.of<ProdukProvider>(context, listen: false)
          .getDetail(widget.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _delete() async {
    final produkProvider = Provider.of<ProdukProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await produkProvider.deleteProduk(widget.id);
        if (!mounted) return;
        navigator.pop(true);
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return GlassScaffold(
      appBar: AppBar(
        title: Text(_data?['nama_produk'] ?? 'Detail Produk'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
        actions: [
          if (_data != null &&
              user != null &&
              (user.isAdmin || user.isSuperAdmin))
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProdukFormScreen(produk: _data)));
                  if (!mounted) return;
                  if (result == true) _loadDetail();
                }
                if (val == 'delete') _delete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const AppDetailSkeleton()
          : _data == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.inventory_2,
                              size: 40, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                          child: Text(_data!['nama_produk'] ?? '-',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)),
                      if (_data!['item_code'] != null)
                        Center(
                            child: Text(_data!['item_code'],
                                style: TextStyle(
                                    color:
                                        AppTheme.textTertiaryColor(context)))),
                      // Barcode EAN-13 (only for 12-13 digit numeric codes)
                      if (_data!['item_code'] != null &&
                          RegExp(r'^\d{12,13}$')
                              .hasMatch(_data!['item_code'].toString()))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: bw.BarcodeWidget(
                              barcode: bw.Barcode.ean13(),
                              data: _data!['item_code'].toString(),
                              width: 200,
                              height: 70,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            _InfoRow('Harga',
                                Formatters.currency(_data!['harga'] ?? 0)),
                            _InfoRow(
                                'Harga Grosir',
                                Formatters.currency(
                                    _data!['harga_grosir'] ?? 0)),
                            _InfoRow('Satuan', _data!['satuan'] ?? '-'),
                            if (_data!['deskripsi'] != null &&
                                _data!['deskripsi'].toString().isNotEmpty)
                              _InfoRow('Deskripsi', _data!['deskripsi']),
                          ]),
                        ),
                      ),
                      // Show stok info if available
                      if (_data!['stok'] != null) ...[
                        const SizedBox(height: 16),
                        const Text('Stok per Gudang',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ...(_data!['stok'] as List? ?? []).map((s) {
                          final stokPenjualan = _stockComponent(
                              s, 'stok_penjualan', 'stokPenjualan');
                          final stokGratis =
                              _stockComponent(s, 'stok_gratis', 'stokGratis');
                          final stokSample =
                              _stockComponent(s, 'stok_sample', 'stokSample');
                          final totalStok = _resolveTotalStok(s);
                          final gudangName = s['gudang']?['nama_gudang'] ??
                              s['gudang']?['nama'] ??
                              'Gudang #${s['gudang_id']}';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(gudangName),
                              trailing: Text('$totalStok',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              subtitle: Wrap(spacing: 8, children: [
                                Text('Jual: $stokPenjualan',
                                    style: const TextStyle(fontSize: 12)),
                                Text('Gratis: $stokGratis',
                                    style: const TextStyle(fontSize: 12)),
                                Text('Sample: $stokSample',
                                    style: const TextStyle(fontSize: 12)),
                              ]),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(':',
              style: TextStyle(
                  color: AppTheme.textSecondaryColor(context), fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
