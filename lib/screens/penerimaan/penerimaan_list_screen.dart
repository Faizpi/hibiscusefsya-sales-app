import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penerimaan_barang_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import '../../widgets/summary_cards.dart';
import 'penerimaan_detail_screen.dart';
import 'penerimaan_create_screen.dart';
import '../../widgets/glass_container.dart';

class PenerimaanListScreen extends StatefulWidget {
  const PenerimaanListScreen({super.key});

  @override
  State<PenerimaanListScreen> createState() => _PenerimaanListScreenState();
}

class _PenerimaanListScreenState extends State<PenerimaanListScreen> {
  String? _selectedStatus;
  int _displayCount = 20;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(refresh: true);
    });
  }

  void _loadData({bool refresh = false}) {
    if (refresh) setState(() => _displayCount = _pageSize);
    Provider.of<PenerimaanBarangProvider>(context, listen: false)
        .fetchPenerimaan(status: _selectedStatus, refresh: refresh);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isDark = AppTheme.isDark(context);

    return GlassScaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Penerimaan Barang'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      floatingActionButton: (user != null && user.canCreate)
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PenerimaanCreateScreen()));
                if (result == true) _loadData(refresh: true);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [null, 'Pending', 'Approved', 'Canceled'].map((status) {
                  final selected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        status ?? 'Semua',
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? (isDark
                                  ? const Color(0xFF93C5FD)
                                  : AppTheme.primaryColor)
                              : AppTheme.textSecondaryColor(context),
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedStatus = status);
                        _loadData(refresh: true);
                      },
                      selectedColor:
                          AppTheme.primaryColor.withAlpha(isDark ? 40 : 25),
                      backgroundColor: AppTheme.cardBg(context),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primaryColor.withAlpha(isDark ? 80 : 60)
                            : AppTheme.borderColorOf(context),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Summary cards
          Consumer<PenerimaanBarangProvider>(
            builder: (ctx, provider, _) {
              if (provider.items.isEmpty) return const SizedBox();
              final items = provider.items;
              final pending = items.where((e) => e.status == 'Pending').length;
              final approved =
                  items.where((e) => e.status == 'Approved').length;
              return SummaryCardRow(cards: [
                SummaryCard(
                  label: 'Pending',
                  value: '$pending',
                  color: AppTheme.warningColor,
                  icon: Icons.hourglass_empty,
                ),
                SummaryCard(
                  label: 'Approved',
                  value: '$approved',
                  color: AppTheme.successColor,
                  icon: Icons.check_circle_outline,
                ),
              ]);
            },
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: Consumer<PenerimaanBarangProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const AppListSkeleton();
                }

                if (provider.error != null && provider.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(provider.error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadData(refresh: true),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.items.isEmpty) {
                  return Center(
                    child: Text('Belum ada data penerimaan barang.',
                        style: TextStyle(
                            color: AppTheme.textSecondaryColor(context))),
                  );
                }

                final visibleItems =
                    provider.items.take(_displayCount).toList();
                final hasMoreLocal =
                    provider.items.length > _displayCount || provider.hasMore;

                return RefreshIndicator(
                  onRefresh: () async => _loadData(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: visibleItems.length + (hasMoreLocal ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= visibleItems.length) {
                        return _buildLoadMoreButton(provider);
                      }

                      final item = visibleItems[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.borderColorOf(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 20 : 6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PenerimaanDetailScreen(id: item.id),
                              ),
                            );
                            _loadData(refresh: true);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusColor(item.status)
                                        .withAlpha(isDark ? 35 : 20),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.local_shipping_rounded,
                                      color: AppTheme.statusColor(item.status),
                                      size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.nomor ?? '-',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isDark
                                                    ? const Color(0xFF93C5FD)
                                                    : AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          _StatusBadge(status: item.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.gudangName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimaryColor(
                                              context),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            Formatters.date(item.tglPenerimaan),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textTertiaryColor(
                                                  context),
                                            ),
                                          ),
                                          if (item.noSuratJalan != null &&
                                              item.noSuratJalan!.isNotEmpty)
                                            Flexible(
                                              child: Text(
                                                'SJ: ${item.noSuratJalan}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme
                                                      .textSecondaryColor(
                                                          context),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildLoadMoreButton(PenerimaanBarangProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: provider.isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _displayCount += _pageSize;
                  });
                  if (_displayCount >= provider.items.length &&
                      provider.hasMore) {
                    provider.loadMore(status: _selectedStatus);
                  }
                },
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Muat Lebih Banyak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.statusColor(status)
            .withAlpha(AppTheme.isDark(context) ? 40 : 25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.statusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
