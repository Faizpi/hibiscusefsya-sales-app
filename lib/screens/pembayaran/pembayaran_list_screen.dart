import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pembayaran_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/summary_cards.dart';
import 'pembayaran_detail_screen.dart';
import 'pembayaran_create_screen.dart';

class PembayaranListScreen extends StatefulWidget {
  const PembayaranListScreen({super.key});

  @override
  State<PembayaranListScreen> createState() => _PembayaranListScreenState();
}

class _PembayaranListScreenState extends State<PembayaranListScreen> {
  int _displayCount = 20;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PembayaranProvider>(context, listen: false)
          .fetchPembayaran(refresh: true);
    });
  }

  void _loadData() {
    setState(() => _displayCount = _pageSize);
    Provider.of<PembayaranProvider>(context, listen: false)
        .fetchPembayaran(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isDark = AppTheme.isDark(context);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
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
                        builder: (_) => const PembayaranCreateScreen()));
                if (result == true) _loadData();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Summary cards
          Consumer<PembayaranProvider>(
            builder: (ctx, provider, _) {
              if (provider.items.isEmpty) return const SizedBox();
              final items = provider.items;
              final pending = items.where((e) => e.status == 'Pending').length;
              final approved =
                  items.where((e) => e.status == 'Approved').length;
              final total =
                  items.fold<double>(0, (sum, e) => sum + (e.jumlahBayar ?? 0));
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
                SummaryCard(
                  label: 'Total',
                  value: Formatters.compactCurrency(total),
                  color: AppTheme.primaryColor,
                  icon: Icons.payments_outlined,
                ),
              ]);
            },
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: Consumer<PembayaranProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const AppListSkeleton();
                }
                if (provider.items.isEmpty) {
                  return Center(
                    child: Text('Belum ada data pembayaran.',
                        style: TextStyle(
                            color: AppTheme.textSecondaryColor(context))),
                  );
                }

                final visibleItems =
                    provider.items.take(_displayCount).toList();
                final hasMoreLocal = provider.items.length > _displayCount;

                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: visibleItems.length + (hasMoreLocal ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= visibleItems.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _displayCount += _pageSize),
                              icon: const Icon(Icons.expand_more_rounded),
                              label: const Text('Muat Lebih Banyak'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(
                                    color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        );
                      }
                      final item = visibleItems[i];
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 10),
                        borderRadius: 14,
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PembayaranDetailScreen(id: item.id)));
                          _loadData();
                        },
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
                                child: Icon(Icons.payments_rounded,
                                    color: AppTheme.statusColor(item.status),
                                    size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(item.nomor ?? '-',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isDark
                                                    ? const Color(0xFF93C5FD)
                                                    : AppTheme.primaryColor)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: AppTheme.statusColor(
                                                    item.status)
                                                .withAlpha(isDark ? 40 : 25),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Text(item.status,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.statusColor(
                                                    item.status),
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ]),
                                    const SizedBox(height: 4),
                                    if (item.penjualan != null)
                                      Text(
                                          'Invoice: ${item.penjualan!['nomor'] ?? '-'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimaryColor(
                                                  context))),
                                    const SizedBox(height: 4),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                                item.metodePembayaran ?? '-',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme
                                                        .textTertiaryColor(
                                                            context))),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                              Formatters.currency(
                                                  item.jumlahBayar ?? 0),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color:
                                                      AppTheme.textPrimaryColor(
                                                          context))),
                                        ]),
                                  ],
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
