import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/stok_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_skeletons.dart';
import '../../widgets/glass_container.dart';

class StokLogScreen extends StatefulWidget {
  const StokLogScreen({super.key});

  @override
  State<StokLogScreen> createState() => _StokLogScreenState();
}

class _StokLogScreenState extends State<StokLogScreen> {
  int? _gudangId;
  DateTime? _tanggalDari;
  DateTime? _tanggalSampai;

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final s = value.toString().trim();
    if (s.isEmpty) return 0;

    final direct = int.tryParse(s);
    if (direct != null) return direct;

    final normalized = s.replaceAll(',', '.');
    final asNum = num.tryParse(normalized);
    if (asNum != null) return asNum.toInt();

    final digitsOnly = s.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  dynamic _firstPresent(Map<String, dynamic> log, List<String> keys) {
    for (final key in keys) {
      if (log.containsKey(key) && log[key] != null) {
        return log[key];
      }
    }
    return null;
  }

  int _stokSebelum(Map<String, dynamic> log) {
    return _toInt(_firstPresent(log, [
      'stok_sebelum',
      'stokSebelum',
      'stok_awal',
      'before_stock',
    ]));
  }

  int _stokSesudah(Map<String, dynamic> log) {
    return _toInt(_firstPresent(log, [
      'stok_sesudah',
      'stok_setelah',
      'stokSesudah',
      'stok_akhir',
      'after_stock',
    ]));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      _loadData();
    });
  }

  void _loadData() {
    final fmt = DateFormat('yyyy-MM-dd');
    Provider.of<StokProvider>(context, listen: false).fetchLog(
      gudangId: _gudangId,
      tanggalDari: _tanggalDari != null ? fmt.format(_tanggalDari!) : null,
      tanggalSampai:
          _tanggalSampai != null ? fmt.format(_tanggalSampai!) : null,
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _tanggalDari : _tanggalSampai) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _tanggalDari = picked;
        } else {
          _tanggalSampai = picked;
        }
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Riwayat Stok'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Consumer<GudangProvider>(
                  builder: (ctx, gProv, _) => DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: _gudangId,
                    decoration: const InputDecoration(
                      labelText: 'Filter Gudang',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Semua Gudang')),
                      ...gProv.items.map((g) => DropdownMenuItem(
                          value: g.id, child: Text(g.namaGudang))),
                    ],
                    onChanged: (v) {
                      setState(() => _gudangId = v);
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dari Tanggal',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: Icon(Icons.calendar_today, size: 16),
                          ),
                          child: Text(
                            _tanggalDari != null
                                ? Formatters.date(
                                    _tanggalDari!.toIso8601String())
                                : '-',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Sampai Tanggal',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: Icon(Icons.calendar_today, size: 16),
                          ),
                          child: Text(
                            _tanggalSampai != null
                                ? Formatters.date(
                                    _tanggalSampai!.toIso8601String())
                                : '-',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: Consumer<StokProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.logData.isEmpty) {
                  return const AppListSkeleton();
                }
                if (provider.logData.isEmpty) {
                  return const Center(child: Text('Tidak ada riwayat stok.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: provider.logData.length,
                    itemBuilder: (ctx, i) {
                      final raw = provider.logData[i];
                      final log = raw is Map
                          ? Map<String, dynamic>.from(raw)
                          : <String, dynamic>{};
                      final stokSebelum = _stokSebelum(log);
                      final stokSesudah = _stokSesudah(log);
                      final selisih = _toInt(log['selisih']) != 0
                          ? _toInt(log['selisih'])
                          : stokSesudah - stokSebelum;
                      final isPositive = selisih >= 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      log['produk']?['nama_produk'] ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isPositive
                                              ? AppTheme.successColor
                                              : AppTheme.dangerColor)
                                          .withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${isPositive ? '+' : ''}$selisih',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isPositive
                                            ? AppTheme.successColor
                                            : AppTheme.dangerColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _LogChip('Sebelum: $stokSebelum'),
                                  const Icon(Icons.arrow_forward,
                                      size: 14, color: AppTheme.textSecondary),
                                  _LogChip('Sesudah: $stokSesudah'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 14,
                                      color:
                                          AppTheme.textTertiaryColor(context)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(log['user']?['name'] ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor(
                                                context))),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.access_time,
                                      size: 14,
                                      color:
                                          AppTheme.textTertiaryColor(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    Formatters.dateTime(log['created_at']),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor(
                                            context)),
                                  ),
                                ],
                              ),
                              if (log['keterangan'] != null &&
                                  log['keterangan'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Ket: ${log['keterangan']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            AppTheme.textTertiaryColor(context),
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogChip extends StatelessWidget {
  final String text;
  const _LogChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
    );
  }
}
