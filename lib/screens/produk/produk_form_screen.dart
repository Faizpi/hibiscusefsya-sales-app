import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/produk_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_container.dart';

class ProdukFormScreen extends StatefulWidget {
  final Map<String, dynamic>? produk;
  const ProdukFormScreen({super.key, this.produk});

  @override
  State<ProdukFormScreen> createState() => _ProdukFormScreenState();
}

class _ProdukFormScreenState extends State<ProdukFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _itemCodeCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _hargaGrosirCtrl;
  late final TextEditingController _deskripsiCtrl;
  String _satuan = 'Pcs';
  bool _isSubmitting = false;

  bool get isEdit => widget.produk != null;

  static const List<String> _satuanOptions = ['Pcs', 'Lusin', 'Karton'];

  @override
  void initState() {
    super.initState();
    _namaCtrl =
        TextEditingController(text: widget.produk?['nama_produk'] ?? '');
    _itemCodeCtrl =
        TextEditingController(text: widget.produk?['item_code'] ?? '');
    _hargaCtrl =
        TextEditingController(text: widget.produk?['harga']?.toString() ?? '');
    _hargaGrosirCtrl = TextEditingController(
        text: widget.produk?['harga_grosir']?.toString() ?? '0');
    _deskripsiCtrl =
        TextEditingController(text: widget.produk?['deskripsi'] ?? '');

    final existingSatuan = widget.produk?['satuan'] ?? 'Pcs';
    _satuan = _satuanOptions.contains(existingSatuan) ? existingSatuan : 'Pcs';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _itemCodeCtrl.dispose();
    _hargaCtrl.dispose();
    _hargaGrosirCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'nama_produk': _namaCtrl.text.trim(),
      'item_code': _itemCodeCtrl.text.trim().isNotEmpty
          ? _itemCodeCtrl.text.trim()
          : null,
      'harga': num.tryParse(_hargaCtrl.text) ?? 0,
      'harga_grosir': _hargaGrosirCtrl.text.isNotEmpty
          ? num.tryParse(_hargaGrosirCtrl.text)
          : null,
      'satuan': _satuan,
      'deskripsi': _deskripsiCtrl.text.trim().isNotEmpty
          ? _deskripsiCtrl.text.trim()
          : null,
    };

    try {
      final provider = Provider.of<ProdukProvider>(context, listen: false);
      if (isEdit) {
        await provider.updateProduk(widget.produk!['id'], data);
      } else {
        await provider.createProduk(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isEdit ? 'Produk diperbarui' : 'Produk dibuat'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nama Produk
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nama Produk *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Item Code & Harga Retail
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _itemCodeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Item Code (SKU)',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _hargaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Harga Retail *',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Harga wajib diisi' : null,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Harga Grosir
            TextFormField(
              controller: _hargaGrosirCtrl,
              decoration: const InputDecoration(
                  labelText: 'Harga Grosir', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Satuan dropdown
            DropdownButtonFormField<String>(
              value: _satuan,
              decoration: const InputDecoration(
                  labelText: 'Satuan *', border: OutlineInputBorder()),
              items: _satuanOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _satuan = v ?? 'Pcs'),
              validator: (v) => v == null ? 'Satuan wajib dipilih' : null,
            ),
            const SizedBox(height: 16),

            // Deskripsi
            TextFormField(
              controller: _deskripsiCtrl,
              decoration: const InputDecoration(
                  labelText: 'Deskripsi', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'Simpan' : 'Simpan'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
