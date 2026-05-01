import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/pembayaran_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/glass_container.dart';

class PembayaranCreateScreen extends StatefulWidget {
  const PembayaranCreateScreen({super.key});

  @override
  State<PembayaranCreateScreen> createState() => _PembayaranCreateScreenState();
}

class _PembayaranCreateScreenState extends State<PembayaranCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahBayarController = TextEditingController();
  final _keteranganController = TextEditingController();

  DateTime _tglPembayaran = DateTime.now();
  String _metodePembayaran = 'Transfer Bank';
  int? _gudangId;
  Set<int> selectedInvoiceIds = {};
  List<_InvoiceOption> _invoiceOptions = [];
  List<PlatformFile> _lampiran = [];
  bool _isLoadingInvoices = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
    });
  }

  @override
  void dispose() {
    _jumlahBayarController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  double get _totalSelectedSisa => _invoiceOptions
      .where((inv) => selectedInvoiceIds.contains(inv.id))
      .fold<double>(0, (sum, inv) => sum + inv.sisaTagihan);

  Future<void> _loadInvoicesByGudang(int? gudangId) async {
    if (gudangId == null) {
      setState(() {
        _invoiceOptions = [];
        selectedInvoiceIds.clear();
      });
      return;
    }

    setState(() {
      _isLoadingInvoices = true;
      selectedInvoiceIds.clear();
    });

    try {
      final provider = Provider.of<PembayaranProvider>(context, listen: false);
      final rawList = await provider.getPenjualanByGudang(gudangId);
      final mapped = rawList
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .map(
            (row) => _InvoiceOption(
              id: row['id'] is int
                  ? row['id'] as int
                  : int.tryParse('${row['id']}') ?? 0,
              nomor: (row['nomor'] ?? '').toString(),
              pelanggan: (row['pelanggan'] ?? '').toString(),
              tglTransaksi: (row['tgl_transaksi'] ?? '').toString(),
              syaratPembayaran: (row['syarat_pembayaran'] ?? '').toString(),
              totalTagihan: double.tryParse('${row['grand_total'] ?? 0}') ?? 0,
              sudahBayar: double.tryParse(
                      '${row['total_bayar'] ?? row['sudah_bayar'] ?? 0}') ??
                  0,
              sisaTagihan: double.tryParse(
                      '${row['sisa_tagihan'] ?? row['sisa'] ?? row['sisa_pembayaran'] ?? 0}') ??
                  0,
            ),
          )
          .where((e) => e.id > 0 && e.sisaTagihan > 0)
          .toList();

      if (!mounted) return;
      setState(() => _invoiceOptions = mapped);
      _updateTotalBayar();
    } catch (_) {
      if (!mounted) return;
      setState(() => _invoiceOptions = []);
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvoices = false);
      }
    }
  }

  void _updateTotalBayar() {
    setState(() {
      _jumlahBayarController.text =
          _totalSelectedSisa > 0 ? Formatters.rupiahInput(_totalSelectedSisa) : '0';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedInvoiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu invoice'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<PembayaranProvider>(context, listen: false);
      final data = {
        'penjualan_ids': selectedInvoiceIds.toList(),
        'tgl_pembayaran': _tglPembayaran.toIso8601String().split('T')[0],
        'metode_pembayaran': _metodePembayaran,
        'jumlah_bayar': Formatters.parseRupiah(_jumlahBayarController.text) ?? 0,
        'keterangan': _keteranganController.text,
      };

      if (_lampiran.isNotEmpty) {
        final fields = <String, String>{};
        fields['penjualan_ids'] = selectedInvoiceIds.join(',');
        fields['tgl_pembayaran'] = data['tgl_pembayaran'].toString();
        fields['metode_pembayaran'] = data['metode_pembayaran'].toString();
        fields['jumlah_bayar'] = data['jumlah_bayar'].toString();
        fields['keterangan'] = data['keterangan'].toString();
        final paths =
            _lampiran.where((f) => f.path != null).map((f) => f.path!).toList();
        await provider.createPembayaranMultipart(
          fields: fields,
          lampiran: paths,
        );
      } else {
        await provider.createPembayaran(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pembayaran berhasil dibuat!'),
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
        title: const Text('Terima Pembayaran'),
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
                  onChanged: (v) {
                    setState(() => _gudangId = v);
                    _loadInvoicesByGudang(v);
                  },
                  validator: (v) => v == null ? 'Pilih gudang' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // Invoice Penjualan - Multi-select with checkboxes
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
                        'Pilih gudang untuk melihat daftar invoice',
                        style:
                            TextStyle(color: AppTheme.infoColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoadingInvoices)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_invoiceOptions.isEmpty)
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
                        'Semua invoice sudah lunas di gudang ini',
                        style: TextStyle(
                            color: AppTheme.successColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select All checkbox
                  CheckboxListTile(
                    value:
                        selectedInvoiceIds.length == _invoiceOptions.length &&
                            _invoiceOptions.isNotEmpty,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          selectedInvoiceIds =
                              _invoiceOptions.map((e) => e.id).toSet();
                        } else {
                          selectedInvoiceIds.clear();
                        }
                      });
                      _updateTotalBayar();
                    },
                    title: const Text('Pilih Semua Invoice',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 12),
                  // Invoice list
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppTheme.glassBorderColor(context)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _invoiceOptions.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (ctx, idx) {
                        final inv = _invoiceOptions[idx];
                        final isSelected = selectedInvoiceIds.contains(inv.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selectedInvoiceIds.add(inv.id);
                              } else {
                                selectedInvoiceIds.remove(inv.id);
                              }
                            });
                            _updateTotalBayar();
                          },
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inv.nomor.isNotEmpty
                                    ? inv.nomor
                                    : 'INV #${inv.id}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                inv.pelanggan,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                inv.tglTransaksi,
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                'Sisa: ${Formatters.currency(inv.sisaTagihan)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                    fontSize: 10),
                              ),
                            ],
                          ),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Total selected
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Piutang Terpilih:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                        Text(
                          Formatters.currency(_totalSelectedSisa),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Tanggal Pembayaran
            DatePickerField(
              label: 'Tanggal Pembayaran *',
              selectedDate: _tglPembayaran,
              onDateSelected: (d) => setState(() => _tglPembayaran = d),
            ),
            const SizedBox(height: 12),

            // Metode Pembayaran
            DropdownButtonFormField<String>(
              initialValue: _metodePembayaran,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Metode Pembayaran *'),
              items: ['Transfer Bank', 'Tunai', 'Giro', 'Cek', 'Lainnya']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _metodePembayaran = v!),
            ),
            const SizedBox(height: 12),

            // Jumlah Bayar - read-only, auto-filled from selected total
            TextFormField(
              controller: _jumlahBayarController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar (Rp) *',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
                helperText: 'Auto-filled dari total piutang terpilih',
              ),
              keyboardType: TextInputType.number,
              readOnly: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if ((Formatters.parseRupiah(v) ?? 0) <= 0) return 'Harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Keterangan
            TextFormField(
              controller: _keteranganController,
              decoration: const InputDecoration(labelText: 'Keterangan'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Lampiran
            LampiranPickerWidget(
              files: _lampiran,
              onFilesChanged: (files) => setState(() => _lampiran = files),
              fileNamePrefix: 'PAY',
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
                    : const Text('Simpan Pembayaran',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceOption {
  final int id;
  final String nomor;
  final String pelanggan;
  final String tglTransaksi;
  final String syaratPembayaran;
  final double totalTagihan;
  final double sudahBayar;
  final double sisaTagihan;

  _InvoiceOption({
    required this.id,
    required this.nomor,
    required this.pelanggan,
    required this.tglTransaksi,
    required this.syaratPembayaran,
    required this.totalTagihan,
    required this.sudahBayar,
    required this.sisaTagihan,
  });
}
