import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kunjungan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kunjungan_provider.dart';
import '../../providers/kontak_provider.dart';
import '../../providers/produk_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../models/kontak_model.dart';
import '../../models/produk_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/koordinat_lokasi_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/searchable_dropdown_form_field.dart';
import 'package:file_picker/file_picker.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../../widgets/glass_container.dart';

class KunjunganEditScreen extends StatefulWidget {
  final KunjunganModel data;
  const KunjunganEditScreen({super.key, required this.data});

  @override
  State<KunjunganEditScreen> createState() => _KunjunganEditScreenState();
}

class _KunjunganEditScreenState extends State<KunjunganEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _memoController;
  late final TextEditingController _salesNamaController;
  late final TextEditingController _emailController;
  late final TextEditingController _alamatController;

  int? _kontakId;
  int? _gudangId;
  bool _isGudangLocked = false;
  bool _isLoadingProdukGudang = false;
  final Set<int> _allowedProdukIds = {};
  final Map<int, StokModel> _stokByProdukId = {};
  late DateTime _tglKunjungan;
  String? _tujuan;
  late final TextEditingController _koordinatController;
  final List<_KunjunganItem> _items = [];
  List<PlatformFile> _lampiran = [];
  bool _isSubmitting = false;

  static const List<String> _tujuanOptions = [
    'Pemeriksaan Stock',
    'Penagihan',
    'Promo Gratis',
    'Promo Sample',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _memoController = TextEditingController(text: d.memo ?? '');
    _salesNamaController = TextEditingController(text: d.salesNama ?? '');
    _emailController = TextEditingController(text: d.salesEmail ?? '');
    _alamatController = TextEditingController(text: d.salesAlamat ?? '');
    _kontakId = d.kontakId;
    _gudangId = d.gudangId;
    _tglKunjungan = d.tglKunjungan != null
        ? DateTime.tryParse(d.tglKunjungan!) ?? DateTime.now()
        : DateTime.now();
    _tujuan = _tujuanOptions.contains(d.tujuan) ? d.tujuan : null;
    _koordinatController = TextEditingController(text: d.koordinat ?? '');

    if (d.items != null) {
      for (final item in d.items!) {
        _items.add(_KunjunganItem()
          ..produkId = item.produkId
          ..qty = item.kuantitas ?? 1
          ..keteranganController.text = item.keterangan ?? '');
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KontakProvider>(context, listen: false).fetchKontak();
      Provider.of<ProdukProvider>(context, listen: false).fetchProduk();
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      _applyUserGudangRule();
      _applyUserDefaults();
    });
  }

  void _applyUserDefaults() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    if (_salesNamaController.text.trim().isEmpty) {
      _salesNamaController.text = user.name;
    }
    if (_emailController.text.trim().isEmpty && user.email.trim().isNotEmpty) {
      _emailController.text = user.email;
    }
    if (_alamatController.text.trim().isEmpty &&
        (user.alamat?.trim().isNotEmpty == true)) {
      _alamatController.text = user.alamat!.trim();
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    _salesNamaController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _koordinatController.dispose();
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_KunjunganItem()));
  void _removeItem(int i) => setState(() => _items.removeAt(i));

  Future<void> _applyUserGudangRule() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final fixedGudangId = user?.currentGudangId ?? user?.gudangId;
    final isSuperAdmin = user?.isSuperAdmin == true;

    if (!isSuperAdmin && fixedGudangId != null) {
      setState(() {
        _gudangId = fixedGudangId;
        _isGudangLocked = true;
      });
      await _loadProdukGudang(fixedGudangId);
      return;
    }

    setState(() => _isGudangLocked = false);
    if (_gudangId != null) {
      await _loadProdukGudang(_gudangId);
    }
  }

  Future<void> _loadProdukGudang(int? gudangId) async {
    if (gudangId == null) {
      setState(() {
        _allowedProdukIds.clear();
        _stokByProdukId.clear();
      });
      return;
    }
    setState(() => _isLoadingProdukGudang = true);
    try {
      final stokList = await Provider.of<GudangProvider>(context, listen: false)
          .fetchStok(gudangId: gudangId);
      if (!mounted) return;
      setState(() {
        _stokByProdukId
          ..clear()
          ..addEntries(stokList.map((s) => MapEntry(s.produkId, s)));
        _allowedProdukIds
          ..clear()
          ..addAll(stokList.map((s) => s.produkId));
      });
      _syncProdukByTujuan();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allowedProdukIds.clear();
        _stokByProdukId.clear();
      });
    } finally {
      if (mounted) setState(() => _isLoadingProdukGudang = false);
    }
  }

  bool get _isPromoGratis => _tujuan == 'Promo Gratis';
  bool get _isPromoSample => _tujuan == 'Promo Sample';
  bool get _isPromoStockBound => _isPromoGratis || _isPromoSample;

  String? _resolveTipeStokByTujuan() {
    if (_isPromoGratis) return 'gratis';
    if (_isPromoSample) return 'sample';
    return null;
  }

  int _availableStockByTujuan(int produkId) {
    final stok = _stokByProdukId[produkId];
    if (stok == null) return 0;
    if (_isPromoGratis) return stok.stokGratis;
    if (_isPromoSample) return stok.stokSample;
    return stok.stok;
  }

  bool _isProdukAllowedForCurrentTujuan(ProdukModel produk) {
    if (!_isPromoStockBound) return true;
    return _availableStockByTujuan(produk.id) > 0;
  }

  void _syncProdukByTujuan() {
    if (!_isPromoStockBound) return;
    setState(() {
      for (final item in _items) {
        final produkId = item.produk?.id ?? item.produkId;
        if (produkId == null) continue;
        final tersedia = _availableStockByTujuan(produkId);
        if (tersedia <= 0) {
          item.produk = null;
          item.produkId = null;
          item.qty = 1;
          continue;
        }
        if (item.qty > tersedia) {
          item.qty = tersedia;
        }
      }
    });
  }

  Future<void> _scanBarcodeProduk(
      int rowIndex, List<ProdukModel> produks) async {
    if (_gudangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih gudang terlebih dahulu sebelum scan produk.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          scanType: 'produk',
          dataList: produks
              .map((p) => {
                    'id': p.id,
                    'item_code': p.itemCode,
                    'nama_produk': p.namaProduk,
                  })
              .toList(),
        ),
      ),
    );
    if (result == null || !mounted) return;
    final scannedId = result['id'] is int
        ? result['id'] as int
        : int.tryParse('${result['id']}');
    if (scannedId == null) return;
    final matched = produks.cast<ProdukModel?>().firstWhere(
          (p) => p?.id == scannedId,
          orElse: () => null,
        );
    if (matched == null) return;
    setState(() {
      _items[rowIndex].produk = matched;
      _items[rowIndex].produkId = matched.id;
    });
  }

  String _produkSearchLabel(ProdukModel p) {
    final code = (p.itemCode ?? '').trim();
    return code.isNotEmpty ? '$code - ${p.namaProduk}' : p.namaProduk;
  }

  String _kontakSearchLabel(KontakModel k) {
    final code = (k.kodeKontak ?? '').trim();
    final telp = (k.noTelp ?? '').trim();
    final codePart = code.isNotEmpty ? '$code - ' : '';
    final telpPart = telp.isNotEmpty ? ' | $telp' : '';
    return '$codePart${k.nama}$telpPart';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      if (_isPromoStockBound) {
        for (final item
            in _items.where((i) => i.produkId != null || i.produk != null)) {
          final produkId = item.produk?.id ?? item.produkId;
          if (produkId == null) continue;
          final tersedia = _availableStockByTujuan(produkId);
          final namaProduk = item.produk?.namaProduk ?? 'Produk #$produkId';
          if (tersedia <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stok ${_resolveTipeStokByTujuan()} untuk $namaProduk tidak tersedia.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isSubmitting = false);
            return;
          }
          if (item.qty > tersedia) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Qty $namaProduk melebihi stok ${_resolveTipeStokByTujuan()} (tersedia: $tersedia).',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isSubmitting = false);
            return;
          }
        }
      }
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final resolvedSalesName = _salesNamaController.text.trim().isNotEmpty
          ? _salesNamaController.text.trim()
          : (user?.name.trim().isNotEmpty == true ? user!.name.trim() : null);
      final resolvedSalesEmail = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : (user?.email.trim().isNotEmpty == true ? user!.email.trim() : null);
      final resolvedSalesAddress = _alamatController.text.trim().isNotEmpty
          ? _alamatController.text.trim()
          : ((user?.alamat?.trim().isNotEmpty == true)
              ? user!.alamat!.trim()
              : null);
      final data = <String, dynamic>{
        'tgl_kunjungan': _tglKunjungan.toIso8601String().split('T')[0],
        'kontak_id': _kontakId,
        'gudang_id': _gudangId,
        'tujuan': _tujuan,
        'memo': _memoController.text,
        'koordinat': _koordinatController.text.isNotEmpty
            ? _koordinatController.text
            : null,
        'sales_nama': resolvedSalesName,
        'sales_email': resolvedSalesEmail,
        'sales_alamat': resolvedSalesAddress,
        'items': _items
            .where((i) => i.produkId != null || i.produk != null)
            .map((i) => {
                  'produk_id': i.produk?.id ?? i.produkId,
                  'jumlah': i.qty,
                  'tipe_stok': _resolveTipeStokByTujuan(),
                  'keterangan': i.keteranganController.text,
                })
            .toList(),
      };
      await Provider.of<KunjunganProvider>(context, listen: false)
          .updateKunjungan(widget.data.id, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kunjungan berhasil diperbarui!'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Edit Kunjungan'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Gudang & Tgl Kunjungan
            Row(children: [
              Expanded(
                child: Consumer<GudangProvider>(
                  builder: (ctx, gudangProvider, _) {
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _gudangId,
                      decoration: const InputDecoration(
                          labelText: 'Gudang', border: OutlineInputBorder()),
                      items: gudangProvider.items
                          .map((g) => DropdownMenuItem(
                              value: g.id, child: Text(g.namaGudang)))
                          .toList(),
                      onChanged: _isGudangLocked
                          ? null
                          : (v) {
                              setState(() => _gudangId = v);
                              _loadProdukGudang(v);
                            },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DatePickerField(
                  label: 'Tanggal Kunjungan *',
                  selectedDate: _tglKunjungan,
                  onDateSelected: (d) => setState(() => _tglKunjungan = d),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (_isGudangLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Gudang otomatis sesuai role akun Anda.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ),

            // Pelanggan (Kontak)
            Consumer<KontakProvider>(
              builder: (ctx, kontakProvider, _) {
                final matched =
                    kontakProvider.items.cast<KontakModel?>().firstWhere(
                          (k) => k?.id == _kontakId,
                          orElse: () => null,
                        );
                return SearchableDropdownFormField<KontakModel>(
                  value: matched,
                  labelText: 'Pelanggan *',
                  hintText: 'Ketik nama / kode / no telp pelanggan...',
                  leadingIcon: const Icon(Icons.search, size: 20),
                  items: kontakProvider.items,
                  itemAsString: _kontakSearchLabel,
                  onChanged: (v) {
                    setState(() {
                      _kontakId = v?.id;
                      _salesNamaController.text =
                          v?.nama ?? _salesNamaController.text;
                      _emailController.text = v?.email ?? _emailController.text;
                      _alamatController.text =
                          v?.alamat ?? _alamatController.text;
                    });
                  },
                  validator: (v) =>
                      v == null ? 'Pelanggan wajib dipilih' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Nama Sales, Email & Alamat
            TextFormField(
              controller: _salesNamaController,
              decoration: const InputDecoration(
                  labelText: 'Nama Sales',
                  hintText: 'Nama sales/aprover',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'email@contoh.com',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamatController,
              decoration: const InputDecoration(
                  labelText: 'Alamat', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Tujuan Kunjungan dropdown
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _tujuan,
              decoration: const InputDecoration(
                  labelText: 'Tujuan Kunjungan *',
                  hintText: 'Pilih tujuan...',
                  border: OutlineInputBorder()),
              items: _tujuanOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                setState(() => _tujuan = v);
                _syncProdukByTujuan();
              },
              validator: (v) => v == null ? 'Tujuan wajib dipilih' : null,
            ),
            const SizedBox(height: 16),

            // Koordinat Lokasi
            KoordinatLokasiField(
              controller: _koordinatController,
            ),
            const SizedBox(height: 16),

            // Lampiran
            LampiranPickerWidget(
              files: _lampiran,
              onFilesChanged: (files) => setState(() => _lampiran = files),
              fileNamePrefix: (widget.data.nomor?.trim().isNotEmpty == true)
                  ? widget.data.nomor!.trim()
                  : 'VST',
              existingFileCount: widget.data.lampiranPaths?.length ?? 0,
            ),
            const SizedBox(height: 20),
            Consumer<GudangProvider>(
              builder: (ctx, gudangProvider, _) {
                if (_gudangId == null) return const SizedBox.shrink();
                final selectedGudang =
                    gudangProvider.items.cast<dynamic>().firstWhere(
                          (g) => g.id == _gudangId,
                          orElse: () => null,
                        );
                final gudangName =
                    selectedGudang?.namaGudang ?? 'Gudang #$_gudangId';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? AppTheme.primaryColor.withAlpha(26)
                        : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(
                            alpha: AppTheme.isDark(context) ? 0.45 : 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt,
                          size: 16,
                          color: AppTheme.isDark(context)
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Filtered by Gudang: $gudangName',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.isDark(context)
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Produk Terkait
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.inventory_2, size: 20),
                const SizedBox(width: 6),
                Text('Produk Terkait',
                    style: Theme.of(context).textTheme.titleMedium),
              ]),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Produk'),
                  onPressed: _addItem),
            ]),
            Consumer<ProdukProvider>(
              builder: (ctx, produkProvider, _) {
                final baseProduks = _gudangId == null
                    ? <ProdukModel>[]
                    : (_isPromoStockBound
                        ? (_allowedProdukIds.isEmpty
                            ? produkProvider.items
                            : produkProvider.items
                                .where((p) => _allowedProdukIds.contains(p.id))
                                .toList())
                        : produkProvider.items);
                final produks = baseProduks
                    .where(_isProdukAllowedForCurrentTujuan)
                    .toList();
                return Column(
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    final matchedProduk = item.produk ??
                        (item.produkId != null
                            ? produks.cast<ProdukModel?>().firstWhere(
                                (p) => p!.id == item.produkId,
                                orElse: () => null)
                            : null);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          Row(children: [
                            Expanded(
                              child: SearchableDropdownFormField<ProdukModel>(
                                value: matchedProduk,
                                labelText: 'Pilih produk...',
                                hintText: _gudangId == null
                                    ? 'Pilih gudang dulu'
                                    : (_isLoadingProdukGudang
                                        ? 'Memuat produk...'
                                        : 'Ketik nama/kode produk...'),
                                enabled: _gudangId != null &&
                                    !_isLoadingProdukGudang,
                                items: produks,
                                itemAsString: _produkSearchLabel,
                                onChanged: (v) => setState(() {
                                  item.produk = v;
                                  item.produkId = v?.id;
                                }),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Scan Barcode EAN-13',
                              icon: const Icon(
                                Icons.qr_code_scanner,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: _isLoadingProdukGudang
                                  ? null
                                  : () => _scanBarcodeProduk(i, produks),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: item.qty.toString(),
                                decoration: const InputDecoration(
                                    labelText: 'Qty',
                                    isDense: true,
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => setState(
                                    () => item.qty = int.tryParse(v) ?? 0),
                              ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () => _removeItem(i)),
                          ]),
                          const SizedBox(height: 8),
                          TextFormField(
                              controller: item.keteranganController,
                              decoration: const InputDecoration(
                                  labelText: 'Keterangan',
                                  isDense: true,
                                  border: OutlineInputBorder())),
                        ]),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),

            // Memo
            TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                    labelText: 'Memo / Catatan', border: OutlineInputBorder()),
                maxLines: 3),
            const SizedBox(height: 24),

            // Buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('Simpan Kunjungan'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _KunjunganItem {
  ProdukModel? produk;
  int? produkId;
  int qty = 1;
  final keteranganController = TextEditingController();
}
