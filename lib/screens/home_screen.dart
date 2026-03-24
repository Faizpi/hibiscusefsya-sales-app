import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/biaya_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/gudang_provider.dart';
import '../providers/kunjungan_provider.dart';
import '../providers/pembayaran_provider.dart';
import '../providers/pembelian_provider.dart';
import '../providers/penerimaan_barang_provider.dart';
import '../providers/penjualan_provider.dart';
import '../providers/produk_provider.dart';
import '../providers/stok_provider.dart';
import '../utils/formatters.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import 'dashboard_screen.dart';
import 'penjualan/penjualan_list_screen.dart';
import 'pembelian/pembelian_list_screen.dart';
import 'produk/produk_list_screen.dart';
import 'kontak/kontak_list_screen.dart';
import 'biaya/biaya_list_screen.dart';
import 'pembayaran/pembayaran_list_screen.dart';
import 'penerimaan/penerimaan_list_screen.dart';
import 'kunjungan/kunjungan_list_screen.dart';
import 'gudang/gudang_list_screen.dart';
import 'gudang/stok_gudang_screen.dart';
import 'gudang/stok_log_screen.dart';
import 'pengguna/pengguna_list_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'laporan/export_report_screen.dart';

class _MenuItemData {
  final String title;
  final IconData icon;
  final Widget Function() screenBuilder;
  final String? requiredPermission;

  const _MenuItemData({
    required this.title,
    required this.icon,
    required this.screenBuilder,
    this.requiredPermission,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeDestination {
  beranda,
  aktivitas,
  profil,
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<_HomeDestination> _navDestinations = [
    _HomeDestination.beranda,
    _HomeDestination.aktivitas,
    _HomeDestination.profil,
  ];

  _HomeDestination _currentDestination = _HomeDestination.beranda;

  int get _selectedNavIndex {
    final index = _navDestinations.indexOf(_currentDestination);
    return index < 0 ? 0 : index;
  }

  int get _tabIndex {
    switch (_currentDestination) {
      case _HomeDestination.beranda:
        return 0;
      case _HomeDestination.aktivitas:
        return 1;
      case _HomeDestination.profil:
        return 2;
    }
  }

  bool _isBottomNavVisible() {
    return _navDestinations.contains(_currentDestination);
  }

  void _selectDestination(_HomeDestination destination) {
    if (_currentDestination == destination) return;
    setState(() => _currentDestination = destination);
  }

  bool _canShowGudangSwitch(dynamic user) {
    return user?.isAdmin == true || user?.isSpectator == true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (_canShowGudangSwitch(user)) {
        Provider.of<GudangProvider>(context, listen: false).fetchGudang();
      }
    });
  }

  static final List<_MenuItemData> _allMenuItems = [
    _MenuItemData(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      screenBuilder: () => const DashboardScreen(),
      requiredPermission: 'can_view_dashboard',
    ),
    _MenuItemData(
      title: 'Penjualan',
      icon: Icons.receipt_long_rounded,
      screenBuilder: () => const PenjualanListScreen(),
      requiredPermission: 'can_view_dashboard',
    ),
    _MenuItemData(
      title: 'Pembelian',
      icon: Icons.shopping_cart_rounded,
      screenBuilder: () => const PembelianListScreen(),
      requiredPermission: 'can_view_dashboard',
    ),
    _MenuItemData(
      title: 'Biaya',
      icon: Icons.account_balance_wallet_rounded,
      screenBuilder: () => const BiayaListScreen(),
      requiredPermission: 'can_view_dashboard',
    ),
    _MenuItemData(
      title: 'Kunjungan',
      icon: Icons.location_on_rounded,
      screenBuilder: () => const KunjunganListScreen(),
      requiredPermission: 'can_view_dashboard',
    ),
    _MenuItemData(
      title: 'Pembayaran',
      icon: Icons.payments_rounded,
      screenBuilder: () => const PembayaranListScreen(),
      requiredPermission: 'can_view_dashboard',
    ),
    _MenuItemData(
      title: 'Penerimaan',
      icon: Icons.local_shipping_rounded,
      screenBuilder: () => const PenerimaanListScreen(),
      requiredPermission: 'can_view_dashboard',
    ),
    _MenuItemData(
      title: 'Laporan',
      icon: Icons.summarize_rounded,
      screenBuilder: () => const ExportReportScreen(),
      requiredPermission: 'can_export_report',
    ),
    _MenuItemData(
      title: 'Kontak',
      icon: Icons.contacts_rounded,
      screenBuilder: () => const KontakListScreen(),
      requiredPermission: 'can_view_kontak',
    ),
    _MenuItemData(
      title: 'Stok Gudang',
      icon: Icons.assessment_rounded,
      screenBuilder: () => const StokGudangScreen(),
      requiredPermission: 'can_view_stock',
    ),
    _MenuItemData(
      title: 'Riwayat Stok',
      icon: Icons.history_rounded,
      screenBuilder: () => const StokLogScreen(),
      requiredPermission: 'can_view_stock_log',
    ),
    _MenuItemData(
      title: 'Produk',
      icon: Icons.inventory_2_rounded,
      screenBuilder: () => const ProdukListScreen(),
      requiredPermission: 'can_manage_produk',
    ),
    _MenuItemData(
      title: 'Gudang',
      icon: Icons.warehouse_rounded,
      screenBuilder: () => const GudangListScreen(),
      requiredPermission: 'can_manage_gudang',
    ),
    _MenuItemData(
      title: 'Manajemen User',
      icon: Icons.people_rounded,
      screenBuilder: () => const PenggunaListScreen(),
      requiredPermission: 'can_manage_users',
    ),
  ];

  // First 8 menus shown on beranda grid
  static const int _mainMenuCount = 8;

  List<_MenuItemData> _getMenuForRole(dynamic user) {
    return _allMenuItems.where((item) {
      if (item.title == 'Laporan') {
        final canExportFull = user?.hasPermission('can_export_report') == true;
        final isSalesUser = user?.isUser == true;
        return canExportFull || isSalesUser;
      }

      if (item.requiredPermission == null) return true;
      return user?.hasPermission(item.requiredPermission!) == true;
    }).toList();
  }

  List<Map<String, String>> _buildNotifications(
      dynamic user, Map<String, dynamic> data) {
    final notifications = <Map<String, String>>[];

    final pendingApproval =
        int.tryParse('${data['pending_approval'] ?? 0}') ?? 0;
    if (user?.hasPermission('can_approve_transaction') == true &&
        pendingApproval > 0) {
      notifications.add({
        'title': 'Menunggu Approval',
        'body': '$pendingApproval transaksi perlu Anda approve.',
      });
    }

    final recentActivity = (data['recent_activity'] as List?) ??
        (data['recent_penjualan'] as List?) ??
        [];
    if (user?.isUser == true) {
      for (final raw in recentActivity.take(10)) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final status = (item['status'] ?? '').toString();
        if (status != 'Approved' &&
            status != 'Rejected' &&
            status != 'Canceled' &&
            status != 'Lunas') {
          continue;
        }

        final nomor = (item['nomor'] ?? item['invoice'] ?? '-').toString();
        final tgl = item['tgl_transaksi']?.toString();
        final subtitle = tgl != null && tgl.isNotEmpty
            ? 'Status $status ΓÇó ${Formatters.dateTime(tgl)}'
            : 'Status $status';
        notifications.add({
          'title': nomor,
          'body': subtitle,
        });
      }
    }

    return notifications;
  }

