import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pembelian_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pembelian_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/app_theme.dart';
import '../../utils/detail_print_actions_helper.dart';
import '../../widgets/app_skeletons.dart';
import 'pembelian_edit_screen.dart';
import '../../widgets/lampiran_section.dart';
import '../../widgets/glass_container.dart';

class PembelianDetailScreen extends StatefulWidget {
  final int id;
  const PembelianDetailScreen({super.key, required this.id});

  @override
  State<PembelianDetailScreen> createState() => _PembelianDetailScreenState();
}

class _PembelianDetailScreenState extends State<PembelianDetailScreen> {
  PembelianModel? _data;
  bool _isLoading = true;
  String? _error;

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
      final provider = Provider.of<PembelianProvider>(context, listen: false);
      _data = await provider.getDetail(widget.id);
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
        title: Text(_data?.nomor ?? 'Detail Pembelian'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
        actions: [
          ...DetailPrintActionsHelper.buildAppBarActions(
            context: context,
            type: 'pembelian',
            id: widget.id,
            bluetoothSupported: true,
          ),
          if (_data != null &&
              user != null &&
              user.hasPermission('can_edit_transaction') &&
              !user.isSpectator)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PembelianEditScreen(data: _data!),
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
              final canCancel = (user.hasPermission('can_cancel_transaction') &&
                      status == 'Pending') ||
                  (user.hasPermission('can_cancel_approved_transaction') &&
                      (status == 'Approved' || status == 'Lunas'));
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
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;
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
                          color: AppTheme.statusColor(d.status).withAlpha(38),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(d.status,
                            style: TextStyle(
                                color: AppTheme.statusColor(d.status),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow('Tanggal', Formatters.date(d.tglTransaksi)),
                  _InfoRow('Jatuh Tempo', Formatters.date(d.tglJatuhTempo)),
                  _InfoRow('Pembayaran', d.syaratPembayaran ?? '-'),
                  _InfoRow('Urgensi', d.urgensi ?? '-'),
                  _InfoRow('Gudang', d.gudangName),
                  _InfoRow('Dibuat oleh', d.userName),
                  if (d.tahunAnggaran != null)
                    _InfoRow('Tahun Anggaran', d.tahunAnggaran!),
                  if (d.stafPenyetuju != null)
                    _InfoRow('Staf Penyetuju', d.stafPenyetuju!),
                  if (d.memo != null && d.memo!.isNotEmpty)
                    _InfoRow('Memo', d.memo!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Detail Item',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (d.items != null)
            ...d.items!.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.namaProduk ?? '-',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                  '${item.kuantitas} ${item.unit ?? item.satuan ?? 'Pcs'} x ${Formatters.currency(item.hargaSatuan)}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondaryColor(
                                          context))),
                            ),
                            const SizedBox(width: 8),
                            Text(Formatters.currency(item.total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (item.diskon != null && item.diskon! > 0)
                          Text('Diskon: ${item.diskon}%',
                              style: TextStyle(
                                  color: Colors.red[400], fontSize: 12)),
                        if (item.batchNumber != null &&
                            item.batchNumber!.isNotEmpty)
                          Text('Batch: ${item.batchNumber}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor(context))),
                        if (item.expiredDate != null &&
                            item.expiredDate!.isNotEmpty)
                          Text('Expired: ${Formatters.date(item.expiredDate)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor(context))),
                        if (item.deskripsi != null &&
                            item.deskripsi!.isNotEmpty)
                          Text('Ket: ${item.deskripsi}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textTertiaryColor(context))),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (d.diskonAkhir != null && d.diskonAkhir! > 0)
                    _TotalRow('Diskon Akhir',
                        '- ${Formatters.currency(d.diskonAkhir)}'),
                  if (d.taxPercentage != null && d.taxPercentage! > 0)
                    _TotalRow('Pajak (${d.taxPercentage}%)', ''),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(Formatters.currency(d.grandTotal ?? 0),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Lampiran
          if (d.lampiranPaths != null && d.lampiranPaths!.isNotEmpty)
            LampiranSection(paths: d.lampiranPaths!),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Tambah Lampiran via Kamera'),
            onPressed: () async {
              await DetailPrintActionsHelper.uploadLampiran(
                context,
                type: 'pembelian',
                id: widget.id,
              );
              _loadDetail();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    final provider = Provider.of<PembelianProvider>(context, listen: false);
    try {
      if (action == 'approve') {
        await provider.approvePembelian(widget.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pembelian berhasil di-approve.'),
              backgroundColor: Colors.green));
        }
      } else if (action == 'cancel') {
        await provider.cancelPembelian(widget.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pembelian berhasil dibatalkan.'),
              backgroundColor: Colors.orange));
        }
      } else if (action == 'uncancel') {
        await provider.uncancelPembelian(widget.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pembelian berhasil di-uncancel.'),
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

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  const _TotalRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(color: AppTheme.textSecondaryColor(context))),
        Text(value),
      ]),
    );
  }
}
