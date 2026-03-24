import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/stok_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../providers/produk_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/produk_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_container.dart';

class StokGudangScreen extends StatefulWidget {
  const StokGudangScreen({super.key});

  @override
  State<StokGudangScreen> createState() => _StokGudangScreenState();
}

class _StokGudangScreenState extends State<StokGudangScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedGudangId;
  ProdukModel? _selectedProduk;
  final _stokPenjualanController = TextEditingController(text: '0');
  final _stokGratisController = TextEditingController(text: '0');
  final _stokSampleController = TextEditingController(text: '0');
  final _keteranganController = TextEditingController();
  bool _isSubmitting = false;

  int? _activeGudangId() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.currentGudangId ?? user?.gudangId;
  }

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

  int _resolveGudangId(dynamic item) {
    final fallbackGudangId = _selectedGudangId ?? _activeGudangId();
    if (item is! Map) return fallbackGudangId ?? 0;

    final nestedGudang = item['gudang'];
    final rawGudangId = item['gudang_id'] ??
        item['gudangId'] ??
        (nestedGudang is Map
            ? (nestedGudang['id'] ?? nestedGudang['gudang_id'])
            : null);

    final parsedGudangId = _asInt(rawGudangId);
    if (parsedGudangId > 0) return parsedGudangId;

    return fallbackGudangId ?? 0;
  }

  String _resolveGudangName(
      dynamic item, int gId, Map<int, String> knownNames) {
    if (knownNames[gId] != null && knownNames[gId]!.trim().isNotEmpty) {
      return knownNames[gId]!;
    }
    if (item is Map) {
      final nestedGudang = item['gudang'];
      if (nestedGudang is Map) {
        final name = (nestedGudang['nama_gudang'] ??
                nestedGudang['nama'] ??
                nestedGudang['name'])
            ?.toString();
        if (name != null && name.trim().isNotEmpty) {
          return name;
        }
      }
    }
    return 'Gudang $gId';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final canEditStockManual =
          user?.hasPermission('can_edit_stock_manual') == true &&
              user?.isAdmin != true;
      final activeGudangId = _activeGudangId();

      if (_selectedGudangId == null && activeGudangId != null) {
        setState(() => _selectedGudangId = activeGudangId);
      }

      Provider.of<StokProvider>(context, listen: false)
          .fetchStok(gudangId: activeGudangId);
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      if (canEditStockManual) {
        Provider.of<ProdukProvider>(context, listen: false).fetchProduk();
      }
    });
  }

  @override
  void dispose() {
    _stokPenjualanController.dispose();
    _stokGratisController.dispose();
    _stokSampleController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _submitStok() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await Provider.of<StokProvider>(context, listen: false).updateStok({
        'gudang_id': _selectedGudangId,
        'produk_id': _selectedProduk?.id,
        'stok_penjualan': int.tryParse(_stokPenjualanController.text) ?? 0,
        'stok_gratis': int.tryParse(_stokGratisController.text) ?? 0,
        'stok_sample': int.tryParse(_stokSampleController.text) ?? 0,
        'keterangan': _keteranganController.text,
      }, refreshGudangId: _selectedGudangId ?? _activeGudangId());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Stok berhasil disimpan!'),
            backgroundColor: Colors.green));
        _stokPenjualanController.text = '0';
        _stokGratisController.text = '0';
        _stokSampleController.text = '0';
        _keteranganController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _exportStokExcel() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengunduh Excel...'),
          duration: Duration(seconds: 2),
        ),
      );

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final gudangId = auth.user?.currentGudangId ?? auth.user?.gudangId ?? 1;
      final dashboard = Provider.of<DashboardProvider>(context, listen: false);
      final bytes = await dashboard.exportStokExcel(gudangId: gudangId);

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'Stok_Gudang_${DateTime.now().toIso8601String().split('T')[0]}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Stok Gudang',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final canEditStockManual =
        user?.hasPermission('can_edit_stock_manual') == true &&
            user?.isAdmin != true;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Stok Gudang'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Excel',
            onPressed: () => _exportStokExcel(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<StokProvider>(context, listen: false)
              .fetchStok(gudangId: _selectedGudangId ?? _activeGudangId());
          if (context.mounted) {
            await Provider.of<GudangProvider>(context, listen: false)
                .fetchGudang();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          children: [
            if (canEditStockManual) ...[
              // --- Update Stok Form ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tambah / Update Stok Awal',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Consumer<GudangProvider>(
                          builder: (ctx, gudangProvider, _) {
                            return DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: _selectedGudangId,
                              decoration: const InputDecoration(
                                  labelText: 'Pilih Gudang *'),
                              items: gudangProvider.items
                                  .map((g) => DropdownMenuItem(
                                      value: g.id, child: Text(g.namaGudang)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedGudangId = v),
                              validator: (v) =>
                                  v == null ? 'Pilih gudang' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Consumer<ProdukProvider>(
                          builder: (ctx, produkProvider, _) {
                            return DropdownButtonFormField<ProdukModel>(
                              isExpanded: true,
                              initialValue: _selectedProduk,
                              decoration: const InputDecoration(
                                  labelText: 'Pilih Produk *'),
                              items: produkProvider.items
                                  .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.namaProduk,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedProduk = v),
                              validator: (v) =>
                                  v == null ? 'Pilih produk' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stokPenjualanController,
                              decoration: const InputDecoration(
                                  labelText: 'Stok Penjualan', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _stokGratisController,
                              decoration: const InputDecoration(
                                  labelText: 'Stok Gratis', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _stokSampleController,
                              decoration: const InputDecoration(
                                  labelText: 'Stok Sample', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _keteranganController,
                          decoration: const InputDecoration(
                              labelText: 'Keterangan Perubahan (opsional)'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitStok,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save),
                            label: const Text('Simpan Stok'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- Daftar Stok per Gudang ---
            Text('Daftar Stok per Gudang',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Consumer2<StokProvider, GudangProvider>(
              builder: (ctx, stokProvider, gudangProvider, _) {
                if (stokProvider.isLoading && stokProvider.stokData.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ));
                }

                // Group stok by gudang
                final Map<int, List<dynamic>> grouped = {};
                final Map<int, String> gudangNames = {};
                for (final g in gudangProvider.items) {
                  gudangNames[g.id] = g.namaGudang;
                }

                for (final item in stokProvider.stokData) {
                  if (item is! Map) continue;
                  final gId = _resolveGudangId(item);
                  if (gId <= 0) continue;
                  if (!grouped.containsKey(gId)) {
                    grouped[gId] = [];
                    gudangNames[gId] =
                        _resolveGudangName(item, gId, gudangNames);
                  }
                  grouped[gId]!.add(item);
                }

                if (grouped.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Tidak ada data stok.'),
                  ));
                }

                return Column(
                  children: grouped.entries.map((entry) {
                    final gId = entry.key;
                    final items = entry.value;
                    final name = gudangNames[gId] ?? 'Gudang';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: const Icon(Icons.warehouse_outlined,
                            color: AppTheme.primaryColor, size: 22),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${items.length} produk',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textTertiaryColor(context))),
                        children: items.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Belum ada stok.'),
                                )
                              ]
                            : items.map<Widget>((item) {
                                final produk = item['produk'];
                                final stokPenjualan = _stockComponent(
                                    item, 'stok_penjualan', 'stokPenjualan');
                                final stokGratis = _stockComponent(
                                    item, 'stok_gratis', 'stokGratis');
                                final stokSample = _stockComponent(
                                    item, 'stok_sample', 'stokSample');
                                final totalStok = _resolveTotalStok(item);
                                return ListTile(
                                  dense: true,
                                  title: Text(produk?['nama_produk'] ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13)),
                                  subtitle: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _StokChip('Penjualan', stokPenjualan,
                                            AppTheme.successColor),
                                        _StokChip('Gratis', stokGratis,
                                            AppTheme.infoColor),
                                        _StokChip('Sample', stokSample,
                                            AppTheme.warningColor),
                                      ]),
                                  trailing: Text('Total: $totalStok',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppTheme.primaryColor)),
                                );
                              }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StokChip extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _StokChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withAlpha(15), borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