  void _openNotifications(List<Map<String, String>> notifications) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        if (notifications.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Belum ada notifikasi.'),
            ),
          );
        }

        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.dividerColorOf(context),
            ),
            itemBuilder: (ctx, i) {
              final n = notifications[i];
              return ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(n['title'] ?? '-'),
                subtitle: Text(n['body'] ?? ''),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final selectedColor = isDark ? Colors.white : const Color(0xFF101828);
    final unselectedColor =
        isDark ? Colors.white.withAlpha(165) : const Color(0xFF6B7280);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg(context),
        body: Stack(
          children: [
            // Main content
            IndexedStack(
              index: _tabIndex,
              children: [
                _buildBerandaTab(),
                const DashboardScreen(),
                const ProfileScreen(),
              ],
            ),
            // Floating glass navbar overlaid on top of content
            if (_isBottomNavVisible())
              Positioned(
                left: 28,
                right: 28,
                bottom: MediaQuery.of(context).padding.bottom + 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppTheme.glassBlur(context, base: 28),
                      sigmaY: AppTheme.glassBlur(context, base: 28),
                    ),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppTheme.glassColor(context)
                            .withAlpha(isDark ? 124 : 154),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.glassBorderColor(context)
                              .withAlpha(isDark ? 100 : 150),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 42 : 14),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white.withAlpha(isDark ? 4 : 20),
                            blurRadius: 14,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Moving orb (not full capsule) like iOS liquid tab focus.
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutQuart,
                            alignment:
                                Alignment(-1 + _selectedNavIndex.toDouble(), 0),
                            child: FractionallySizedBox(
                              widthFactor: 1 / 3,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withAlpha(isDark ? 18 : 70),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white
                                              .withAlpha(isDark ? 8 : 30),
                                          blurRadius: 12,
                                          offset: const Offset(0, -1),
                                        ),
                                        BoxShadow(
                                          color: Colors.black
                                              .withAlpha(isDark ? 20 : 8),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Align(
                                      alignment: const Alignment(-0.25, -0.3),
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withAlpha(isDark ? 22 : 120),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _buildNavItem(
                                _HomeDestination.beranda,
                                Icons.home_rounded,
                                Icons.home_outlined,
                                'Beranda',
                                selectedColor,
                                unselectedColor,
                              ),
                              _buildNavItem(
                                _HomeDestination.aktivitas,
                                Icons.bar_chart_rounded,
                                Icons.bar_chart_outlined,
                                'Aktivitas',
                                selectedColor,
                                unselectedColor,
                              ),
                              _buildNavItem(
                                _HomeDestination.profil,
                                Icons.person_rounded,
                                Icons.person_outlined,
                                'Profil',
                                selectedColor,
                                unselectedColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    _HomeDestination destination,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final isSelected = _currentDestination == destination;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectDestination(destination),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 18.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textScaler: const TextScaler.linear(1.0),
              style: TextStyle(
                fontSize: 8.8,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
                height: 1.0,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBerandaTab() {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final menuAspectRatio = textScale > 1.05 ? 0.72 : 0.80;
    final auth = Provider.of<AuthProvider>(context);
    final dashboard = Provider.of<DashboardProvider>(context);
    final user = auth.user;
    final notifications = _buildNotifications(user, dashboard.data);
    final menuItems = _getMenuForRole(user);
    final mainMenus = menuItems.length > _mainMenuCount
        ? menuItems.sublist(0, _mainMenuCount)
        : menuItems;
    final hasMoreMenus = menuItems.length > _mainMenuCount;

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<DashboardProvider>(context, listen: false)
            .fetchDashboard();
      },
      child: CustomScrollView(
        slivers: [
          // Clean greeting header ΓÇö on scaffold bg, not gradient
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.glassColor(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.glassBorderColor(context),
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/hibiscusefsya1-removebg-preview.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Greeting text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user?.name ?? ''}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimaryColor(context),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Selamat datang di Hibiscus Efsya',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondaryColor(context),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Notification bell
                        GestureDetector(
                          onTap: () => _openNotifications(notifications),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.glassColor(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.glassBorderColor(context),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: AppTheme.textSecondaryColor(context),
                                    size: 20,
                                  ),
                                ),
                                if (notifications.isNotEmpty)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                          minWidth: 14, minHeight: 14),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dangerColor,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        notifications.length > 9
                                            ? '9+'
                                            : notifications.length.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Profile avatar
                        GestureDetector(
                          onTap: () =>
                              _selectDestination(_HomeDestination.profil),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.mainGradient(context),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withAlpha(32),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Gudang switch is explicitly shown in Home for
                    // admin/spectator accounts.
                    if (user != null && _canShowGudangSwitch(user)) ...[
                      const SizedBox(height: 14),
                      _buildGudangSwitch(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Menu section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withAlpha(40),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu grid section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width < 360 ? 3 : 4,
                        childAspectRatio: menuAspectRatio,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: mainMenus.length,
                      itemBuilder: (context, index) {
                        final item = mainMenus[index];
                        return _buildMenuItem(item, index);
                      },
                    ),
                    if (hasMoreMenus) ...[
                      const Divider(height: 20),
                      InkWell(
                        onTap: () => _showAllMenus(menuItems),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Menu Lainnya',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.isDark(context)
                                      ? const Color(0xFF93C5FD)
                                      : AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppTheme.isDark(context)
                                    ? const Color(0xFF93C5FD)
                                    : AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Quick stats summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aksi Cepat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withAlpha(40),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick action cards - 2x2 grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Builder(
                builder: (ctx) {
                  final quickCards = <Widget>[];
                  if (user?.hasPermission('can_create_transaction') == true) {
                    quickCards.addAll([
                      _buildQuickAction(
                        icon: Icons.add_shopping_cart_rounded,
                        label: 'Penjualan Baru',
                        iconColor: AppTheme.primaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PenjualanListScreen()),
                        ),
                      ),
                      _buildQuickAction(
                        icon: Icons.location_on_rounded,
                        label: 'Catat Kunjungan',
                        iconColor: AppTheme.accentColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KunjunganListScreen()),
                        ),
                      ),
                      _buildQuickAction(
                        icon: Icons.shopping_cart_rounded,
                        label: 'Pembelian Baru',
                        iconColor: AppTheme.successColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PembelianListScreen()),
                        ),
                      ),
                    ]);
                  }

                  if (user?.hasPermission('can_view_stock') == true) {
                    quickCards.add(
                      _buildQuickAction(
                        icon: Icons.assessment_rounded,
                        label: 'Cek Stok',
                        iconColor: AppTheme.warningColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StokGudangScreen()),
                        ),
                      ),
                    );
                  }

                  final canOpenReport = user?.isUser == true;
                  if (canOpenReport) {
                    quickCards.add(
                      _buildQuickAction(
                        icon: Icons.summarize_rounded,
                        label: 'Laporan',
                        iconColor: AppTheme.primaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExportReportScreen()),
                        ),
                      ),
                    );
                  }

                  if (quickCards.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: quickCards
                        .map(
                          (w) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 44) / 2,
                            child: w,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      borderRadius: 16,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  iconColor.withAlpha(40),
                  iconColor.withAlpha(15),
                ],
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.screenBuilder()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.menuIconColor(index)
                  .withAlpha(AppTheme.isDark(context) ? 35 : 20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: AppTheme.isDark(context)
                  ? AppTheme.menuIconColor(index).withAlpha(230)
                  : AppTheme.menuIconColor(index),
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            textScaler: const TextScaler.linear(1.0),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor(context),
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showAllMenus(List<_MenuItemData> menuItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllMenuScreen(menuItems: menuItems),
      ),
    );
  }

  Future<void> _refreshWarehouseScopedData(int gudangId) async {
    // Refresh all warehouse-sensitive modules after switch so data from
    // previous warehouse does not remain in list caches.
    final refreshTasks = <Future<void>>[
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard(),
      Provider.of<StokProvider>(context, listen: false)
          .fetchStok(gudangId: gudangId),
      Provider.of<ProdukProvider>(context, listen: false).fetchProduk(),
      Provider.of<PenjualanProvider>(context, listen: false)
          .fetchPenjualan(refresh: true),
      Provider.of<PembelianProvider>(context, listen: false)
          .fetchPembelian(refresh: true),
      Provider.of<KunjunganProvider>(context, listen: false)
          .fetchKunjungan(refresh: true),
      Provider.of<PembayaranProvider>(context, listen: false)
          .fetchPembayaran(refresh: true),
      Provider.of<PenerimaanBarangProvider>(context, listen: false)
          .fetchPenerimaan(refresh: true),
      Provider.of<BiayaProvider>(context, listen: false)
          .fetchBiaya(refresh: true),
    ];

    for (final task in refreshTasks) {
      try {
        await task;
      } catch (e) {
        debugPrint('Refresh setelah switch gudang gagal: $e');
      }
      if (!mounted) return;
    }
  }

  Widget _buildGudangSwitch() {
    final isDark = AppTheme.isDark(context);
    return Consumer<GudangProvider>(
      builder: (ctx, gudangProv, _) {
        if (gudangProv.items.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            gudangProv.fetchGudang();
          });
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppTheme.softBluePinkSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorderColor(context)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Memuat data gudang...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          );
        }

        final auth = Provider.of<AuthProvider>(context, listen: false);
        final currentGudangId =
            auth.user?.currentGudangId ?? auth.user?.gudangId;
        final isSwitchEnabled = gudangProv.items.length > 1;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.softBluePinkSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF2563EB))
                    .withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              isDense: true,
              value: gudangProv.items.any((g) => g.id == currentGudangId)
                  ? currentGudangId
                  : null,
              hint: Text('Pilih Gudang',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiaryColor(context))),
              icon: Icon(Icons.warehouse_outlined,
                  size: 18, color: AppTheme.textTertiaryColor(context)),
              dropdownColor: AppTheme.cardBg(context),
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimaryColor(context),
                  fontFamily: 'Poppins'),
              selectedItemBuilder: (context) {
                return gudangProv.items.map((g) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      g.namaGudang,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimaryColor(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: gudangProv.items
                  .map((g) => DropdownMenuItem(
                      value: g.id,
                      child: Text(g.namaGudang,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: isSwitchEnabled
                  ? (id) async {
                      if (id == null) return;
                      try {
                        await gudangProv.switchGudang(id);
                        if (!mounted) return;
                        await auth.refreshProfile();
                        if (!mounted) return;
                        await _refreshWarehouseScopedData(id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Gudang berhasil diganti'),
                              backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Gagal: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.dangerColor, size: 22),
            SizedBox(width: 10),
            Text('Keluar', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

/// Full-page menu screen (like BCA "Menu Lainnya")
class _AllMenuScreen extends StatelessWidget {
  final List<_MenuItemData> menuItems;
  const _AllMenuScreen({required this.menuItems});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final menuAspectRatio = textScale > 1.05 ? 0.72 : 0.80;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Semua Menu'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 360 ? 3 : 4,
              childAspectRatio: menuAspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.screenBuilder()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.menuIconColor(index)
                            .withAlpha(AppTheme.isDark(context) ? 35 : 20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: AppTheme.isDark(context)
                            ? AppTheme.menuIconColor(index).withAlpha(230)
                            : AppTheme.menuIconColor(index),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor(context),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
