import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/penerimaan_barang_provider.dart';
import '../../providers/pembelian_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../models/pembelian_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/searchable_dropdown_form_field.dart';

class PenerimaanCreateScreen extends StatefulWidget {
  const PenerimaanCreateScreen({super.key});

  @override
  State<PenerimaanCreateScreen> createState() => _PenerimaanCreateScreenState();
}

class _PenerimaanCreateScreenState extends State<PenerimaanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noSuratJalanController = TextEditingController();
  final _keteranganController = TextEditingController();

  DateTime _tglPenerimaan = DateTime.now();
  int? _gudangId;
  PembelianModel? _selectedPO;
  final List<_ItemRow> _items = [];
  List<PlatformFile> _lampiran = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      Provider.of<PembelianProvider>(context, listen: false).fetchPembelian();
    });
  }

  @override
  void dispose() {
    _noSuratJalanController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _onPOSelected(PembelianModel? po) {
    setState(() {
      _selectedPO = po;
      _items.clear();
      if (po?.items != null) {
        for (final item in po!.items!) {
          _items.add(_ItemRow()
            ..produkId = item.produkId
            ..namaProduk = item.namaProduk ?? 'Produk #${item.produkId}'
            ..qtyPesan = (item.kuantitas ?? 0).toDouble()
            ..qtyDiterima = (item.kuantitas ?? 0).toDouble());
        }
      }
    });
  }

  int get _totalItemDiterima {
    double total = 0;
    for (final item in _items) {
      total += item.qtyDiterima;
    }
    return total.toInt();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPO == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih PO terlebih dahulu.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final provider =
          Provider.of<PenerimaanBarangProvider>(context, listen: false);
      final data = {
        'pembelian_id': _selectedPO!.id,
        'gudang_id': _gudangId,
        'tgl_penerimaan': _tglPenerimaan.toIso8601String().split('T')[0],
        'no_surat_jalan': _noSuratJalanController.text,
        'keterangan': _keteranganController.text,
        'items': _items
            .map((i) => {
                  'produk_id': i.produkId,
                  'qty_diterima': i.qtyDiterima,
                  'qty_reject': i.qtyDitolak,
                  'batch_number': i.batchController.text.isNotEmpty
                      ? i.batchController.text
                      : null,
                  'expired_date': i.expDate != null
                      ? i.expDate!.toIso8601String().split('T')[0]
                      : null,
                  'keterangan': i.keteranganController.text.isNotEmpty
                      ? i.keteranganController.text
                      : null,
                })
            .toList(),
      };

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
        await provider.createPenerimaanMultipart(
          fields: fields,
          lampiran: paths,
        );
      } else {
        await provider.createPenerimaan(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Penerimaan berhasil dibuat!'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Penerimaan Barang'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  onChanged: (v) => setState(() => _gudangId = v),
                  validator: (v) => v == null ? 'Pilih gudang' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // Pembelian (PO)
            Consumer<PembelianProvider>(
              builder: (ctx, pembelianProvider, _) {
                final poList = pembelianProvider.items
                    .where((p) => p.status == 'Approved')
                    .toList();
                return SearchableDropdownFormField<PembelianModel>(
                  value: _selectedPO,
                  labelText: 'Pembelian (PO) *',
                  hintText: 'Pilih atau ketik nomor PO...',
                  items: poList,
                  itemAsString: (p) {
                    final nomor = p.nomor ?? 'PO #${p.id}';
                    final pembuat = p.userName;
                    return pembuat == '-' ? nomor : '$nomor - $pembuat';
                  },
                  onChanged: _onPOSelected,
                  validator: (v) => v == null ? 'Pilih PO' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // Tanggal Penerimaan
            DatePickerField(
              label: 'Tanggal Penerimaan *',
              selectedDate: _tglPenerimaan,
              onDateSelected: (d) => setState(() => _tglPenerimaan = d),
            ),
            const SizedBox(height: 12),

            // No Surat Jalan
            TextFormField(
              controller: _noSuratJalanController,
              decoration: const InputDecoration(
                labelText: 'No. Surat Jalan',
              ),
            ),
            const SizedBox(height: 12),

            // Keterangan
            TextFormField(
              controller: _keteranganController,
              decoration: const InputDecoration(labelText: 'Keterangan'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Total Item Diterima indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Item Diterima',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('$_totalItemDiterima',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Items from PO
            if (_items.isNotEmpty) ...[
              Text('Detail Item',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.namaProduk,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Qty Pesan: ${item.qtyPesan.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor(context))),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item.qtyDiterima.toStringAsFixed(0),
                              decoration: const InputDecoration(
                                  labelText: 'Qty Diterima', isDense: true),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() =>
                                  item.qtyDiterima = double.tryParse(v) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.qtyDitolak.toStringAsFixed(0),
                              decoration: const InputDecoration(
                                  labelText: 'Qty Ditolak', isDense: true),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() =>
                                  item.qtyDitolak = double.tryParse(v) ?? 0),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
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
                              label: 'Exp Date',
                              selectedDate: item.expDate,
                              onDateSelected: (d) =>
                                  setState(() => item.expDate = d),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: item.keteranganController,
                          decoration: const InputDecoration(
                              labelText: 'Keterangan Item', isDense: true),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),

            // Lampiran
            LampiranPickerWidget(
              files: _lampiran,
              onFilesChanged: (files) => setState(() => _lampiran = files),
              fileNamePrefix: 'RCV',
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
                    : const Text('Simpan Penerimaan',
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
  int? produkId;
  String namaProduk = '';
  double qtyPesan = 0;
  double qtyDiterima = 0;
  double qtyDitolak = 0;
  DateTime? expDate;
  final batchController = TextEditingController();
  final keteranganController = TextEditingController();
}
