import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biaya_provider.dart';
import '../../providers/kontak_provider.dart';
import '../../models/kontak_model.dart';
import '../../models/biaya_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/koordinat_lokasi_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/searchable_dropdown_form_field.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../kontak/kontak_form_screen.dart';
import '../../widgets/glass_container.dart';
import 'biaya_detail_screen.dart';

class BiayaCreateScreen extends StatefulWidget {
  const BiayaCreateScreen({super.key});

  @override
  State<BiayaCreateScreen> createState() => _BiayaCreateScreenState();
}

class _BiayaCreateScreenState extends State<BiayaCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _penerimaController = TextEditingController();
  final _memoController = TextEditingController();
  final _alamatPenagihanController = TextEditingController();
  final _koordinatController = TextEditingController();
  final _tagController = TextEditingController();
  KontakModel? _selectedKontak;

  DateTime _tglTransaksi = DateTime.now();
  String _jenisBiaya = 'Biaya Keluar';
  String _bayarDari = 'Kas';
  String _caraPembayaran = 'Tunai';
  bool _bayarNanti = false;
  double _taxPercentage = 0;
  final List<_BiayaItem> _items = [];
  List<PlatformFile> _lampiran = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KontakProvider>(context, listen: false).fetchKontak();
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
      await Provider.of<KontakProvider>(context, listen: false).fetchKontak();
    }
  }

  Future<void> _scanKontak() async {
    final provider = Provider.of<KontakProvider>(context, listen: false);
    provider.fetchKontak();
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
      final provider = Provider.of<BiayaProvider>(context, listen: false);
      final loginName =
          Provider.of<AuthProvider>(context, listen: false).user?.name;
      final resolvedTag = _tagController.text.trim().isNotEmpty
          ? _tagController.text.trim()
          : (loginName?.trim().isNotEmpty == true ? loginName!.trim() : null);
      final data = {
        'tgl_transaksi': _tglTransaksi.toIso8601String().split('T')[0],
        'jenis_biaya': _jenisBiaya,
        'bayar_dari': _bayarDari,
        'bayar_nanti': _bayarNanti,
        'penerima': _penerimaController.text,
        'cara_pembayaran': _caraPembayaran,
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
      };

      BiayaModel createdModel;
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
        createdModel = await provider.createBiayaMultipart(
          fields: fields,
          lampiran: paths,
        );
      } else {
        createdModel = await provider.createBiaya(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Biaya berhasil dibuat!'),
            backgroundColor: Colors.green));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BiayaDetailScreen(id: createdModel.id),
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
          title: const Text('Buat Biaya'),
          flexibleSpace: Container(
              decoration:
                  BoxDecoration(gradient: AppTheme.mainGradient(context)))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Jenis Biaya + Bayar Dari
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _jenisBiaya,
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
                    initialValue: _bayarDari,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Bayar Dari *'),
                    items: ['Kas', 'Bank']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _bayarDari = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bayar Nanti toggle
            SwitchListTile(
              title: const Text('Bayar Nanti'),
              value: _bayarNanti,
              onChanged: (v) => setState(() => _bayarNanti = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 8),

            // Penerima (Kontak)
            Consumer<KontakProvider>(
              builder: (ctx, kontakProvider, _) {
                return SearchableDropdownFormField<KontakModel>(
                  value: _selectedKontak,
                  labelText: 'Penerima (Kontak) *',
                  hintText: 'Pilih atau ketik kontak...',
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
                  validator: (v) => v == null ? 'Wajib diisi' : null,
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

            // Tgl Transaksi + Cara Pembayaran
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
                    initialValue: _caraPembayaran,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Cara Pembayaran'),
                    items: ['Tunai', 'Transfer', 'Cek & Giro']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _caraPembayaran = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Alamat Penagihan
            TextFormField(
              controller: _alamatPenagihanController,
              decoration: const InputDecoration(labelText: 'Alamat Penagihan'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Tag (Pembuat)
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag (Pembuat)',
                prefixIcon: Icon(Icons.label_outline, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Koordinat Lokasi
            KoordinatLokasiField(controller: _koordinatController),
            const SizedBox(height: 20),

            // Items
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                  child: Text('Item Biaya',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis)),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Data'),
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
                                        isDense: true,
                                        hintText: 'Contoh: Biaya Listrik'),
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
                            initialValue: _items[i].jumlah.toString(),
                            decoration: const InputDecoration(
                                labelText: 'Jumlah (Rp)', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() =>
                                _items[i].jumlah = double.tryParse(v) ?? 0),
                          ),
                        ]),
                      ),
                    )),
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
                                textAlign: TextAlign.end)),
                      ]),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Pajak (%)', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(
                        () => _taxPercentage = double.tryParse(v) ?? 0),
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

            // Lampiran
            LampiranPickerWidget(
              files: _lampiran,
              onFilesChanged: (files) => setState(() => _lampiran = files),
              fileNamePrefix: 'EXP',
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Buat Biaya Baru',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
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
