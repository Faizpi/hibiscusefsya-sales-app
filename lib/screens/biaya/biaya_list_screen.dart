import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biaya_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import '../../widgets/summary_cards.dart';
import 'biaya_detail_screen.dart';
import 'biaya_create_screen.dart';
import '../../widgets/glass_container.dart';

class BiayaListScreen extends StatefulWidget {
  const BiayaListScreen({super.key});

  @override
  State<BiayaListScreen> createState() => _BiayaListScreenState();
}

class _BiayaListScreenState extends State<BiayaListScreen> {
  String? _selectedStatus;
  String _searchQuery = '';
  int _displayCount = 20;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BiayaProvider>(context, listen: false)
          .fetchBiaya(refresh: true);
    });
  }

  void _loadData() {
    setState(() => _displayCount = _pageSize);
    Provider.of<BiayaProvider>(context, listen: false).fetchBiaya(
        status: _selectedStatus, search: _searchQuery, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isDark = AppTheme.isDark(context);

    return GlassScaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Biaya'),
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
                        builder: (_) => const BiayaCreateScreen()));
                if (result == true) _loadData();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nomor, jenis, atau penerima...',
                hintStyle: TextStyle(
                    color: AppTheme.textTertiaryColor(context), fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    color: AppTheme.textTertiaryColor(context)),
                isDense: true,
                filled: true,
                fillColor: AppTheme.glassInputFill(context),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppTheme.glassBorderColor(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppTheme.glassBorderColor(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
              style: TextStyle(color: AppTheme.textPrimaryColor(context)),
              onChanged: (v) {
                _searchQuery = v;
                _loadData();
              },
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [null, 'Pending', 'Approved', 'Canceled'].map((s) {
                  final selected = _selectedStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s ?? 'Semua',
                          style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? (isDark
                                      ? const Color(0xFF93C5FD)
                                      : AppTheme.primaryColor)
                                  : AppTheme.textSecondaryColor(context))),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedStatus = s);
                        _loadData();
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
          Consumer<BiayaProvider>(
            builder: (ctx, provider, _) {
              if (provider.items.isEmpty) return const SizedBox();
              final items = provider.items;
              final pending = items.where((e) => e.status == 'Pending').length;
              final approved =
                  items.where((e) => e.status == 'Approved').length;
              final total =
                  items.fold<double>(0, (sum, e) => sum + (e.grandTotal ?? 0));
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
                  icon: Icons.receipt_long_outlined,
                ),
              ]);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<BiayaProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const AppListSkeleton();
                }
                if (provider.items.isEmpty) {
                  return Center(
                    child: Text('Belum ada data biaya.',
                        style: TextStyle(
                            color: AppTheme.textSecondaryColor(context))),
                  );
                }

                final visibleItems =
                    provider.items.take(_displayCount).toList();
                final hasMoreLocal =
                    provider.items.length > _displayCount || provider.hasMore;

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
                              onPressed: () => _loadMore(provider),
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
                                        BiayaDetailScreen(id: item.id)));
                            _loadData();
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
                                  child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: AppTheme.statusColor(item.status),
                                      size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Text(item.jenisBiaya ?? '-',
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
                                                  Formatters.date(
                                                      item.tglTransaksi),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme
                                                          .textTertiaryColor(
                                                              context))),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                                Formatters.currency(
                                                    item.grandTotal ?? 0),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppTheme
                                                        .textPrimaryColor(
                                                            context))),
                                          ]),
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

  void _loadMore(BiayaProvider provider) {
    setState(() => _displayCount += _pageSize);
    if (_displayCount >= provider.items.length && provider.hasMore) {
      provider.loadMore(status: _selectedStatus, search: _searchQuery);
    }
  }
}
