import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kunjungan_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kunjungan_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/app_theme.dart';
import '../../utils/detail_print_actions_helper.dart';
import '../../widgets/app_skeletons.dart';
import 'kunjungan_edit_screen.dart';
import '../../widgets/lampiran_section.dart';
import '../../widgets/glass_container.dart';

class KunjunganDetailScreen extends StatefulWidget {
  final int id;
  const KunjunganDetailScreen({super.key, required this.id});

  @override
  State<KunjunganDetailScreen> createState() => _KunjunganDetailScreenState();
}

class _KunjunganDetailScreenState extends State<KunjunganDetailScreen> {
  KunjunganModel? _data;
  bool _isLoading = true;
  String? _error;

  bool _canEditForCurrentUser(UserModel user, String status) {
    if (!user.hasPermission('can_edit_transaction') || user.isSpectator) {
      return false;
    }
    if (status == 'Pending') return true;
    return status == 'Approved' && user.isSuperAdmin;
  }

  bool _canCancelForCurrentUser(UserModel user, String status) {
    if (status == 'Pending') {
      return user.hasPermission('can_cancel_transaction');
    }
    if (status == 'Approved') {
      return user.isSuperAdmin &&
          user.hasPermission('can_cancel_approved_transaction');
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _data = await Provider.of<KunjunganProvider>(context, listen: false)
          .getDetail(widget.id);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return GlassScaffold(
      appBar: AppBar(
        title: Text(_data?.nomor ?? 'Detail Kunjungan'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
        actions: [
          ...DetailPrintActionsHelper.buildAppBarActions(
            context: context,
            type: 'kunjungan',
            id: widget.id,
            bluetoothSupported: true,
          ),
          if (_data != null &&
              user != null &&
              _canEditForCurrentUser(user, _data!.status))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KunjunganEditScreen(data: _data!),
                  ),
                );
                if (result == true) _loadDetail();
              },
            ),
          if (_data != null && user != null)
            Builder(builder: (ctx) {
              final status = _data!.status;
              final canApprove =
                  user.hasPermission('can_approve_transaction') &&
                      status == 'Pending';
              final canCancel = _canCancelForCurrentUser(user, status);
              final canUncancel =
                  user.hasPermission('can_uncancel_transaction') &&
                      status == 'Canceled';
              final menuItems = <PopupMenuEntry<String>>[
                if (canApprove)
                  const PopupMenuItem(value: 'approve', child: Text('Approve')),
                if (canCancel)
                  const PopupMenuItem(value: 'cancel', child: Text('Batalkan')),
                if (canUncancel)
                  const PopupMenuItem(
                      value: 'uncancel', child: Text('Uncancel')),
              ];
              if (menuItems.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (_) => menuItems,
              );
            }),
        ],
      ),
      body: _isLoading
          ? const AppDetailSkeleton()
          : _error != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                          onPressed: _loadDetail,
                          child: const Text('Coba Lagi')),
                    ]))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final derivedTipeStok = _deriveTipeStok(d.tujuan);
    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(d.nomor ?? '-',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: AppTheme.statusColor(d.status)
                                    .withAlpha(38),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(d.status,
                                style: TextStyle(
                                    color: AppTheme.statusColor(d.status),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                    const Divider(height: 24),
                    _InfoRow('Tujuan', d.tujuan ?? '-'),
                    _InfoRow('Tanggal', Formatters.date(d.tglKunjungan)),
                    _InfoRow('Pembuat', d.user?['name'] ?? '-'),
                    if (d.approver != null)
                      _InfoRow('Approver', d.approver?['name'] ?? '-'),
                    _InfoRow('Gudang', d.gudang?['nama_gudang'] ?? '-'),
                    const Divider(height: 16),
                    _InfoRow(
                      'Pelanggan',
                      d.salesNama?.isNotEmpty == true
                          ? d.salesNama!
                          : (d.kontak?['nama'] ?? '-'),
                    ),
                    _InfoRow(
                      'No. Telepon',
                      d.salesNoTelepon?.isNotEmpty == true
                          ? d.salesNoTelepon!
                          : (d.kontak?['no_telp']?.toString() ?? '-'),
                    ),
                    _InfoRow(
                      'Alamat',
                      d.salesAlamat?.isNotEmpty == true
                          ? d.salesAlamat!
                          : (d.kontak?['alamat']?.toString() ?? '-'),
                    ),
                    if (d.koordinat != null && d.koordinat!.isNotEmpty)
                      _InfoRow('Koordinat', d.koordinat!),
                    if (d.memo != null && d.memo!.isNotEmpty)
                      _InfoRow('Memo', d.memo!),
                  ]),
            ),
          ),
          if (d.items != null && d.items!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Produk Dikunjungi',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...d.items!.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              item.produk?.namaProduk ??
                                  'Produk #${item.produkId}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Flexible(
                              child: Text(
                                  'Qty: ${item.kuantitas ?? 0} ${item.produk?.satuan ?? 'Pcs'}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          AppTheme.textSecondaryColor(context)),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 16),
                            if ((item.tipeStok ?? derivedTipeStok) != null)
                              Flexible(
                                child: Text(
                                    'Tipe: ${item.tipeStok ?? derivedTipeStok}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondaryColor(
                                            context)),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            if (item.batchNumber != null &&
                                item.batchNumber!.isNotEmpty)
                              Text('Batch: ${item.batchNumber}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor(
                                          context))),
                            if (item.expiredDate != null &&
                                item.expiredDate!.isNotEmpty)
                              Text(
                                  'Expired: ${Formatters.date(item.expiredDate)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor(
                                          context))),
                          ]),
                          if (item.keterangan != null &&
                              item.keterangan!.isNotEmpty)
                            Text('Ket: ${item.keterangan}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTheme.textTertiaryColor(context))),
                        ]),
                  ),
                )),
          ],
          // Lampiran
          if (d.lampiranPaths != null && d.lampiranPaths!.isNotEmpty)
            LampiranSection(paths: d.lampiranPaths!),
          const SizedBox(height: 16),
          // Tombol tambah lampiran: hanya pemilik transaksi, admin, atau super_admin
          Consumer<AuthProvider>(
            builder: (ctx, authProvider, _) {
              final currentUser = authProvider.user;
              if (currentUser == null || currentUser.isSpectator) {
                return const SizedBox.shrink();
              }
              final isOwner = currentUser.isUser &&
                  d.userId != null &&
                  d.userId == currentUser.id;
              final canUpload =
                  isOwner || currentUser.isAdmin || currentUser.isSuperAdmin;
              if (!canUpload) return const SizedBox.shrink();
              return ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Tambah Lampiran via Kamera'),
                onPressed: () async {
                  await DetailPrintActionsHelper.uploadLampiran(
                    context,
                    type: 'kunjungan',
                    id: widget.id,
                  );
                  _loadDetail();
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String? _deriveTipeStok(String? tujuan) {
    if (tujuan == null) return null;
    if (tujuan == 'Promo Gratis') return 'gratis';
    if (tujuan == 'Promo Sample') return 'sample';
    return null;
  }

  Future<void> _handleAction(String action) async {
    final provider = Provider.of<KunjunganProvider>(context, listen: false);
    try {
      if (action == 'approve') {
        await provider.approveKunjungan(widget.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kunjungan berhasil di-approve.'),
              backgroundColor: Colors.green));
        }
      } else if (action == 'cancel') {
        await provider.cancelKunjungan(widget.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kunjungan berhasil dibatalkan.'),
              backgroundColor: Colors.orange));
        }
      } else if (action == 'uncancel') {
        await provider.uncancelKunjungan(widget.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kunjungan berhasil di-uncancel.'),
              backgroundColor: Colors.green));
        }
      }
      await _loadDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(':',
              style: TextStyle(
                  color: AppTheme.textSecondaryColor(context), fontSize: 13)),
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
