import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gudang_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import 'gudang_form_screen.dart';

class GudangListScreen extends StatefulWidget {
  const GudangListScreen({super.key});

  @override
  State<GudangListScreen> createState() => _GudangListScreenState();
}

class _GudangListScreenState extends State<GudangListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GudangProvider>(context, listen: false).fetchGudang();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Gudang'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GudangFormScreen()));
                if (!context.mounted) return;
                if (result == true) {
                  Provider.of<GudangProvider>(context, listen: false)
                      .fetchGudang();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<GudangProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const AppListSkeleton();
          }
          if (provider.items.isEmpty) {
            return const Center(child: Text('Belum ada data gudang.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchGudang(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: provider.items.length,
              itemBuilder: (ctx, i) {
                final item = provider.items[i];
                final isDark = AppTheme.isDark(context);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColorOf(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 20 : 6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isSuperAdmin
                        ? () async {
                            final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        GudangFormScreen(gudang: item)));
                            if (!context.mounted) return;
                            if (result == true) {
                              Provider.of<GudangProvider>(context,
                                      listen: false)
                                  .fetchGudang();
                            }
                          }
                        : null,
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
                            child: const Icon(Icons.warehouse_rounded,
                                color: AppTheme.primaryColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.namaGudang,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark
                                            ? const Color(0xFF93C5FD)
                                            : AppTheme.primaryColor)),
                                const SizedBox(height: 4),
                                Text(item.alamatGudang ?? '-',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimaryColor(
                                            context))),
                              ],
                            ),
                          ),
                          if (isSuperAdmin)
                            PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'edit') {
                                  final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              GudangFormScreen(gudang: item)));
                                  if (!context.mounted) return;
                                  if (result == true) {
                                    Provider.of<GudangProvider>(context,
                                            listen: false)
                                        .fetchGudang();
                                  }
                                } else if (action == 'delete') {
                                  _confirmDelete(context, item.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Hapus')),
                              ],
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
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Gudang'),
        content: const Text('Apakah Anda yakin ingin menghapus gudang ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<GudangProvider>(context, listen: false)
                    .deleteGudang(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Gudang berhasil dihapus.'),
                      backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Gagal: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
