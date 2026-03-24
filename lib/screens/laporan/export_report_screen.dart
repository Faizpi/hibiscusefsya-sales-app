import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/export_options_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import '../../widgets/glass_container.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _transactionType = 'all';
  String _statusFilter = 'all';
  String _exportFormat = 'pdf';
  String? _biayaJenis;
  String? _tujuanFilter;
  String? _gudangId;
  String? _salesId;

  bool _isExporting = false;
  bool _isLoadingOptions = true;
  String? _optionsError;
  ExportOptionsModel? _options;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });

    try {
      final dashboard = Provider.of<DashboardProvider>(context, listen: false);
      final loaded = await dashboard.fetchExportOptions();
      if (!mounted) return;
      setState(() {
        _options = loaded;
        _transactionType = loaded.defaultTransactionType;
        _statusFilter = loaded.defaultStatusFilter;
        _exportFormat = loaded.defaultExportFormat;
        _isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optionsError = 'Gagal memuat opsi export. Tarik ulang atau coba lagi.';
        _isLoadingOptions = false;
      });
      _handleApiError(e, actionLabel: 'memuat opsi export');
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Pilih tanggal';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _exportReport({String? forcedFormat}) async {
    final options = _options;
    if (options == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isSalesRole = auth.user?.isUser == true;

    if (_dateFrom == null || (!isSalesRole && _dateTo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSalesRole
                ? 'Pilih tanggal laporan harian'
                : 'Pilih tanggal mulai dan selesai',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final exportDateFrom = _dateFrom!;
    final exportDateTo = isSalesRole ? _dateFrom! : _dateTo!;

    if (!isSalesRole && exportDateTo.isBefore(exportDateFrom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tanggal selesai tidak boleh lebih kecil dari tanggal mulai'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!options.canExportFullReport) {
      _showAccessDeniedDialog();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final format = forcedFormat ?? _exportFormat;
      final bytes = await provider.exportReport(
        dateFrom: _toApiDate(exportDateFrom),
        dateTo: _toApiDate(exportDateTo),
        transactionType: _transactionType,
        statusFilter: _statusFilter,
        exportFormat: format,
        biayaJenis: _biayaJenis,
        tujuanFilter: _tujuanFilter,
        gudangId: _gudangId == null ? null : int.tryParse(_gudangId!),
        salesId: _salesId == null ? null : int.tryParse(_salesId!),
      );

      final ext = format == 'pdf' ? 'pdf' : 'xlsx';
      final fileName =
          'Laporan_${_transactionType}_${_toApiDate(exportDateFrom)}_sd_${_toApiDate(exportDateTo)}.$ext';
      await _saveAndPresentFileActions(
        bytes,
        fileName: fileName,
        shareText: 'Laporan $_transactionType',
      );
    } catch (e) {
      _handleApiError(e, actionLabel: 'mengunduh laporan full');
    }

    if (mounted) setState(() => _isExporting = false);
  }

  Future<void> _downloadDailyReportPdf() async {
    final targetDate = _dateFrom ?? DateTime.now();
    setState(() => _isExporting = true);

    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final bytes = await provider.downloadDailyReportPdf(
        date: _toApiDate(targetDate),
      );

      final fileName = 'Laporan_Harian_${_toApiDate(targetDate)}.pdf';
      await _saveAndPresentFileActions(
        bytes,
        fileName: fileName,
        shareText: 'Laporan Harian',
      );
    } catch (e) {
      _handleApiError(e, actionLabel: 'mengunduh laporan harian');
    }

    if (mounted) setState(() => _isExporting = false);
  }

  Future<void> _saveAndPresentFileActions(
    List<int> bytes, {
    required String fileName,
    required String shareText,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File tersimpan: ${file.path}'),
        backgroundColor: Colors.green,
      ),
    );

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Buka File'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final opened = await _openFile(file.path);
                  if (!opened && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'File tidak bisa dibuka otomatis. Silakan bagikan file.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Bagikan File'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: shareText,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _openFile(String path) async {
    final fileUri = Uri.file(path);
    if (await canLaunchUrl(fileUri)) {
      return await launchUrl(
        fileUri,
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }

  void _handleApiError(Object error, {required String actionLabel}) {
    if (!mounted) return;

    if (error is ApiException && error.statusCode == 403) {
      _showAccessDeniedDialog(message: error.message);
      return;
    }

    if (error is ApiException && error.statusCode == 422) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Validasi Gagal'),
          content: Text(
            error.message.isNotEmpty
                ? error.message
                : 'Filter export tidak valid. Periksa tanggal dan parameter filter Anda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal $actionLabel. ${error.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAccessDeniedDialog({String? message}) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Akses Ditolak'),
        content: Text(
          message?.isNotEmpty == true
              ? message!
              : 'Anda tidak punya akses untuk export laporan full (PDF/Excel).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _toApiDate(DateTime date) => date.toIso8601String().split('T')[0];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final isSalesRole = user?.isUser == true;
    final isSuperAdmin = user?.isSuperAdmin == true;
    final isAdmin = user?.isAdmin == true;
    final canExportReport = user?.hasPermission('can_export_report') == true;
    final options = _options;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Export Laporan'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      body: _isLoadingOptions
          ? const AppFormSkeleton()
          : _optionsError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _optionsError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadOptions,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOptions,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (options != null && options.canExportFullReport) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_rounded,
                                    size: 16, color: Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isSuperAdmin
                                        ? 'Super Admin: Anda dapat export semua data transaksi.'
                                        : (isAdmin
                                            ? 'Admin: Anda hanya dapat export data dimana Anda sebagai approver.'
                                            : 'Anda memiliki akses export laporan.'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (options != null) ...[
                          _buildOptionsDropdown(
                            label: 'Tipe Transaksi',
                            value: _transactionType,
                            options: options.transactionTypes,
                            onChanged: (v) => setState(() {
                              _transactionType = v!;
                              if (_transactionType != 'biaya')
                                _biayaJenis = null;
                              if (_transactionType != 'kunjungan') {
                                _tujuanFilter = null;
                              }
                            }),
                          ),
                          const SizedBox(height: 12),
                          if (isSalesRole)
                            _buildDateField(
                              'Tanggal Laporan Harian *',
                              _dateFrom,
                              () => _pickDate(true),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    'Dari Tanggal *',
                                    _dateFrom,
                                    () => _pickDate(true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDateField(
                                    'Sampai Tanggal *',
                                    _dateTo,
                                    () => _pickDate(false),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          _buildOptionsDropdown(
                            label: 'Filter Status',
                            value: _statusFilter,
                            options: options.statusFilters,
                            onChanged: (v) =>
                                setState(() => _statusFilter = v!),
                          ),
                          const SizedBox(height: 12),
                          if (options.gudangOptions.isNotEmpty) ...[
                            _buildOptionsDropdown(
                              label: 'Filter Gudang',
                              value: _gudangId,
                              options: options.gudangOptions,
                              onChanged: (v) => setState(() => _gudangId = v),
                              required: false,
                              optionalAllLabel: 'Semua Gudang',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '*Filter gudang berlaku untuk semua tipe transaksi',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_transactionType == 'biaya' &&
                              options.biayaJenisOptions.isNotEmpty) ...[
                            _buildOptionsDropdown(
                              label: 'Jenis Biaya',
                              value: _biayaJenis,
                              options: options.biayaJenisOptions,
                              onChanged: (v) => setState(() => _biayaJenis = v),
                              required: false,
                              optionalAllLabel: 'Semua Jenis',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '*Hanya berlaku saat tipe transaksi = Biaya',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_transactionType == 'kunjungan' &&
                              options.tujuanFilters.isNotEmpty) ...[
                            _buildOptionsDropdown(
                              label: 'Tujuan Kunjungan',
                              value: _tujuanFilter,
                              options: options.tujuanFilters,
                              onChanged: (v) =>
                                  setState(() => _tujuanFilter = v),
                              required: false,
                              optionalAllLabel: 'Semua Tujuan',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '*Hanya berlaku saat tipe transaksi = Kunjungan',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (options.salesOptions.isNotEmpty &&
                              !isSalesRole) ...[
                            _buildOptionsDropdown(
                              label: 'Filter Sales',
                              value: _salesId,
                              options: options.salesOptions,
                              onChanged: (v) => setState(() => _salesId = v),
                              required: false,
                              optionalAllLabel: 'Semua Sales',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '*Filter berdasarkan sales (pembuat transaksi)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 16),
                          if (!isSalesRole &&
                              options.canExportFullReport &&
                              canExportReport)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final buttonWidth =
                                    (constraints.maxWidth - 10) / 2;

                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    SizedBox(
                                      width: buttonWidth,
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: _isExporting
                                            ? null
                                            : () => _exportReport(
                                                forcedFormat: 'pdf'),
                                        icon: _isExporting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.picture_as_pdf),
                                        label: Text(
                                          _isExporting
                                              ? 'Memproses...'
                                              : 'Export ke PDF',
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFDC2626),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: buttonWidth,
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: _isExporting
                                            ? null
                                            : () => _exportReport(
                                                forcedFormat: 'excel'),
                                        icon: _isExporting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.table_view),
                                        label: Text(
                                          _isExporting
                                              ? 'Memproses...'
                                              : 'Export ke Excel',
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          else
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _isExporting
                                    ? null
                                    : _downloadDailyReportPdf,
                                icon: _isExporting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: Text(
                                  _isExporting
                                      ? 'Memproses...'
                                      : 'Laporan Harian (PDF)',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _formatDate(value),
          style: TextStyle(
            color: value == null
                ? AppTheme.textTertiaryColor(context)
                : AppTheme.textPrimaryColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsDropdown({
    required String label,
    required List<ExportOptionItem> options,
    required ValueChanged<String?> onChanged,
    String? value,
    bool required = true,
    String optionalAllLabel = 'Semua',
  }) {
    final hasValue =
        value != null && options.any((option) => option.value == value);
    final selectedValue = hasValue ? value : null;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: selectedValue,
      style: TextStyle(
        fontSize: 14,
        height: 1.25,
        color: AppTheme.textPrimaryColor(context),
      ),
      decoration: InputDecoration(
        labelText: required ? label : '$label (Opsional)',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: TextStyle(
          fontSize: 12,
          height: 1.2,
          color: AppTheme.textSecondaryColor(context),
        ),
        border: const OutlineInputBorder(),
      ),
      items: [
        if (!required)
          DropdownMenuItem<String>(
            value: null,
            child: Text(optionalAllLabel),
          ),
        ...options.map(
          (item) => DropdownMenuItem<String>(
            value: item.value,
            child: Text(item.label),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
