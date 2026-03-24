import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_container.dart';

class PenggunaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const PenggunaFormScreen({super.key, this.user});

  @override
  State<PenggunaFormScreen> createState() => _PenggunaFormScreenState();
}

class _PenggunaFormScreenState extends State<PenggunaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telpCtrl;
  late final TextEditingController _alamatCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _passwordConfirmCtrl;
  String _role = 'user';
  int? _gudangId;
  bool _isSubmitting = false;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.user?['name'] ?? '');
    _emailCtrl = TextEditingController(text: widget.user?['email'] ?? '');
    _telpCtrl = TextEditingController(text: widget.user?['no_telp'] ?? '');
    _alamatCtrl = TextEditingController(text: widget.user?['alamat'] ?? '');
    _passwordCtrl = TextEditingController();
    _passwordConfirmCtrl = TextEditingController();
    _role = widget.user?['role'] ?? 'user';
    _gudangId = widget.user?['gudang_id'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _telpCtrl.dispose();
    _alamatCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'name': _namaCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _role,
      'no_telp':
          _telpCtrl.text.trim().isNotEmpty ? _telpCtrl.text.trim() : null,
      'alamat':
          _alamatCtrl.text.trim().isNotEmpty ? _alamatCtrl.text.trim() : null,
    };

    if (_gudangId != null) {
      data['gudang_id'] = _gudangId;
    }

    if (_passwordCtrl.text.isNotEmpty) {
      data['password'] = _passwordCtrl.text;
    }

    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      if (isEdit) {
        await provider.updateUser(widget.user!['id'], data);
      } else {
        await provider.createUser(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isEdit ? 'Pengguna diperbarui' : 'Pengguna dibuat'),
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
        title: Text(isEdit ? 'Edit Pengguna' : 'Tambah User Baru'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nama & Email
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _namaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama wajib diisi'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Email wajib diisi'
                      : null,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // No. Telepon & Alamat
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _telpCtrl,
                  decoration: const InputDecoration(
                      labelText: 'No. Telepon', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _alamatCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Alamat', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Role & Gudang
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Role *', border: OutlineInputBorder()),
                  value: _role,
                  items: const [
                    DropdownMenuItem(
                        value: 'super_admin', child: Text('Super Admin')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'spectator', child: Text('Spectator')),
                    DropdownMenuItem(
                        value: 'user', child: Text('User (Sales)')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'user'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer<GudangProvider>(
                  builder: (ctx, gudangProvider, _) {
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _gudangId,
                      decoration: InputDecoration(
                        labelText: 'Gudang *',
                        hintText: '--- Pilih Gudang ---',
                        helperText: _role == 'user'
                            ? 'Wajib untuk role user'
                            : 'Wajib untuk role user, dan tidak digunakan oleh Admin & Spectator (di assign terpisah).',
                        helperMaxLines: 3,
                        border: const OutlineInputBorder(),
                      ),
                      items: gudangProvider.items
                          .map((g) => DropdownMenuItem(
                              value: g.id, child: Text(g.namaGudang)))
                          .toList(),
                      onChanged: (v) => setState(() => _gudangId = v),
                      validator: (v) {
                        if (_role == 'user' && v == null) {
                          return 'Gudang wajib dipilih untuk role user';
                        }
                        return null;
                      },
                    );
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Password & Konfirmasi Password
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Password' : 'Password *',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (!isEdit && (v == null || v.isEmpty)) {
                      return 'Password wajib diisi';
                    }
                    if (v != null && v.isNotEmpty && v.length < 8) {
                      return 'Minimal 8 karakter';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _passwordConfirmCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'Konfirmasi Password'
                        : 'Konfirmasi Password *',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (_passwordCtrl.text.isNotEmpty &&
                        v != _passwordCtrl.text) {
                      return 'Password tidak cocok';
                    }
                    if (!isEdit && (v == null || v.isEmpty)) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    return null;
                  },
                ),
              ),
            ]),
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
                      : Text(isEdit ? 'Simpan Perubahan' : 'Simpan User'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
