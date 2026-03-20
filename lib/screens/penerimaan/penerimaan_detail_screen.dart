import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/penerimaan_barang_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penerimaan_barang_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/detail_print_actions_helper.dart';
import '../../widgets/app_skeletons.dart';
import '../../widgets/lampiran_section.dart';

class PenerimaanDetailScreen extends StatefulWidget {
  final int id;
  const PenerimaanDetailScreen({super.key, required this.id});

  @override
  State<PenerimaanDetailScreen> createState() => _PenerimaanDetailScreenState();
}

class _PenerimaanDetailScreenState extends State<PenerimaanDetailScreen> {
  PenerimaanBarangModel? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final provider =
          Provider.of<PenerimaanBarangProvider>(context, listen: false);
      _data = await provider.getDetail(widget.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _approve() async {
    try {
      await Provider.of<PenerimaanBarangProvider>(context, listen: false)
          .approvePenerimaan(widget.id);
      _loadDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancel() async {
    final provider =
        Provider.of<PenerimaanBarangProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin membatalkan penerimaan ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Batalkan')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await provider.cancelPenerimaan(widget.id);
        if (!mounted) return;
        _loadDetail();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.nomor ?? 'Detail Penerimaan'),
        flexibleSpace: Container(
            decoration:
                BoxDecoration(gradient: AppTheme.mainGradient(context))),
        actions: [
          ...DetailPrintActionsHelper.buildAppBarActions(
            context: context,
            type: 'penerimaan-barang',
            id: widget.id,
            bluetoothSupported: false,
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

              final menuItems = <PopupMenuEntry<String>>[
                if (canApprove)
                  const PopupMenuItem(value: 'approve', child: Text('Approve')),
                if (canCancel)
                  const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
              ];

              if (menuItems.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'approve') _approve();
                  if (val == 'cancel') _cancel();
                },
                itemBuilder: (_) => menuItems,
              );
            }),
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
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      const Text('Items',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ..._buildItemsList(),
                      if (_data!.lampiranPaths != null &&
                          _data!.lampiranPaths!.isNotEmpty)
                        LampiranSection(paths: _data!.lampiranPaths!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    final d = _data!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _InfoRow('Status', d.status),
          _InfoRow('Tanggal', Formatters.date(d.tglPenerimaan)),
          _InfoRow('No. Surat Jalan', d.noSuratJalan ?? '-'),
          _InfoRow('Pembelian', d.pembelianNomor),
          _InfoRow('Gudang', d.gudangName),
          _InfoRow('Pembuat', d.userName),
          if (d.keterangan != null && d.keterangan!.isNotEmpty)
            _InfoRow('Keterangan', d.keterangan!),
        ]),
      ),
    );
  }

  List<Widget> _buildItemsList() {
    final items = _data!.items ?? [];
    if (items.isEmpty) return [const Text('Tidak ada item.')];
    return items.map((item) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.namaProduk ?? item.produk?.namaProduk ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Flexible(
                  child: _chip(
                      'Diterima: ${item.qtyDiterima ?? 0}', Colors.green)),
              const SizedBox(width: 8),
              Flexible(
                  child: _chip('Reject: ${item.qtyReject ?? 0}', Colors.red)),
            ]),
            const SizedBox(height: 6),
            if (item.tipeStok != null)
              Text('Tipe Stok: ${item.tipeStok}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context))),
            if (item.batchNumber != null)
              Text('Batch: ${item.batchNumber}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context))),
            if (item.expiredDate != null)
              Text('Expired: ${Formatters.date(item.expiredDate)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context))),
            if (item.keterangan != null && item.keterangan!.isNotEmpty)
              Text('Ket: ${item.keterangan}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context))),
          ]),
        ),
      );
    }).toList();
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
