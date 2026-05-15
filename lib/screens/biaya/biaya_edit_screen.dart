import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/biaya_model.dart';
import '../../models/kontak_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biaya_provider.dart';
import '../../providers/kontak_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/koordinat_lokasi_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/searchable_dropdown_form_field.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../kontak/kontak_form_screen.dart';
import '../../widgets/glass_container.dart';

class BiayaEditScreen extends StatefulWidget {
  final BiayaModel data;
  const BiayaEditScreen({super.key, required this.data});

  @override
  State<BiayaEditScreen> createState() => _BiayaEditScreenState();
}

class _BiayaEditScreenState extends State<BiayaEditScreen> {
  static const List<String> _bayarDariOptions = ['Kas', 'Bank'];
  static const List<String> _caraPembayaranOptions = [
    'Tunai',
    'Transfer',
    'Cek & Giro'
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _penerimaController;
  late final TextEditingController _memoController;
  late final TextEditingController _alamatPenagihanController;
  late final TextEditingController _koordinatController;
  late final TextEditingController _tagController;
  KontakModel? _selectedKontak;

  late DateTime _tglTransaksi;
  late String _jenisBiaya;
  late String _bayarDari;
  late String _caraPembayaran;
  late double _taxPercentage;
  final List<_BiayaItem> _items = [];
  List<PlatformFile> _lampiran = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _penerimaController = TextEditingController(text: d.penerima ?? '');
    _memoController = TextEditingController(text: d.memo ?? '');
    _alamatPenagihanController =
        TextEditingController(text: d.alamatPenagihan ?? '');
    _koordinatController = TextEditingController(text: d.koordinat ?? '');
    _tagController = TextEditingController(text: d.tag ?? '');
    _tglTransaksi = d.tglTransaksi != null
        ? DateTime.tryParse(d.tglTransaksi!) ?? DateTime.now()
        : DateTime.now();
    _jenisBiaya = d.jenisBiaya ?? 'Biaya Keluar';
    _bayarDari = _normalizeBayarDari(d.bayarDari);
    _caraPembayaran = _normalizeCaraPembayaran(d.caraPembayaran);
    _taxPercentage = (d.taxPercentage ?? 0).toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KontakProvider>(context, listen: false)
          .fetchKontak(all: true);
      _applyUserDefaults();
    });

    if (d.items != null) {
      for (final item in d.items!) {
        _items.add(_BiayaItem()
          ..kategoriController.text = item.kategori ?? ''
          ..deskripsiController.text = item.deskripsi ?? ''
          ..jumlah = (item.jumlah ?? 0).toDouble());
      }
    }
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
    _penerimaController.dispose();
    _memoController.dispose();
    _alamatPenagihanController.dispose();
    _koordinatController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_BiayaItem()));
  void _removeItem(int i) => setState(() => _items.removeAt(i));

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
    final scannedAlamat =
        (result['alamat'] ?? matched?.alamat ?? '').toString().trim();
    setState(() {
      _selectedKontak = matched;
      _penerimaController.text = scannedName;
      _alamatPenagihanController.text = scannedAlamat;
    });
  }

  String _kontakSearchLabel(KontakModel k) {
    final code = (k.kodeKontak ?? '').trim();
    final telp = (k.noTelp ?? '').trim();
    final codePart = code.isNotEmpty ? '$code - ' : '';
    final telpPart = telp.isNotEmpty ? ' | $telp' : '';
    return '$codePart${k.nama}$telpPart';
  }

  String _normalizeBayarDari(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.contains('bank')) return 'Bank';
    return 'Kas';
  }

  String _normalizeCaraPembayaran(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw == 'giro' || raw == 'cek' || raw == 'cek & giro') {
      return 'Cek & Giro';
    }
    if (raw == 'transfer') return 'Transfer';
    return 'Tunai';
  }

  double get _subTotal => _items.fold(0, (sum, item) => sum + item.jumlah);
  double get _jumlahPajak => _subTotal * _taxPercentage / 100;
  double get _grandTotal => _subTotal + _jumlahPajak;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tambahkan minimal 1 item.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final loginName =
          Provider.of<AuthProvider>(context, listen: false).user?.name;
      final resolvedTag = _tagController.text.trim().isNotEmpty
          ? _tagController.text.trim()
          : (loginName?.trim().isNotEmpty == true ? loginName!.trim() : null);
      await Provider.of<BiayaProvider>(context, listen: false)
          .updateBiaya(widget.data.id, {
        'tgl_transaksi': _tglTransaksi.toIso8601String().split('T')[0],
        'jenis_biaya': _jenisBiaya,
        'bayar_dari': _bayarDari,
        'cara_pembayaran': _caraPembayaran,
        'penerima': _selectedKontak?.nama ?? _penerimaController.text,
        'alamat_penagihan': _alamatPenagihanController.text.isNotEmpty
            ? _alamatPenagihanController.text
            : null,
        'koordinat': _koordinatController.text.isNotEmpty
            ? _koordinatController.text
            : null,
        'tag': resolvedTag,
        'tax_percentage': _taxPercentage,
        'memo': _memoController.text,
        'items': _items
            .map((i) => {
                  'kategori': i.kategoriController.text,
                  'deskripsi': i.deskripsiController.text,
                  'jumlah': i.jumlah,
                })
            .toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Biaya berhasil diperbarui!'),
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
        title: const Text('Edit Biaya'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        ['Biaya Keluar', 'Biaya Masuk'].contains(_jenisBiaya)
                            ? _jenisBiaya
                            : 'Biaya Keluar',
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Jenis Biaya *'),
                    items: ['Biaya Keluar', 'Biaya Masuk']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _jenisBiaya = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _bayarDariOptions.contains(_bayarDari)
                        ? _bayarDari
                        : 'Kas',
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Bayar Dari *'),
                    items: _bayarDariOptions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _bayarDari = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<KontakProvider>(
              builder: (ctx, kontakProvider, _) {
                if (_selectedKontak == null &&
                    _penerimaController.text.isNotEmpty) {
                  final matched =
                      kontakProvider.items.cast<KontakModel?>().firstWhere(
                            (k) =>
                                (k?.nama.toLowerCase() ?? '') ==
                                _penerimaController.text.toLowerCase(),
                            orElse: () => null,
                          );
                  if (matched != null) {
                    _selectedKontak = matched;
                  }
                }
                return SearchableDropdownFormField<KontakModel>(
                  value: _selectedKontak,
                  labelText: 'Penerima (Kontak) *',
                  hintText: 'Ketik nama / kode / no telp kontak...',
                  leadingIcon: const Icon(Icons.person_outline, size: 20),
                  items: kontakProvider.items,
                  itemAsString: _kontakSearchLabel,
                  onChanged: (v) {
                    setState(() {
                      _selectedKontak = v;
                      _penerimaController.text = v?.nama ?? '';
                      _alamatPenagihanController.text = v?.alamat ?? '';
                    });
                  },
                  validator: (v) =>
                      (v == null && _penerimaController.text.isEmpty)
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
                    label: const Text('Scan Kontak'),
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
            Row(
              children: [
                Expanded(
                  child: DatePickerField(
                    label: 'Tgl Transaksi *',
                    selectedDate: _tglTransaksi,
                    onDateSelected: (d) => setState(() => _tglTransaksi = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        _caraPembayaranOptions.contains(_caraPembayaran)
                            ? _caraPembayaran
                            : 'Tunai',
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Cara Pembayaran'),
                    items: _caraPembayaranOptions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _caraPembayaran = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alamatPenagihanController,
              decoration: const InputDecoration(labelText: 'Alamat Penagihan'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag (Pembuat)',
                prefixIcon: Icon(Icons.label_outline, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            KoordinatLokasiField(controller: _koordinatController),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                  child: Text('Item Biaya',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis)),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  onPressed: _addItem),
            ]),
            ...List.generate(
                _items.length,
                (i) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          Row(children: [
                            Expanded(
                                child: TextFormField(
                                    controller: _items[i].kategoriController,
                                    decoration: const InputDecoration(
                                        labelText: 'Akun/Biaya (Kategori)',
                                        isDense: true),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Wajib'
                                        : null)),
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(i)),
                          ]),
                          const SizedBox(height: 8),
                          TextFormField(
                              controller: _items[i].deskripsiController,
                              decoration: const InputDecoration(
                                  labelText: 'Deskripsi', isDense: true)),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('jumlah-$i-${_items[i].jumlah}'),
                            initialValue:
                                Formatters.rupiahInput(_items[i].jumlah),
                            decoration: const InputDecoration(
                                labelText: 'Jumlah (Rp)', isDense: true),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: const [
                              RupiahInputFormatter(),
                            ],
                            onChanged: (v) => setState(() => _items[i].jumlah =
                                Formatters.parseRupiah(v) ?? 0),
                          ),
                        ]),
                      ),
                    )),
            const SizedBox(height: 16),
            TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: 'Memo (opsional)'),
                maxLines: 3),
            const SizedBox(height: 16),
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
                                textAlign: TextAlign.end)),
                      ]),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('tax-$_taxPercentage'),
                    initialValue:
                        _taxPercentage > 0 ? _taxPercentage.toString() : '0',
                    decoration: const InputDecoration(
                        labelText: 'Pajak (%)', isDense: true),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(
                        () => _taxPercentage = Formatters.parseDecimal(v) ?? 0),
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
                      ]),
                  const Divider(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Flexible(
                          child: Text(Formatters.currency(_grandTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryColor),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end),
                        ),
                      ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            LampiranPickerWidget(
              files: _lampiran,
              onFilesChanged: (files) => setState(() => _lampiran = files),
              fileNamePrefix: (widget.data.nomor?.trim().isNotEmpty == true)
                  ? widget.data.nomor!.trim()
                  : 'EXP',
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

class _BiayaItem {
  final kategoriController = TextEditingController();
  final deskripsiController = TextEditingController();
  double jumlah = 0;
}
