import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produk_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import 'produk_detail_screen.dart';
import 'produk_form_screen.dart';

class ProdukListScreen extends StatefulWidget {
  const ProdukListScreen({super.key});

  @override
  State<ProdukListScreen> createState() => _ProdukListScreenState();
}

class _ProdukListScreenState extends State<ProdukListScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProdukProvider>(context, listen: false).fetchProduk();
    });
  }

  void _loadData() {
    Provider.of<ProdukProvider>(context, listen: false)
        .fetchProduk(search: _search);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Produk'),
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
                        builder: (_) => const ProdukFormScreen()));
                if (result == true) _loadData();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) {
                _search = v;
                Provider.of<ProdukProvider>(context, listen: false)
                    .fetchProduk(search: v);
              },
            ),
          ),
          Expanded(
            child: Consumer<ProdukProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const AppListSkeleton();
                }
                if (provider.items.isEmpty) {
                  return const Center(child: Text('Tidak ada produk.'));
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchProduk(search: _search),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    itemCount: provider.items.length,
                    itemBuilder: (ctx, i) {
                      final p = provider.items[i];
                      final isDark = AppTheme.isDark(context);
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
                                        ProdukDetailScreen(id: p.id)));
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
                                    color: AppTheme.primaryColor
                                        .withAlpha(isDark ? 35 : 20),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded,
                                      color: AppTheme.primaryColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.namaProduk,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDark
                                                  ? const Color(0xFF93C5FD)
                                                  : AppTheme.primaryColor)),
                                      const SizedBox(height: 4),
                                      Text(p.itemCode ?? '-',
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
                                            child: Text(p.satuan ?? 'pcs',
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
                                              Formatters.currency(p.harga ?? 0),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color:
                                                      AppTheme.textPrimaryColor(
                                                          context))),
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
}
