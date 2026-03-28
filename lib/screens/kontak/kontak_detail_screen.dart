import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kontak_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kontak_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import 'kontak_form_screen.dart';
import '../../widgets/glass_container.dart';

class KontakDetailScreen extends StatefulWidget {
  final int id;
  const KontakDetailScreen({super.key, required this.id});

  @override
  State<KontakDetailScreen> createState() => _KontakDetailScreenState();
}

class _KontakDetailScreenState extends State<KontakDetailScreen> {
  KontakModel? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      _data = await Provider.of<KontakProvider>(context, listen: false)
          .getDetail(widget.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _delete() async {
    final kontakProvider = Provider.of<KontakProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kontak'),
        content: const Text('Yakin ingin menghapus kontak ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await kontakProvider.deleteKontak(widget.id);
        if (!mounted) return;
        navigator.pop(true);
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return GlassScaffold(
      appBar: AppBar(
        title: Text(_data?.nama ?? 'Detail Kontak'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
        actions: [
          if (_data != null &&
              user != null &&
              (user.isAdmin || user.isSuperAdmin))
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => KontakFormScreen(kontak: _data)));
                  if (!mounted) return;
                  if (result == true) _loadDetail();
                }
                if (val == 'delete') _delete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const AppDetailSkeleton()
          : _data == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            _data!.nama.isNotEmpty
                                ? _data!.nama[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                          child: Text(_data!.nama,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold))),
                      if (_data!.kodeKontak != null)
                        Center(
                            child: Text(_data!.kodeKontak!,
                                style: TextStyle(
                                    color:
                                        AppTheme.textTertiaryColor(context)))),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            _InfoRow('Email', _data!.email ?? '-'),
                            _InfoRow('Telepon', _data!.noTelp ?? '-'),
                            _InfoRow(
                                'PIN',
                                _data!.pin != null && _data!.pin!.isNotEmpty
                                    ? '******'
                                    : '-'),
                            _InfoRow('Alamat', _data!.alamat ?? '-'),
                            _InfoRow(
                                'Diskon',
                                _data!.diskonPersen != null
                                    ? '${_data!.diskonPersen}%'
                                    : '-'),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Text(':',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondaryColor(context))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
