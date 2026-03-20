import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_skeletons.dart';
import 'pengguna_form_screen.dart';

class PenggunaListScreen extends StatefulWidget {
  const PenggunaListScreen({super.key});

  @override
  State<PenggunaListScreen> createState() => _PenggunaListScreenState();
}

class _PenggunaListScreenState extends State<PenggunaListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false)
          .fetchUsers(refresh: true);
    });
  }

  void _loadData() {
    Provider.of<UserProvider>(context, listen: false).fetchUsers(refresh: true);
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'spectator':
        return 'Spectator';
      default:
        return 'Sales';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'super_admin':
        return AppTheme.dangerColor;
      case 'admin':
        return AppTheme.primaryColor;
      case 'spectator':
        return AppTheme.infoColor;
      default:
        return AppTheme.successColor;
    }
  }

  Future<void> _deleteUser(int id) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: const Text('Yakin ingin menghapus pengguna ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await userProvider.deleteUser(id);
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).user;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Manajemen User'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      floatingActionButton: (currentUser != null && currentUser.isSuperAdmin)
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PenggunaFormScreen()));
                if (!context.mounted) return;
                if (result == true) _loadData();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<UserProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const AppListSkeleton();
          }
          if (provider.items.isEmpty) {
            return const Center(child: Text('Belum ada data pengguna.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: provider.items.length,
              itemBuilder: (ctx, i) {
                final item = provider.items[i];
                final role = item['role'] as String?;
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
                    onTap: () async {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PenggunaFormScreen(user: item)));
                      if (result == true) _loadData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  _roleColor(role).withAlpha(isDark ? 35 : 20),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                (item['name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: _roleColor(role)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(item['name'] ?? '-',
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
                                        color: _roleColor(role)
                                            .withAlpha(isDark ? 40 : 25),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(_roleLabel(role),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _roleColor(role),
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                Text(item['email'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textTertiaryColor(
                                            context))),
                              ],
                            ),
                          ),
                          if (currentUser != null && currentUser.isSuperAdmin)
                            PopupMenuButton<String>(
                              iconSize: 20,
                              onSelected: (val) {
                                if (val == 'delete') _deleteUser(item['id']);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
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
}
