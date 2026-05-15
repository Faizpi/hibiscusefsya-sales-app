import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/penjualan_model.dart';
import '../../models/kontak_model.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kontak_provider.dart';
import '../../providers/produk_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../models/produk_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/koordinat_lokasi_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/searchable_dropdown_form_field.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../kontak/kontak_form_screen.dart';
import '../../widgets/glass_container.dart';

class PenjualanEditScreen extends StatefulWidget {
  final PenjualanModel data;
  const PenjualanEditScreen({super.key, required this.data});

  @override
  State<PenjualanEditScreen> createState() => _PenjualanEditScreenState();
}

class _PenjualanEditScreenState extends State<PenjualanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pelangganController;
  late final TextEditingController _emailController;
  late final TextEditingController _alamatPenagihanController;
  late final TextEditingController _memoController;
  late final TextEditingController _noReferensiController;
  late final TextEditingController _koordinatController;
  late final TextEditingController _tagController;
  KontakModel? _selectedKontak;

  late DateTime _tglTransaksi;
  late String _syaratPembayaran;
  late String _tipeHarga;
  late double _taxPercentage;
  late double _diskonAkhir;
  int? _gudangId;
  bool _isGudangLocked = false;
  bool _isLoadingProdukGudang = false;
  final Set<int> _allowedProdukIds = {};
  final List<_ItemRow> _items = [];
  List<PlatformFile> _lampiran = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _pelangganController = TextEditingController(text: d.pelanggan ?? '');
    _emailController = TextEditingController(text: d.noTelepon ?? '');
    _alamatPenagihanController =
        TextEditingController(text: d.alamatPenagihan ?? '');
    _memoController = TextEditingController(text: d.memo ?? '');
    _noReferensiController = TextEditingController(text: d.noReferensi ?? '');
    _koordinatController = TextEditingController(text: d.koordinat ?? '');
    _tagController = TextEditingController(text: d.tag ?? '');
    _tglTransaksi = d.tglTransaksi != null
        ? DateTime.tryParse(d.tglTransaksi!) ?? DateTime.now()
        : DateTime.now();
    _syaratPembayaran = d.syaratPembayaran ?? 'Cash';
    _tipeHarga = d.tipeHarga ?? 'Retail';
    _taxPercentage = (d.taxPercentage ?? 0).toDouble();
    _diskonAkhir = (d.diskonAkhir ?? 0).toDouble();
    _gudangId = d.gudangId;

    if (d.items != null) {
      for (final item in d.items!) {
        final row = _ItemRow()
          ..produkId = item.produkId
          ..namaProduk = item.namaProduk
          ..qty = item.kuantitas.toDouble()
          ..harga = item.hargaSatuan.toDouble()
          ..diskon = item.diskon.toDouble()
          ..diskonNominal = item.diskonNominal.toDouble();
        row.diskonNominalController.text =
            Formatters.rupiahInput(row.diskonNominal);
        row.deskripsiController.text = (item.deskripsi ?? '').trim();
        row.unitController.text =
            (item.unit ?? item.satuan ?? 'Pcs').toString().trim();
        row.batchController.text = (item.batchNumber ?? '').trim();
        if (item.expiredDate != null && item.expiredDate!.isNotEmpty) {
          row.expDate = DateTime.tryParse(item.expiredDate!);
        }
        _items.add(row);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProdukProvider>(context, listen: false).fetchProduk();
      Provider.of<KontakProvider>(context, listen: false)
          .fetchKontak(all: true);
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      _applyUserGudangRule();
      _applyUserDefaults();
    });
  }

  void _applyUserDefaults() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    if (_tagController.text.trim().isEmpty) {
      _tagController.text = user.name;
    }
  }

  @override
  void dispose() {
    _pelangganController.dispose();
    _emailController.dispose();
    _alamatPenagihanController.dispose();
    _memoController.dispose();
    _noReferensiController.dispose();
    _koordinatController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_ItemRow()));
  void _removeItem(int i) => setState(() => _items.removeAt(i));

  double _resolvedHargaForProduk(ProdukModel? produk) {
    if (produk == null) return 0;
    final hargaRetail = (produk.harga ?? 0).toDouble();
    final hargaGrosir = (produk.hargaGrosir ?? 0).toDouble();
    final tipeHarga = _tipeHarga.trim().toLowerCase();
    if (tipeHarga == 'grosir') {
      return hargaGrosir > 0 ? hargaGrosir : hargaRetail;
    }
    return hargaRetail;
  }

  String _resolvedTipeHargaForApi() {
    final value = _tipeHarga.trim().toLowerCase();
    if (value == 'grosir') return 'grosir';
    return 'retail';
  }

  bool _canEditHargaProduk() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.isSuperAdmin == true;
  }

  double _hargaSatuanForSubmit(_ItemRow row) {
    if (_canEditHargaProduk()) return row.harga;
    if (row.produk != null) return _resolvedHargaForProduk(row.produk);
    return row.harga;
  }

  bool _canEditApproved() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return widget.data.status != 'Approved' || user?.isSuperAdmin == true;
  }

  void _applySelectedProdukToRow(_ItemRow row, ProdukModel? produk) {
    row.produk = produk;
    row.produkId = produk?.id;
    row.harga = _resolvedHargaForProduk(produk);
    if (produk == null) return;
    row.unitController.text = (produk.satuan?.trim().isNotEmpty == true)
        ? produk.satuan!.trim()
        : 'Pcs';
    row.deskripsiController.text = (produk.deskripsi ?? '').trim();
  }

  String _kontakSearchLabel(KontakModel k) {
    final code = (k.kodeKontak ?? '').trim();
    final telp = (k.noTelp ?? '').trim();
    final codePart = code.isNotEmpty ? '$code - ' : '';
    final telpPart = telp.isNotEmpty ? ' | $telp' : '';
    return '$codePart${k.nama}$telpPart';
  }

  Future<void> _openKontakForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KontakFormScreen()),
    );
    if (mounted) {
      await Provider.of<KontakProvider>(context, listen: false)
          .fetchKontak(all: true);
    }
  }

  Future<void> _scanKontak() async {
    final provider = Provider.of<KontakProvider>(context, listen: false);
    await provider.fetchKontak(all: true);
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
    final scannedNoTelp =
        (result['no_telp'] ?? matched?.noTelp ?? '').toString().trim();
    final scannedAlamat =
        (result['alamat'] ?? matched?.alamat ?? '').toString().trim();
    setState(() {
      _selectedKontak = matched;
      _pelangganController.text = scannedName;
      _emailController.text = scannedNoTelp;
      _alamatPenagihanController.text = scannedAlamat;
    });
  }

  String _produkSearchLabel(ProdukModel p) {
    final code = (p.itemCode ?? '').trim();
    return code.isNotEmpty ? '$code - ${p.namaProduk}' : p.namaProduk;
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
      setState(() => _allowedProdukIds.clear());
      return;
    }
    setState(() => _isLoadingProdukGudang = true);
    try {
      final stokList = await Provider.of<GudangProvider>(context, listen: false)
          .fetchStok(gudangId: gudangId);
      if (!mounted) return;
      setState(() {
        _allowedProdukIds
          ..clear()
          ..addAll(stokList.map((s) => s.produkId));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _allowedProdukIds.clear());
    } finally {
      if (mounted) setState(() => _isLoadingProdukGudang = false);
    }
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
      _applySelectedProdukToRow(_items[rowIndex], matched);
    });
  }

  DateTime get _jatuhTempo {
    int days = 0;
    switch (_syaratPembayaran) {
      case 'Net 7':
        days = 7;
        break;
      case 'Net 14':
        days = 14;
        break;
      case 'Net 30':
        days = 30;
        break;
      case 'Net 60':
        days = 60;
        break;
    }
    return _tglTransaksi.add(Duration(days: days));
  }

  double _lineSubtotal(_ItemRow item) {
    final subtotal =
        item.qty * item.harga * (1 - item.diskon / 100) - item.diskonNominal;
    return subtotal < 0 ? 0 : subtotal;
  }

  double get _subTotal {
    double total = 0;
    for (final item in _items) {
      if (item.qty > 0) {
        total += _lineSubtotal(item);
      }
    }
    return total;
  }

  double get _jumlahPajak {
    double afterDiskon = _subTotal - _diskonAkhir;
    if (afterDiskon < 0) afterDiskon = 0;
    return afterDiskon * _taxPercentage / 100;
  }

  double get _grandTotal {
    double afterDiskon = _subTotal - _diskonAkhir;
    if (afterDiskon < 0) afterDiskon = 0;
    return afterDiskon + _jumlahPajak;
  }

  Future<void> _submit() async {
    if (!_canEditApproved()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Hanya superadmin yang dapat mengubah transaksi approved.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tambahkan minimal 1 item produk.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<PenjualanProvider>(context, listen: false);
      final loginName =
          Provider.of<AuthProvider>(context, listen: false).user?.name;
      final canEditHargaProduk = _canEditHargaProduk();
      final resolvedTag = _tagController.text.trim().isNotEmpty
          ? _tagController.text.trim()
          : (loginName?.trim().isNotEmpty == true ? loginName!.trim() : null);
      await provider.updatePenjualan(widget.data.id, {
        'pelanggan': _selectedKontak?.nama ?? _pelangganController.text,
        'no_telepon':
            _emailController.text.isNotEmpty ? _emailController.text : null,
        'alamat_penagihan': _alamatPenagihanController.text.isNotEmpty
            ? _alamatPenagihanController.text
            : null,
        'tgl_transaksi': _tglTransaksi.toIso8601String().split('T')[0],
        'syarat_pembayaran': _syaratPembayaran,
        'tipe_harga': _resolvedTipeHargaForApi(),
        'gudang_id': _gudangId,
        'no_referensi': _noReferensiController.text.isNotEmpty
            ? _noReferensiController.text
            : null,
        'koordinat': _koordinatController.text.isNotEmpty
            ? _koordinatController.text
            : null,
        'tag': resolvedTag,
        'tax_percentage': _taxPercentage,
        'diskon_akhir': _diskonAkhir,
        'memo': _memoController.text,
        'items': _items
            .where((i) => i.produkId != null || i.produk != null)
            .map((i) => {
                  'produk_id': i.produk?.id ?? i.produkId,
                  'kuantitas': i.qty,
                  'harga_satuan':
                      canEditHargaProduk ? i.harga : _hargaSatuanForSubmit(i),
                  'diskon': i.diskon,
                  'diskon_nominal': i.diskonNominal,
                  'deskripsi': i.deskripsiController.text.isNotEmpty
                      ? i.deskripsiController.text
                      : null,
                  'unit': i.unitController.text.isNotEmpty
                      ? i.unitController.text
                      : null,
                  'batch_number': i.batchController.text.isNotEmpty
                      ? i.batchController.text
                      : null,
                  'expired_date': i.expDate != null
                      ? i.expDate!.toIso8601String().split('T')[0]
                      : null,
                })
            .toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Penjualan berhasil diperbarui!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canEditApproved()) {
      return GlassScaffold(
        appBar: AppBar(
          title: const Text('Edit Penjualan'),
          flexibleSpace: Container(
              decoration:
                  BoxDecoration(gradient: AppTheme.mainGradient(context))),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Transaksi approved hanya bisa diedit oleh superadmin.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Edit Penjualan'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _pelangganController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Pelanggan (auto)',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            Consumer<KontakProvider>(
              builder: (ctx, kontakProvider, _) {
                if (_selectedKontak == null &&
                    _pelangganController.text.isNotEmpty) {
                  final matched =
                      kontakProvider.items.cast<KontakModel?>().firstWhere(
                            (k) =>
                                (k?.nama.toLowerCase() ?? '') ==
                                _pelangganController.text.toLowerCase(),
                            orElse: () => null,
                          );
                  if (matched != null) {
                    _selectedKontak = matched;
                  }
                }
                return SearchableDropdownFormField<KontakModel>(
                  value: _selectedKontak,
                  labelText: 'Pilih Pelanggan *',
                  hintText: 'Ketik nama / kode / no telp pelanggan...',
                  leadingIcon: const Icon(Icons.search, size: 20),
                  items: kontakProvider.items,
                  itemAsString: _kontakSearchLabel,
                  onChanged: (v) {
                    setState(() {
                      _selectedKontak = v;
                      _pelangganController.text = v?.nama ?? '';
                      _emailController.text = v?.noTelp ?? '';
                      _alamatPenagihanController.text = v?.alamat ?? '';
                    });
                  },
                  validator: (v) =>
                      (v == null && _pelangganController.text.isEmpty)
                          ? 'Wajib diisi'
                          : null,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'No. Telepon',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alamatPenagihanController,
              decoration: const InputDecoration(labelText: 'Alamat Penagihan'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DatePickerField(
              label: 'Tgl Transaksi *',
              selectedDate: _tglTransaksi,
              onDateSelected: (d) => setState(() => _tglTransaksi = d),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: [
                      'Cash',
                      'Net 7',
                      'Net 14',
                      'Net 30',
                      'Net 60'
                    ].contains(_syaratPembayaran)
                        ? _syaratPembayaran
                        : 'Cash',
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Syarat Pembayaran *'),
                    items: ['Cash', 'Net 7', 'Net 14', 'Net 30', 'Net 60']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _syaratPembayaran = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DatePickerField(
                    label: 'Jatuh Tempo (Auto)',
                    selectedDate: _jatuhTempo,
                    onDateSelected: (_) {},
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noReferensiController,
              decoration:
                  const InputDecoration(labelText: 'No. Referensi Pelanggan'),
            ),
            const SizedBox(height: 12),
            KoordinatLokasiField(controller: _koordinatController),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagController,
              readOnly: true,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                labelText: 'Tag (Sales)',
                prefixIcon: Icon(Icons.label_outline, size: 20),
                helperText: 'Otomatis dari akun login',
              ),
            ),
            const SizedBox(height: 12),
            Consumer<GudangProvider>(
              builder: (ctx, gudangProvider, _) {
                return DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _gudangId,
                  decoration: const InputDecoration(labelText: 'Gudang *'),
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
                  validator: (v) => v == null ? 'Pilih gudang' : null,
                );
              },
            ),
            if (_isGudangLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Gudang otomatis sesuai role akun Anda.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text('Tipe Harga *',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondaryColor(context))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _tipeHarga = 'Retail';
                      for (final item in _items) {
                        if (item.produk != null) {
                          item.harga = _resolvedHargaForProduk(item.produk);
                        }
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tipeHarga == 'Retail'
                            ? AppTheme.primaryColor
                            : AppTheme.cardBg(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _tipeHarga == 'Retail'
                                ? AppTheme.primaryColor
                                : AppTheme.borderColorOf(context)),
                      ),
                      child: Center(
                          child: Text('Retail',
                              style: TextStyle(
                                  color: _tipeHarga == 'Retail'
                                      ? Colors.white
                                      : AppTheme.textPrimaryColor(context),
                                  fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _tipeHarga = 'Grosir';
                      for (final item in _items) {
                        if (item.produk != null) {
                          item.harga = _resolvedHargaForProduk(item.produk);
                        }
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tipeHarga == 'Grosir'
                            ? AppTheme.successColor
                            : AppTheme.cardBg(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _tipeHarga == 'Grosir'
                                ? AppTheme.successColor
                                : AppTheme.borderColorOf(context)),
                      ),
                      child: Center(
                          child: Text('Grosir',
                              style: TextStyle(
                                  color: _tipeHarga == 'Grosir'
                                      ? Colors.white
                                      : AppTheme.textPrimaryColor(context),
                                  fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
              ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Text('Item Produk',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  onPressed: _addItem,
                ),
              ],
            ),
            Consumer<ProdukProvider>(
              builder: (ctx, produkProvider, _) {
                final produks = _gudangId == null
                    ? <ProdukModel>[]
                    : (_allowedProdukIds.isEmpty
                        ? produkProvider.items
                        : produkProvider.items
                            .where((p) => _allowedProdukIds.contains(p.id))
                            .toList());
                final canEditHargaProduk = _canEditHargaProduk();
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
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      SearchableDropdownFormField<ProdukModel>(
                                    value: matchedProduk,
                                    labelText: 'Produk',
                                    hintText: _gudangId == null
                                        ? 'Pilih gudang dulu'
                                        : (_isLoadingProdukGudang
                                            ? 'Memuat produk...'
                                            : 'Ketik nama/kode produk...'),
                                    enabled: _gudangId != null &&
                                        !_isLoadingProdukGudang,
                                    items: produks,
                                    itemAsString: _produkSearchLabel,
                                    onChanged: (v) {
                                      setState(() {
                                        _applySelectedProdukToRow(item, v);
                                      });
                                    },
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
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeItem(i),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: item.deskripsiController,
                              decoration: const InputDecoration(
                                  labelText: 'Deskripsi', isDense: true),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: item.qty.toString(),
                                    decoration: const InputDecoration(
                                        labelText: 'Qty', isDense: true),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setState(() =>
                                        item.qty = double.tryParse(v) ?? 0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: item.unitController,
                                    decoration: const InputDecoration(
                                        labelText: 'Unit', isDense: true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    key: ValueKey(
                                        'harga-$i-${item.produk?.id ?? item.produkId}-${item.harga}'),
                                    initialValue:
                                        Formatters.rupiahInput(item.harga),
                                    readOnly: !canEditHargaProduk,
                                    enableInteractiveSelection:
                                        canEditHargaProduk,
                                    decoration: InputDecoration(
                                      labelText: 'Harga',
                                      isDense: true,
                                      suffixIcon: canEditHargaProduk
                                          ? null
                                          : const Icon(Icons.lock_outline,
                                              size: 18),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: const [
                                      RupiahInputFormatter(),
                                    ],
                                    onChanged: canEditHargaProduk
                                        ? (v) => setState(() => item.harga =
                                            Formatters.parseRupiah(v) ?? 0)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    key: ValueKey('disc-$i-${item.diskon}'),
                                    initialValue: item.diskon > 0
                                        ? item.diskon.toString()
                                        : '0',
                                    decoration: const InputDecoration(
                                        labelText: 'Disc%', isDense: true),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (v) => setState(() =>
                                        item.diskon =
                                            Formatters.parseDecimal(v) ?? 0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Diskon Nominal (Rp) per item
                            TextFormField(
                              controller: item.diskonNominalController,
                              decoration: const InputDecoration(
                                labelText: 'Diskon Nominal (Rp)',
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: const [
                                RupiahInputFormatter(),
                              ],
                              onChanged: (v) => setState(() {
                                item.diskonNominal =
                                    Formatters.parseRupiah(v) ?? 0;
                              }),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: item.batchController,
                                    decoration: const InputDecoration(
                                        labelText: 'Batch', isDense: true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DatePickerField(
                                    label: 'Exp',
                                    selectedDate: item.expDate,
                                    firstDate: DateTime.now(),
                                    onDateSelected: (d) =>
                                        setState(() => item.expDate = d),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Jumlah: ${Formatters.currency(_lineSubtotal(item))}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: 'Memo (opsional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Flexible(
                            child: Text(Formatters.currency(_subTotal),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: ValueKey('diskonAkhir-$_diskonAkhir'),
                      initialValue: Formatters.rupiahInput(_diskonAkhir),
                      decoration: const InputDecoration(
                          labelText: 'Diskon Akhir (Rp)', isDense: true),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: const [RupiahInputFormatter()],
                      onChanged: (v) => setState(
                          () => _diskonAkhir = Formatters.parseRupiah(v) ?? 0),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: ValueKey('tax-$_taxPercentage'),
                      initialValue:
                          _taxPercentage > 0 ? _taxPercentage.toString() : '0',
                      decoration: const InputDecoration(
                          labelText: 'Pajak (%)', isDense: true),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => setState(() =>
                          _taxPercentage = Formatters.parseDecimal(v) ?? 0),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jumlah Pajak'),
                        Flexible(
                            child: Text(Formatters.currency(_jumlahPajak),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Flexible(
                          child: Text(
                            Formatters.currency(_grandTotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primaryColor),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            LampiranPickerWidget(
              files: _lampiran,
              onFilesChanged: (files) => setState(() => _lampiran = files),
              fileNamePrefix: (widget.data.nomor?.trim().isNotEmpty == true)
                  ? widget.data.nomor!.trim()
                  : 'INV',
              existingFileCount: widget.data.lampiranPaths?.length ?? 0,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan Perubahan',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  ProdukModel? produk;
  int? produkId;
  String? namaProduk;
  double qty = 1;
  double harga = 0;
  double diskon = 0;
  double diskonNominal = 0;
  DateTime? expDate;
  final deskripsiController = TextEditingController();
  final unitController = TextEditingController();
  final batchController = TextEditingController();
  final diskonNominalController = TextEditingController();
}
