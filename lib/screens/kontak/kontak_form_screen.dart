import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kontak_model.dart';
import '../../providers/kontak_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_container.dart';

class KontakFormScreen extends StatefulWidget {
  final KontakModel? kontak;
  const KontakFormScreen({super.key, this.kontak});

  @override
  State<KontakFormScreen> createState() => _KontakFormScreenState();
}

class _KontakFormScreenState extends State<KontakFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kodeCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telpCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _alamatCtrl;
  late final TextEditingController _diskonCtrl;
  bool _isSubmitting = false;

  bool get isEdit => widget.kontak != null;

  @override
  void initState() {
    super.initState();
    _kodeCtrl = TextEditingController(text: widget.kontak?.kodeKontak ?? '');
    _namaCtrl = TextEditingController(text: widget.kontak?.nama ?? '');
    _emailCtrl = TextEditingController(text: widget.kontak?.email ?? '');
    _telpCtrl = TextEditingController(text: widget.kontak?.noTelp ?? '');
    _pinCtrl = TextEditingController(text: widget.kontak?.pin ?? '');
    _alamatCtrl = TextEditingController(text: widget.kontak?.alamat ?? '');
    _diskonCtrl = TextEditingController(
        text: widget.kontak?.diskonPersen?.toString() ?? '0');
  }

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _telpCtrl.dispose();
    _pinCtrl.dispose();
    _alamatCtrl.dispose();
    _diskonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'nama': _namaCtrl.text.trim(),
      'email':
          _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      'no_telp':
          _telpCtrl.text.trim().isNotEmpty ? _telpCtrl.text.trim() : null,
      'alamat':
          _alamatCtrl.text.trim().isNotEmpty ? _alamatCtrl.text.trim() : null,
      'diskon_persen':
          _diskonCtrl.text.isNotEmpty ? num.tryParse(_diskonCtrl.text) : null,
      if (_kodeCtrl.text.trim().isNotEmpty)
        'kode_kontak': _kodeCtrl.text.trim(),
      if (_pinCtrl.text.trim().isNotEmpty) 'pin': _pinCtrl.text.trim(),
    };

    try {
      final provider = Provider.of<KontakProvider>(context, listen: false);
      if (isEdit) {
        await provider.updateKontak(widget.kontak!.id, data);
      } else {
        await provider.createKontak(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isEdit ? 'Kontak diperbarui' : 'Kontak dibuat'),
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
        title: Text(isEdit ? 'Edit Kontak' : 'Tambah Kontak Baru'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextFormField(
              controller: _kodeCtrl,
              decoration: const InputDecoration(
                labelText: 'Kode Kontak',
                hintText: 'Kosongkan untuk auto-generate',
                helperText:
                    'Contoh: KTKOO1, CUST-001. Kosongkan untuk auto-generate.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nama Kontak *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telpCtrl,
              decoration: const InputDecoration(
                labelText: 'No. Telepon',
                hintText: '628xxxxxxxxxx',
                helperText:
                    'Format: 628xxxxxxxxxx. No. telepon akan menjadi username login jika diperlukan.',
                helperMaxLines: 3,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinCtrl,
              decoration: const InputDecoration(
                labelText: 'PIN Customer (6 digit)',
                hintText: 'Contoh: 123456',
                helperText:
                    'PIN untuk login portal customer. Kosongkan jika belum perlu.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamatCtrl,
              decoration: const InputDecoration(
                  labelText: 'Alamat', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diskonCtrl,
              decoration: const InputDecoration(
                  labelText: 'Diskon Bawaan (%)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
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
