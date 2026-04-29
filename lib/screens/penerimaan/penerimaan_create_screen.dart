import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/penerimaan_barang_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/glass_container.dart';

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
  Set<int> selectedPOIds = {};
  List<_PoOption> _poOptions = [];
  final List<_ItemRow> _items = [];
  List<PlatformFile> _lampiran = [];
  bool _isSubmitting = false;
  bool _isLoadingPO = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
    });
  }

  @override
  void dispose() {
    _noSuratJalanController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadPOsByGudang(int? gudangId) async {
    if (gudangId == null) {
      setState(() {
        _poOptions = [];
        selectedPOIds.clear();
        _items.clear();
      });
      return;
    }

    setState(() {
      _isLoadingPO = true;
      _poOptions = [];
      selectedPOIds.clear();
      _items.clear();
    });

    try {
      final provider =
          Provider.of<PenerimaanBarangProvider>(context, listen: false);
      final rawList = await provider.getPembelianByGudang(gudangId);
      final mapped = rawList
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .map(
            (row) => _PoOption(
              id: row['id'] is int
                  ? row['id'] as int
                  : int.tryParse('${row['id']}') ?? 0,
              nomor: (row['nomor'] ?? '').toString(),
              tglTransaksi: (row['tgl_transaksi'] ?? '').toString(),
            ),
          )
          .where((po) => po.id > 0)
          .toList();

      if (!mounted) return;
      setState(() => _poOptions = mapped);
    } catch (_) {
      if (!mounted) return;
      setState(() => _poOptions = []);
    } finally {
      if (mounted) setState(() => _isLoadingPO = false);
    }
  }

  Future<void> _updateSelectedPOs() async {
    if (selectedPOIds.isEmpty) {
      setState(() => _items.clear());
      return;
    }

    setState(() => _isLoadingPO = true);

    try {
      _items.clear();
      final provider =
          Provider.of<PenerimaanBarangProvider>(context, listen: false);
      for (final poId in selectedPOIds) {
        final detail = await provider.getPembelianDetail(poId);
        final detailItems = (detail['items'] as List? ?? const [])
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .toList();
        for (final item in detailItems) {
          _items.add(_ItemRow()
            ..produkId = int.tryParse('${item['produk_id']}')
            ..namaProduk =
                (item['nama_produk'] ?? 'Produk #${item['produk_id']}')
                    .toString()
            ..qtyPesan = double.tryParse(
                    '${item['qty_pesan'] ?? item['kuantitas'] ?? 0}') ??
                0
            ..qtyDiterima =
                double.tryParse('${item['qty_diterima'] ?? 0}') ?? 0);
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat detail PO: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPO = false);
    }
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
    if (selectedPOIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih minimal satu PO.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final provider =
          Provider.of<PenerimaanBarangProvider>(context, listen: false);
      final data = {
        'pembelian_ids': selectedPOIds.toList(),
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
        fields['pembelian_ids'] = selectedPOIds.join(',');
        fields['gudang_id'] = data['gudang_id'].toString();
        fields['tgl_penerimaan'] = data['tgl_penerimaan'].toString();
        fields['no_surat_jalan'] = data['no_surat_jalan'].toString();
        fields['keterangan'] = data['keterangan'].toString();
        final items = data['items'] as List;
        for (int idx = 0; idx < items.length; idx++) {
          (items[idx] as Map).forEach((k, v) {
            if (v != null) fields['items[$idx][$k]'] = v.toString();
          });
        }
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
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Buat Penerimaan Barang'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                  onChanged: (v) {
                    setState(() => _gudangId = v);
                    _loadPOsByGudang(v);
                  },
                  validator: (v) => v == null ? 'Pilih gudang' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // Pembelian (PO) - Multi-select with checkboxes
            if (_gudangId == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppTheme.infoColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih gudang untuk melihat daftar PO',
                        style:
                            TextStyle(color: AppTheme.infoColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoadingPO)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_poOptions.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: AppTheme.successColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tidak ada PO di gudang ini',
                        style: TextStyle(
                            color: AppTheme.successColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.glassBorderColor(context),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                      child: CheckboxListTile(
                        value: selectedPOIds.length == _poOptions.length &&
                            _poOptions.isNotEmpty,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedPOIds =
                                  _poOptions.map((e) => e.id).toSet();
                            } else {
                              selectedPOIds.clear();
                            }
                          });
                          _updateSelectedPOs();
                        },
                        title: const Text('Pilih Semua PO',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                        dense: false,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: AppTheme.dividerColorOf(context),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _poOptions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppTheme.dividerColorOf(context),
                      ),
                      itemBuilder: (_, idx) {
                        final po = _poOptions[idx];
                        return CheckboxListTile(
                          value: selectedPOIds.contains(po.id),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selectedPOIds.add(po.id);
                              } else {
                                selectedPOIds.remove(po.id);
                              }
                            });
                            _updateSelectedPOs();
                          },
                          title: Text(
                              po.nomor.isNotEmpty ? po.nomor : 'PO #${po.id}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 12)),
                          subtitle: Text(po.tglTransaksi),
                          dense: false,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
                  ],
                ),
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
                              firstDate: DateTime.now(),
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

class _PoOption {
  final int id;
  final String nomor;
  final String tglTransaksi;

  _PoOption({
    required this.id,
    required this.nomor,
    required this.tglTransaksi,
  });
}
