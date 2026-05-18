import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/formatters.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/app_skeletons.dart';
import 'laporan/export_report_screen.dart';

// Safely parse dynamic value (String or num) to double
double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient(context)),
        ),
      ),
      body: Consumer2<AuthProvider, DashboardProvider>(
        builder: (ctx, auth, dashboard, _) {
          if (dashboard.isLoading) {
            return const AppFormSkeleton();
          }

          if (dashboard.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.error_outline,
                          size: 32, color: AppTheme.dangerColor),
                    ),
                    const SizedBox(height: 16),
                    Text(dashboard.error!,
                        style: const TextStyle(color: AppTheme.dangerColor),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => dashboard.fetchDashboard(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = dashboard.data;
          final user = auth.user;
          final canOpenReport =
              user?.hasPermission('can_export_report') == true ||
                  user?.isUser == true;

          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () => dashboard.fetchDashboard(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome section
                GlassContainer(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      // Subtle gradient overlay on the left
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppTheme.primaryColor
                                    .withAlpha(isDark ? 25 : 18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat datang,',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          AppTheme.textSecondaryColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.name ?? '',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimaryColor(context),
                                    ),
                                  ),
                                  if (data['current_gudang'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warehouse_outlined,
                                              size: 14,
                                              color:
                                                  AppTheme.textSecondaryColor(
                                                      context)),
                                          const SizedBox(width: 4),
                                          Text(
                                            data['current_gudang'].toString(),
                                            style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppTheme.textSecondaryColor(
                                                        context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Generate Report button by permission matrix.
                            if (canOpenReport)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: dashboard.isGenerating
                                      ? null
                                      : () => _showReportDialog(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.buttonGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withAlpha(40),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: dashboard.isGenerating
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.assessment_outlined,
                                                  size: 16,
                                                  color: Colors.white),
                                              SizedBox(width: 6),
                                              Text('Report',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Kanban summary cards (below export action, above stat cards)
                _buildSummaryKanban(
                  title: 'Ringkasan Hari Ini',
                  icon: Icons.today_rounded,
                  accent: AppTheme.primaryColor,
                  rows: [
                    _SummaryRowData(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Penjualan',
                      amount: _safeDouble(data['daily_penjualan']),
                      count: data['daily_penjualan_count'] ?? 0,
                      color: AppTheme.primaryColor,
                    ),
                    _SummaryRowData(
                      icon: Icons.receipt_long_outlined,
                      label: 'Biaya',
                      amount: _safeDouble(data['daily_biaya']),
                      count: data['daily_biaya_count'] ?? 0,
                      color: AppTheme.dangerColor,
                    ),
                    _SummaryRowData(
                      icon: Icons.payments_outlined,
                      label: 'Pembayaran',
                      amount: _safeDouble(data['daily_pembayaran']),
                      count: data['daily_pembayaran_count'] ?? 0,
                      color: AppTheme.infoColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildSummaryKanban(
                  title: 'Ringkasan Bulan Ini',
                  icon: Icons.calendar_month_rounded,
                  accent: AppTheme.successColor,
                  rows: [
                    _SummaryRowData(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Penjualan',
                      amount: _safeDouble(data['total_penjualan_bulan_ini']),
                      count: data['penjualan_count_bulan_ini'] ??
                          data['penjualan_bulan_ini'] ??
                          0,
                      color: AppTheme.primaryColor,
                    ),
                    _SummaryRowData(
                      icon: Icons.receipt_long_outlined,
                      label: 'Biaya',
                      amount: _safeDouble(data['biaya_bulan_ini']),
                      count: data['biaya_count_bulan_ini'] ?? 0,
                      color: AppTheme.dangerColor,
                    ),
                    _SummaryRowData(
                      icon: Icons.payments_outlined,
                      label: 'Pembayaran',
                      amount: _safeDouble(data['total_pembayaran_bulan_ini']),
                      count: data['pembayaran_bulan_ini'] ?? 0,
                      color: AppTheme.infoColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stat cards grid
                _buildStatRow(
                  _StatCardData(
                    label: 'PENJUALAN',
                    value: Formatters.currency(
                        data['total_penjualan_bulan_ini'] ?? 0),
                    sub: '${data['penjualan_bulan_ini'] ?? 0} transaksi',
                    color: AppTheme.primaryColor,
                    icon: Icons.shopping_cart_outlined,
                  ),
                  _StatCardData(
                    label: 'PEMBELIAN',
                    value: Formatters.currency(
                        data['total_pembelian_bulan_ini'] ?? 0),
                    sub: '${data['pembelian_bulan_ini'] ?? 0} transaksi',
                    color: AppTheme.successColor,
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                _buildStatRow(
                  _StatCardData(
                    label: 'KUNJUNGAN',
                    value: '${data['kunjungan_bulan_ini'] ?? 0}',
                    sub: '${data['kunjungan_bulan_ini'] ?? 0} kunjungan bulan ini',
                    color: AppTheme.infoColor,
                    icon: Icons.location_on_outlined,
                  ),
                  _StatCardData(
                    label: 'PENDING',
                    value: '${data['pending_approval'] ?? 0}',
                    sub: 'menunggu persetujuan',
                    color: AppTheme.dangerColor,
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                _buildStatRow(
                  _StatCardData(
                    label: 'BIAYA MASUK',
                    value: Formatters.currency(data['biaya_masuk_bulan_ini'] ?? 0),
                    sub: 'penerimaan bulan ini',
                    color: AppTheme.successColor,
                    icon: Icons.arrow_downward_rounded,
                  ),
                  _StatCardData(
                    label: 'BIAYA KELUAR',
                    value: Formatters.currency(data['biaya_keluar_bulan_ini'] ?? data['biaya_bulan_ini'] ?? 0),
                    sub: 'pengeluaran bulan ini',
                    color: const Color(0xFFEF4444),
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(height: 12),

                _buildStatRow(
                  _StatCardData(
                    label: 'TOTAL PRODUK',
                    value: '${data['total_produk'] ?? '-'}',
                    sub: '',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.inventory_2_outlined,
                  ),
                  _StatCardData(
                    label: 'JUMLAH USER',
                    value: '${data['total_user'] ?? '-'}',
                    sub: '',
                    color: const Color(0xFF64748B),
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(height: 24),

                // Pie Chart Section
                _buildSectionTitle('Distribusi Transaksi'),
                const SizedBox(height: 12),
                _buildPieChart(data),
                const SizedBox(height: 24),

                // Line Chart Section
                _buildSectionTitle('Trend Bulan Ini'),
                const SizedBox(height: 12),
                _buildLineChart(data),
                const SizedBox(height: 24),

                // Recent activity section
                _buildSectionTitle('Aktivitas Terbaru',
                    badge: data['total_transaksi'] != null
                        ? '${data['total_transaksi']} data'
                        : null),
                const SizedBox(height: 12),
                ..._buildRecentActivity(data),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? badge}) {
    return Row(
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
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor(context)),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.isDark(context)
                  ? AppTheme.primaryColor.withAlpha(30)
                  : AppTheme.pinkLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.isDark(context)
                      ? AppTheme.primaryLight
                      : AppTheme.pinkAccent,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  // Pie Chart
  Widget _buildPieChart(Map<String, dynamic> data) {
    final penjualan = _safeDouble(data['penjualan_bulan_ini']);
    final pembelian = _safeDouble(data['pembelian_bulan_ini']);
    final kunjungan = _safeDouble(data['kunjungan_bulan_ini']);
    final canceled =
        _safeDouble(data['canceled_bulan_ini'] ?? data['pending_approval']);

    final total = penjualan + pembelian + kunjungan + canceled;

    final sections = <_PieData>[
      _PieData('Penjualan', penjualan, AppTheme.primaryColor),
      _PieData('Pembelian', pembelian, AppTheme.successColor),
      _PieData('Kunjungan', kunjungan, AppTheme.pinkAccent),
      _PieData('Canceled', canceled, AppTheme.dangerColor),
    ];

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: total == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Belum ada data transaksi',
                    style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        fontSize: 13)),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: sections.where((s) => s.value > 0).map((s) {
                            return PieChartSectionData(
                              color: s.color,
                              value: s.value,
                              title:
                                  '${(s.value / total * 100).toStringAsFixed(0)}%',
                              radius: 35,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondaryColor(context))),
                          const SizedBox(height: 2),
                          Text('${total.toInt()}',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimaryColor(context))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: sections.map((s) {
                    final pct = total > 0
                        ? (s.value / total * 100).toStringAsFixed(1)
                        : '0.0';
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${s.label} ${s.value.toInt()} ($pct%)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  // Line Chart
  Widget _buildLineChart(Map<String, dynamic> data) {
    // Generate sample trend data from dashboard data
    final totalPenjualan = _safeDouble(data['total_penjualan_bulan_ini']);
    final totalPembelian = _safeDouble(data['total_pembelian_bulan_ini']);

    // Create a simple 7-point trend line from the totals
    final penjualanSpots = <FlSpot>[];
    final pembelianSpots = <FlSpot>[];

    for (int i = 0; i < 7; i++) {
      final factor = [0.3, 0.5, 0.7, 0.45, 0.8, 0.65, 1.0][i];
      penjualanSpots.add(FlSpot(i.toDouble(), totalPenjualan * factor / 7));
      pembelianSpots.add(FlSpot(i.toDouble(), totalPembelian * factor / 7));
    }

    final maxY = [
          ...penjualanSpots.map((s) => s.y),
          ...pembelianSpots.map((s) => s.y),
          1.0,
        ].reduce((a, b) => a > b ? a : b) *
        1.2;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.borderColorOf(context),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          Formatters.compactCurrency(value),
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.textTertiaryColor(context),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = [
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                          'Min'
                        ];
                        if (value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textTertiaryColor(context),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final color = spot.bar.color ?? Colors.white;
                        return LineTooltipItem(
                          Formatters.compactCurrency(spot.y),
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: penjualanSpots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.primaryColor,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor.withAlpha(60),
                          AppTheme.primaryColor.withAlpha(8),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: pembelianSpots,
                    isCurved: true,
                    color: AppTheme.pinkAccent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.pinkAccent,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.pinkAccent.withAlpha(45),
                          AppTheme.pinkAccent.withAlpha(8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend('Penjualan', AppTheme.primaryColor),
              const SizedBox(width: 24),
              _chartLegend('Pembelian', AppTheme.pinkAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(_StatCardData left, _StatCardData right) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(left)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(right)),
      ],
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return GlassContainer(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryColor(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: data.color
                                .withAlpha(AppTheme.isDark(context) ? 35 : 20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(data.icon, size: 16, color: data.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          data.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    if (data.sub.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(data.sub,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondaryColor(context))),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryKanban({
    required String title,
    required IconData icon,
    required Color accent,
    required List<_SummaryRowData> rows,
  }) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withAlpha(AppTheme.isDark(context) ? 35 : 20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
              ),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Rows
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(
                    height: 1,
                    color: AppTheme.dividerColorOf(context),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: row.color
                              .withAlpha(AppTheme.isDark(context) ? 30 : 15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(row.icon, size: 14, color: row.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${row.count} transaksi',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textTertiaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(row.amount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExportReportScreen(),
      ),
    );
  }

  List<Widget> _buildRecentActivity(Map<String, dynamic> data) {
    List? activities = data['recent_activity'] as List?;
    final recentPenjualan = data['recent_penjualan'] as List?;

    if ((activities == null || activities.isEmpty) &&
        (recentPenjualan == null || recentPenjualan.isEmpty)) {
      return [
        GlassContainer.faux(
          borderRadius: 16,
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_rounded,
                    size: 40, color: AppTheme.textTertiaryColor(context)),
                const SizedBox(height: 8),
                Text('Belum ada transaksi.',
                    style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ];
    }

    final items = activities ?? recentPenjualan ?? [];

    return [
      GlassContainer.faux(
        borderRadius: 16,
        child: Column(
          children: [
            ...items.take(15).toList().asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final t = entry.value;
              final nomor = (t['nomor'] ?? '-').toString();
              final status = t['status'] ?? 'Pending';
              final total = t['grand_total'] ?? t['total'] ?? 0;
              final tanggal = t['tgl_transaksi'];
              final pelanggan = (t['pelanggan'] ??
                      t['supplier'] ??
                      t['nama_kontak'] ??
                      t['kontak']?['nama'] ??
                      '')
                  .toString();
              // pembuat extracted in _showTransactionDetail if needed
              final avatarColor = AppTheme
                  .menuIconColors[index % AppTheme.menuIconColors.length];
              final firstLetter =
                  nomor.isNotEmpty ? nomor[0].toUpperCase() : '?';

              return Column(
                children: [
                  InkWell(
                    onTap: () => _showTransactionDetail(context, t),
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Circle avatar
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: avatarColor.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                firstLetter,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: avatarColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Invoice + name + date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nomor,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppTheme.textPrimaryColor(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (pelanggan.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(pelanggan,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondaryColor(
                                                context)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                if (tanggal != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(Formatters.dateTime(tanggal),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textTertiaryColor(
                                                context))),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status + amount
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.3,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  total != 0 ? Formatters.currency(total) : '-',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          AppTheme.textPrimaryColor(context)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                _StatusBadge(status: status),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < items.take(15).length - 1)
                    Divider(
                        height: 1,
                        indent: 64,
                        color: AppTheme.dividerColorOf(context)),
                ],
              );
            }),
          ],
        ),
      ),
    ];
  }

  void _showTransactionDetail(BuildContext context, Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final nomor = t['nomor'] ?? '-';
        final tipe = t['tipe'] ?? 'Penjualan';
        final status = t['status'] ?? 'Pending';
        final total = t['grand_total'] ?? t['total'] ?? 0;
        final tanggal = t['tgl_transaksi'];
        final pelanggan = (t['pelanggan'] ??
                t['supplier'] ??
                t['nama_kontak'] ??
                t['kontak']?['nama'] ??
                '')
            .toString();
        final pembuat = (t['dibuat_oleh'] ??
                t['user']?['name'] ??
                t['created_by_name'] ??
                '')
            .toString();

        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textTertiaryColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Detail Transaksi',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor(context))),
                const SizedBox(height: 16),
                _detailRow('Tipe', tipe),
                _detailRow('Nomor Invoice', nomor),
                if (pelanggan.isNotEmpty)
                  _detailRow('Pelanggan/Vendor', pelanggan),
                if (pembuat.isNotEmpty) _detailRow('Dibuat Oleh', pembuat),
                _detailRow('Tanggal',
                    tanggal != null ? Formatters.dateTime(tanggal) : '-'),
                _detailRow('Status', status),
                _detailRow(
                    'Total', total != 0 ? Formatters.currency(total) : '-'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Text(':',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondaryColor(context))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  const _PieData(this.label, this.value, this.color);
}

class _SummaryRowData {
  final IconData icon;
  final String label;
  final double amount;
  final dynamic count;
  final Color color;

  const _SummaryRowData({
    required this.icon,
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
  });
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 10,
            color: AppTheme.statusColor(status),
            fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}
