import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../kontak/kontak_form_screen.dart';
import '../../widgets/glass_container.dart';

class KunjunganCreateScreen extends StatefulWidget {
  const KunjunganCreateScreen({super.key});

  @override
  State<KunjunganCreateScreen> createState() => _KunjunganCreateScreenState();
}

class _KunjunganCreateScreenState extends State<KunjunganCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  final _salesNamaController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController();

  KontakModel? _selectedKontak;
  int? _gudangId;
  bool _isGudangLocked = false;
  bool _isLoadingProdukGudang = false;
  final Set<int> _allowedProdukIds = {};
  final Map<int, StokModel> _stokByProdukId = {};
  DateTime _tglKunjungan = DateTime.now();
  String? _tujuan;
  final _koordinatController = TextEditingController();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KontakProvider>(context, listen: false).fetchKontak();
      Provider.of<ProdukProvider>(context, listen: false).fetchProduk();
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      _applyUserGudangRule();
    });
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

  Future<void> _openKontakForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KontakFormScreen()),
    );
    if (mounted) {
      await Provider.of<KontakProvider>(context, listen: false).fetchKontak();
    }
  }

  Future<void> _scanKontak() async {
    final provider = Provider.of<KontakProvider>(context, listen: false);
    await provider.fetchKontak();
    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          scanType: 'kontak',
          dataList: provider.items
              .map((k) => {
                    'id': k.id,
                    'kode_kontak': k.kodeKontak,
                    'nama': k.nama,
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
    final matched = provider.items.cast<KontakModel?>().firstWhere(
          (k) => k?.id == scannedId,
          orElse: () => null,
        );
    final scannedName =
        (result['nama'] ?? matched?.nama ?? '').toString().trim();
    final scannedEmail =
        (result['email'] ?? matched?.email ?? '').toString().trim();
    final scannedAlamat =
        (result['alamat'] ?? matched?.alamat ?? '').toString().trim();
    setState(() {
      _selectedKontak = matched;
      _salesNamaController.text = scannedName;
      _emailController.text = scannedEmail;
      _alamatController.text = scannedAlamat;
    });
  }

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
        final produkId = item.produk?.id;
        if (produkId == null) continue;
        final tersedia = _availableStockByTujuan(produkId);
        if (tersedia <= 0) {
          item.produk = null;
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
    setState(() => _items[rowIndex].produk = matched);
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
    if (_selectedKontak == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pelanggan wajib dipilih'),
          backgroundColor: Colors.red));
      return;
    }
    if (_tujuan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tujuan kunjungan wajib dipilih'),
          backgroundColor: Colors.red));
      return;
    }
    if (_isPromoStockBound) {
      for (final item in _items.where((i) => i.produk != null)) {
        final produk = item.produk!;
        final tersedia = _availableStockByTujuan(produk.id);
        if (tersedia <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Stok ${_resolveTipeStokByTujuan()} untuk ${produk.namaProduk} tidak tersedia.',
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
                'Qty ${produk.namaProduk} melebihi stok ${_resolveTipeStokByTujuan()} (tersedia: $tersedia).',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }
    }
    setState(() => _isSubmitting = true);
    try {
      final data = <String, dynamic>{
        'tgl_kunjungan': _tglKunjungan.toIso8601String().split('T')[0],
        'kontak_id': _selectedKontak!.id,
        'gudang_id': _gudangId,
        'tujuan': _tujuan,
        'memo': _memoController.text,
        'koordinat': _koordinatController.text.isNotEmpty
            ? _koordinatController.text
            : null,
        'sales_nama': _salesNamaController.text.trim().isNotEmpty
            ? _salesNamaController.text.trim()
            : null,
        'sales_email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'sales_alamat': _alamatController.text.trim().isNotEmpty
            ? _alamatController.text.trim()
            : null,
        'items': _items
            .where((i) => i.produk != null)
            .map((i) => {
                  'produk_id': i.produk!.id,
                  'jumlah': i.qty,
                  'tipe_stok': _resolveTipeStokByTujuan(),
                  'batch_number': i.batchController.text.trim().isNotEmpty
                      ? i.batchController.text.trim()
                      : null,
                  'expired_date': i.expDate != null
                      ? i.expDate!.toIso8601String().split('T')[0]
                      : null,
                  'keterangan': i.keteranganController.text,
                })
            .toList(),
      };
      final provider = Provider.of<KunjunganProvider>(context, listen: false);

      if (_lampiran.isNotEmpty) {
        final fields = <String, String>{};
        data.forEach((key, value) {
          if (value == null) return;
          if (key == 'items') {
            final items = value as List;
            for (int idx = 0; idx < items.length; idx++) {
              (items[idx] as Map).forEach((k, v) {
                if (v != null) fields['items[$idx][$k]'] = v.toString();
              });
            }
          } else {
            fields[key] = value.toString();
          }
        });
        final paths =
            _lampiran.where((f) => f.path != null).map((f) => f.path!).toList();
        await provider.createKunjunganMultipart(
          fields: fields,
          lampiran: paths,
        );
      } else {
        await provider.createKunjungan(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kunjungan berhasil dibuat!'),
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
          title: const Text('Buat Kunjungan Baru'),
          flexibleSpace: Container(
              decoration:
                  BoxDecoration(gradient: AppTheme.mainGradient(context)))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aprover akan ditentukan otomatis berdasarkan gudang Anda.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

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
                return SearchableDropdownFormField<KontakModel>(
                  value: _selectedKontak,
                  labelText: 'Pelanggan *',
                  hintText: 'Pilih atau ketik kontak...',
                  items: kontakProvider.items,
                  itemAsString: _kontakSearchLabel,
                  onChanged: (v) => setState(() {
                    _selectedKontak = v;
                    _salesNamaController.text = v?.nama ?? '';
                    _emailController.text = v?.email ?? '';
                    _alamatController.text = v?.alamat ?? '';
                  }),
                  validator: (v) =>
                      v == null ? 'Pelanggan wajib dipilih' : null,
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanKontak,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Pelanggan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openKontakForm,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Tambah Kontak'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nama Pelanggan, Email & Alamat dari kontak
            TextFormField(
              controller: _salesNamaController,
              decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan',
                  hintText: 'Otomatis dari kontak',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Email Pelanggan',
                  hintText: 'Otomatis dari kontak',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamatController,
              decoration: const InputDecoration(
                  labelText: 'Alamat Pelanggan', border: OutlineInputBorder()),
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
              fileNamePrefix: 'VST',
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
                  children: List.generate(
                      _items.length,
                      (i) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(children: [
                                Row(children: [
                                  Expanded(
                                    child: SearchableDropdownFormField<
                                        ProdukModel>(
                                      value: _items[i].produk,
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
                                      onChanged: (v) =>
                                          setState(() => _items[i].produk = v),
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
                                      initialValue: _items[i].qty.toString(),
                                      decoration: const InputDecoration(
                                          labelText: 'Qty',
                                          isDense: true,
                                          border: OutlineInputBorder()),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(() =>
                                          _items[i].qty = int.tryParse(v) ?? 0),
                                    ),
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () => _removeItem(i)),
                                ]),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _items[i].batchController,
                                        decoration: const InputDecoration(
                                            labelText: 'Batch',
                                            isDense: true,
                                            border: OutlineInputBorder()),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DatePickerField(
                                        label: 'Exp Date',
                                        selectedDate: _items[i].expDate,
                                        onDateSelected: (d) => setState(
                                            () => _items[i].expDate = d),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: _items[i].keteranganController,
                                    decoration: const InputDecoration(
                                        labelText: 'Keterangan',
                                        isDense: true,
                                        border: OutlineInputBorder())),
                              ]),
                            ),
                          )),
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
  int qty = 1;
  DateTime? expDate;
  final batchController = TextEditingController();
  final keteranganController = TextEditingController();
}
