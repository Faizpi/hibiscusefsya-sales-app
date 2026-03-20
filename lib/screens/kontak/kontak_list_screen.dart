import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kontak_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import 'kontak_detail_screen.dart';
import 'kontak_form_screen.dart';

class KontakListScreen extends StatefulWidget {
  const KontakListScreen({super.key});

  @override
  State<KontakListScreen> createState() => _KontakListScreenState();
}

class _KontakListScreenState extends State<KontakListScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KontakProvider>(context, listen: false).fetchKontak();
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
    });
  }

  void _loadData() {
    Provider.of<KontakProvider>(context, listen: false)
        .fetchKontak(search: _search);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Kontak'),
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
                        builder: (_) => const KontakFormScreen()));
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
                hintText: 'Cari kontak...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) {
                _search = v;
                Provider.of<KontakProvider>(context, listen: false)
                    .fetchKontak(search: v);
              },
            ),
          ),
          Expanded(
            child: Consumer<KontakProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const AppListSkeleton();
                }
                if (provider.items.isEmpty) {
                  return const Center(child: Text('Tidak ada kontak.'));
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchKontak(search: _search),
                  child: Consumer<GudangProvider>(
                    builder: (ctx2, gudangProvider, _) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                        itemCount: provider.items.length,
                        itemBuilder: (ctx, i) {
                          final k = provider.items[i];
                          final isDark = AppTheme.isDark(context);
                          String? gudangName;
                          if (k.gudangId != null) {
                            final match = gudangProvider.items
                                .where((g) => g.id == k.gudangId);
                            if (match.isNotEmpty) {
                              gudangName = match.first.namaGudang;
                            }
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.borderColorOf(context)),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withAlpha(isDark ? 20 : 6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            KontakDetailScreen(id: k.id)));
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
                                        color: AppTheme.primaryColor
                                            .withAlpha(isDark ? 35 : 20),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          k.nama.isNotEmpty
                                              ? k.nama[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: isDark
                                                ? const Color(0xFF93C5FD)
                                                : AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                              child: Text(k.nama,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF93C5FD)
                                                          : AppTheme
                                                              .primaryColor)),
                                            ),
                                            if (k.diskonPersen != null &&
                                                k.diskonPersen! > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successColor
                                                      .withAlpha(
                                                          isDark ? 40 : 25),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Diskon ${k.diskonPersen}%',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.successColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                          ]),
                                          const SizedBox(height: 4),
                                          if (k.kodeKontak != null)
                                            Text(k.kodeKontak!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme
                                                        .textPrimaryColor(
                                                            context))),
                                          const SizedBox(height: 4),
                                          Wrap(
                                              spacing: 12,
                                              runSpacing: 4,
                                              children: [
                                                if (k.noTelp != null)
                                                  Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.phone,
                                                            size: 13,
                                                            color: AppTheme
                                                                .textTertiaryColor(
                                                                    context)),
                                                        const SizedBox(
                                                            width: 4),
                                                        Flexible(
                                                          child: Text(k.noTelp!,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: AppTheme
                                                                      .textTertiaryColor(
                                                                          context))),
                                                        ),
                                                      ]),
                                                if (k.email != null)
                                                  Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .email_outlined,
                                                            size: 13,
                                                            color: AppTheme
                                                                .textTertiaryColor(
                                                                    context)),
                                                        const SizedBox(
                                                            width: 4),
                                                        Flexible(
                                                          child: Text(k.email!,
                                                              style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: AppTheme
                                                                      .textTertiaryColor(
                                                                          context)),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis),
                                                        ),
                                                      ]),
                                                if (gudangName != null)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.infoColor
                                                          .withAlpha(20),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                            Icons
                                                                .warehouse_outlined,
                                                            size: 12,
                                                            color: AppTheme
                                                                .infoColor),
                                                        const SizedBox(
                                                            width: 3),
                                                        Text(gudangName,
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color: AppTheme
                                                                    .infoColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500)),
                                                      ],
                                                    ),
                                                  ),
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
