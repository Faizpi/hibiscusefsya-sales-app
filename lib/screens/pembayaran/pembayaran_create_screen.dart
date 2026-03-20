import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/pembayaran_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/lampiran_picker_widget.dart';
import '../../widgets/searchable_dropdown_form_field.dart';

class PembayaranCreateScreen extends StatefulWidget {
  const PembayaranCreateScreen({super.key});

  @override
  State<PembayaranCreateScreen> createState() => _PembayaranCreateScreenState();
}

class _PembayaranCreateScreenState extends State<PembayaranCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _jumlahBayarController = TextEditingController();
  final _keteranganController = TextEditingController();

  DateTime _tglPembayaran = DateTime.now();
  String _metodePembayaran = 'Transfer Bank';
  int? _gudangId;
  _InvoiceOption? _selectedInvoice;
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
    _invoiceController.dispose();
    _jumlahBayarController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoicesByGudang(int? gudangId) async {
    if (gudangId == null) {
      setState(() {
        _invoiceOptions = [];
        _selectedInvoice = null;
        _invoiceController.clear();
      });
      return;
    }

    setState(() {
      _isLoadingInvoices = true;
      _selectedInvoice = null;
      _invoiceController.clear();
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
            ),
          )
          .where((e) => e.id > 0)
          .toList();

      if (!mounted) return;
      setState(() => _invoiceOptions = mapped);
    } catch (_) {
      if (!mounted) return;
      setState(() => _invoiceOptions = []);
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvoices = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<PembayaranProvider>(context, listen: false);
      final data = {
        'penjualan_id':
            _selectedInvoice?.id ?? int.tryParse(_invoiceController.text),
        'tgl_pembayaran': _tglPembayaran.toIso8601String().split('T')[0],
        'metode_pembayaran': _metodePembayaran,
        'jumlah_bayar': double.tryParse(_jumlahBayarController.text) ?? 0,
        'keterangan': _keteranganController.text,
      };

      if (_lampiran.isNotEmpty) {
        final fields = <String, String>{};
        data.forEach((key, value) {
          if (value != null) fields[key] = value.toString();
        });
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
    return Scaffold(
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

            // Invoice Penjualan
            SearchableDropdownFormField<_InvoiceOption>(
              value: _selectedInvoice,
              enabled: _gudangId != null && !_isLoadingInvoices,
              labelText: 'Invoice Penjualan *',
              hintText: _gudangId == null
                  ? 'Pilih gudang dulu'
                  : (_isLoadingInvoices
                      ? 'Memuat invoice...'
                      : 'Pilih atau ketik invoice...'),
              leadingIcon: const Icon(Icons.receipt_long, size: 20),
              items: _invoiceOptions,
              itemAsString: (invoice) {
                final nomor = invoice.nomor.isNotEmpty
                    ? invoice.nomor
                    : 'INV #${invoice.id}';
                final pelanggan = invoice.pelanggan;
                return pelanggan.isNotEmpty ? '$nomor - $pelanggan' : nomor;
              },
              onChanged: (selected) {
                setState(() {
                  _selectedInvoice = selected;
                  _invoiceController.text = selected?.id.toString() ?? '';
                });
              },
              validator: (v) => v == null ? 'Wajib diisi' : null,
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

            // Jumlah Bayar
            TextFormField(
              controller: _jumlahBayarController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar (Rp) *',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if ((double.tryParse(v) ?? 0) <= 0) return 'Harus lebih dari 0';
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

  _InvoiceOption({
    required this.id,
    required this.nomor,
    required this.pelanggan,
  });
}
