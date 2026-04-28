import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pembelian_provider.dart';
import '../../providers/produk_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../models/produk_model.dart';
import '../../models/pembelian_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/koordinat_lokasi_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/searchable_dropdown_form_field.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../../widgets/glass_container.dart';
import 'pembelian_detail_screen.dart';

class PembelianCreateScreen extends StatefulWidget {
  const PembelianCreateScreen({super.key});

  @override
  State<PembelianCreateScreen> createState() => _PembelianCreateScreenState();
}

class _PembelianCreateScreenState extends State<PembelianCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  final _stafController = TextEditingController();
  final _emailStafController = TextEditingController();
  final _tahunAnggaranController = TextEditingController();
  final _koordinatController = TextEditingController();
  final _tagController = TextEditingController();

  DateTime _tglTransaksi = DateTime.now();
  String _syaratPembayaran = 'Cash';
  String _urgensi = 'Sedang';
  int? _gudangId;
  bool _isGudangLocked = false;
  bool _isLoadingProdukGudang = false;
  final Set<int> _allowedProdukIds = {};
  double _taxPercentage = 0;
  double _diskonAkhir = 0;
  final List<_ItemRow> _items = [];
  List<PlatformFile> _lampiran = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProdukProvider>(context, listen: false).fetchProduk();
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      _applyUserGudangRule();
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null && _tagController.text.trim().isEmpty) {
        _tagController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _stafController.dispose();
    _emailStafController.dispose();
    _tahunAnggaranController.dispose();
    _koordinatController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_ItemRow()));
  void _removeItem(int i) => setState(() => _items.removeAt(i));

  void _applySelectedProdukToRow(_ItemRow row, ProdukModel? produk) {
    row.produk = produk;
    row.harga = (produk?.harga ?? 0).toDouble();
    if (produk == null) return;
    row.unitController.text = (produk.satuan?.trim().isNotEmpty == true)
        ? produk.satuan!.trim()
        : 'Pcs';
    row.deskripsiController.text = (produk.deskripsi ?? '').trim();
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
    setState(() => _applySelectedProdukToRow(_items[rowIndex], matched));
  }

  String _produkSearchLabel(ProdukModel p) {
    final code = (p.itemCode ?? '').trim();
    return code.isNotEmpty ? '$code - ${p.namaProduk}' : p.namaProduk;
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

  double get _subTotal {
    double total = 0;
    for (final item in _items) {
      if (item.produk != null && item.qty > 0) {
        total += item.qty * item.harga * (1 - item.diskon / 100);
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
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tambahkan minimal 1 item.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final selectedItems = _items.where((i) => i.produk != null).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 produk pada item.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (final item in selectedItems) {
      if (item.qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Qty item harus lebih dari 0.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (item.harga < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga item tidak boleh negatif.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (item.unitController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unit item wajib diisi.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<PembelianProvider>(context, listen: false);
      final loginName =
          Provider.of<AuthProvider>(context, listen: false).user?.name;
      final resolvedTag = _tagController.text.trim().isNotEmpty
          ? _tagController.text.trim()
          : (loginName?.trim().isNotEmpty == true ? loginName!.trim() : null);
      final data = {
        'tgl_transaksi': _tglTransaksi.toIso8601String().split('T')[0],
        'syarat_pembayaran': _syaratPembayaran,
        'urgensi': _urgensi,
        'gudang_id': _gudangId,
        'tahun_anggaran': _tahunAnggaranController.text.isNotEmpty
            ? _tahunAnggaranController.text
            : null,
        'staf_penyetuju':
            _stafController.text.isNotEmpty ? _stafController.text : null,
        'email_penyetuju': _emailStafController.text.isNotEmpty
            ? _emailStafController.text
            : null,
        'koordinat': _koordinatController.text.isNotEmpty
            ? _koordinatController.text
            : null,
        'tag': resolvedTag,
        'tax_percentage': _taxPercentage,
        'diskon_akhir': _diskonAkhir,
        'memo': _memoController.text,
        'items': selectedItems
            .map((i) => {
                  'produk_id': i.produk!.id,
                  'kuantitas': i.qty,
                  'harga_satuan': i.harga,
                  'diskon': i.diskon,
                  'deskripsi': i.deskripsiController.text.isNotEmpty
                      ? i.deskripsiController.text
                      : null,
                  'unit': i.unitController.text.isNotEmpty
                      ? i.unitController.text
                      : null,
                })
            .toList(),
      };

      PembelianModel createdModel;
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
        createdModel = await provider.createPembelianMultipart(
          fields: fields,
          lampiran: paths,
        );
      } else {
        createdModel = await provider.createPembelian(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pembelian berhasil dibuat!'),
            backgroundColor: Colors.green));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PembelianDetailScreen(id: createdModel.id),
          ),
        );
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
          title: const Text('Buat Permintaan Pembelian'),
          flexibleSpace: Container(
              decoration:
                  BoxDecoration(gradient: AppTheme.mainGradient(context)))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tgl Transaksi + Syarat Pembayaran + Jatuh Tempo
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
                    initialValue: _syaratPembayaran,
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

            // Urgensi
            DropdownButtonFormField<String>(
              initialValue: _urgensi,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Urgensi *'),
              items: ['Segera', 'Sedang', 'Tidak Mendesak']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _urgensi = v!),
            ),
            const SizedBox(height: 12),

            // Gudang
            Consumer<GudangProvider>(
              builder: (ctx, gudangProvider, _) {
                return DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _gudangId,
                  decoration: const InputDecoration(
                    labelText: 'Gudang *',
                    hintText: 'Pilih Gudang...',
                  ),
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
            const SizedBox(height: 12),
            if (_isGudangLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Gudang otomatis sesuai role akun Anda.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ),

            // Tahun Anggaran
            TextFormField(
                controller: _tahunAnggaranController,
                decoration: const InputDecoration(
                    labelText: 'Tahun Anggaran (opsional)'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),

            // Tag (Pembuat)
            TextFormField(
              controller: _tagController,
              readOnly: true,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                labelText: 'Tag (Pembuat)',
                prefixIcon: Icon(Icons.label_outline, size: 20),
                helperText: 'Otomatis dari akun login',
              ),
            ),
            const SizedBox(height: 12),

            // Koordinat Lokasi
            KoordinatLokasiField(controller: _koordinatController),
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

            // Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Text('Item Produk',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis)),
                TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Baris'),
                    onPressed: _addItem),
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
                return Column(
                  children: List.generate(_items.length, (i) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          Row(children: [
                            Expanded(
                              child: SearchableDropdownFormField<ProdukModel>(
                                value: _items[i].produk,
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
                                onChanged: (v) => setState(() {
                                  _applySelectedProdukToRow(_items[i], v);
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
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(i)),
                          ]),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _items[i].deskripsiController,
                            decoration: const InputDecoration(
                                labelText: 'Deskripsi', isDense: true),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                flex: 1,
                                child: TextFormField(
                                    initialValue: _items[i].qty.toString(),
                                    decoration: const InputDecoration(
                                        labelText: 'Qty', isDense: true),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setState(() => _items[i]
                                        .qty = double.tryParse(v) ?? 0))),
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _items[i].unitController,
                                  decoration: const InputDecoration(
                                      labelText: 'Unit', isDense: true),
                                )),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                flex: 2,
                                child: TextFormField(
                                    key: ValueKey(
                                        'harga-$i-${_items[i].produk?.id}-${_items[i].harga}'),
                                    initialValue: _items[i].harga.toString(),
                                    decoration: const InputDecoration(
                                        labelText: 'Harga', isDense: true),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setState(() => _items[i]
                                        .harga = double.tryParse(v) ?? 0))),
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 1,
                                child: TextFormField(
                                    initialValue: _items[i].diskon.toString(),
                                    decoration: const InputDecoration(
                                        labelText: 'Disc%', isDense: true),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setState(() => _items[i]
                                        .diskon = double.tryParse(v) ?? 0))),
                          ]),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: ${Formatters.currency(_items[i].produk != null ? _items[i].qty * _items[i].harga * (1 - _items[i].diskon / 100) : 0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor),
                            ),
                          ),
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
                decoration: const InputDecoration(labelText: 'Memo (opsional)'),
                maxLines: 3),
            const SizedBox(height: 16),

            // Totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Flexible(
                            child: Text(Formatters.currency(_subTotal),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end))
                      ]),
                  const SizedBox(height: 8),
                  TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Diskon Akhir (Rp)', isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(
                          () => _diskonAkhir = double.tryParse(v) ?? 0)),
                  const SizedBox(height: 8),
                  TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Pajak (%)', isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(
                          () => _taxPercentage = double.tryParse(v) ?? 0)),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jumlah Pajak'),
                        Flexible(
                            child: Text(Formatters.currency(_jumlahPajak),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end)),
                      ]),
                  const Divider(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Flexible(
                          child: Text(Formatters.currency(_grandTotal),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end),
                        ),
                      ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Lampiran
            LampiranPickerWidget(
              files: _lampiran,
              onFilesChanged: (files) => setState(() => _lampiran = files),
              fileNamePrefix: 'PR',
            ),
            const SizedBox(height: 24),

            // Submit
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
                    : const Text('Simpan Pembelian',
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
  double qty = 1;
  double harga = 0;
  double diskon = 0;
  final deskripsiController = TextEditingController();
  final unitController = TextEditingController();
}
