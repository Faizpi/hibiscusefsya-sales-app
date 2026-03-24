import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gudang_provider.dart';
import '../../models/produk_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_container.dart';

class GudangFormScreen extends StatefulWidget {
  final GudangModel? gudang;
  const GudangFormScreen({super.key, this.gudang});

  @override
  State<GudangFormScreen> createState() => _GudangFormScreenState();
}

class _GudangFormScreenState extends State<GudangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _alamatController;
  bool _isSubmitting = false;

  bool get _isEdit => widget.gudang != null;

  @override
  void initState() {
    super.initState();
    _namaController =
        TextEditingController(text: widget.gudang?.namaGudang ?? '');
    _alamatController =
        TextEditingController(text: widget.gudang?.alamatGudang ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<GudangProvider>(context, listen: false);
      final data = {
        'nama_gudang': _namaController.text.trim(),
        'alamat_gudang': _alamatController.text.trim(),
      };

      if (_isEdit) {
        await provider.updateGudang(widget.gudang!.id, data);
      } else {
        await provider.createGudang(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Gudang berhasil ${_isEdit ? 'diperbarui' : 'dibuat'}!'),
          backgroundColor: Colors.green,
        ));
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
        title: Text(_isEdit ? 'Edit Gudang' : 'Tambah Gudang'),
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
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Gudang *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama gudang wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alamatController,
              decoration:
                  const InputDecoration(labelText: 'Alamat Gudang (opsional)'),
              maxLines: 3,
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
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Gudang',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
