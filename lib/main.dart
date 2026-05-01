import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/penjualan_provider.dart';
import 'providers/pembelian_provider.dart';
import 'providers/produk_provider.dart';
import 'providers/kontak_provider.dart';
import 'providers/kunjungan_provider.dart';
import 'providers/biaya_provider.dart';
import 'providers/pembayaran_provider.dart';
import 'providers/penerimaan_barang_provider.dart';
import 'providers/gudang_provider.dart';
import 'providers/stok_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'widgets/glass_container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PenjualanProvider>(
          create: (_) => PenjualanProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PembelianProvider>(
          create: (_) => PembelianProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProdukProvider>(
          create: (_) => ProdukProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, KontakProvider>(
          create: (_) => KontakProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, KunjunganProvider>(
          create: (_) => KunjunganProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BiayaProvider>(
          create: (_) => BiayaProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PembayaranProvider>(
          create: (_) => PembayaranProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PenerimaanBarangProvider>(
          create: (_) => PenerimaanBarangProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, GudangProvider>(
          create: (_) => GudangProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StokProvider>(
          create: (_) => StokProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, prev) => prev!..updateToken(auth.token),
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (ctx, auth, themeProv, _) => MaterialApp(
          title: 'JURNAL HE M.B.K',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final mediaQuery = MediaQuery.of(context);
            final normalizedMediaQuery = mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.95,
                maxScaleFactor: 1.15,
              ),
            );

            return MediaQuery(
              data: normalizedMediaQuery,
              child: GlobalGlassBackground(child: child),
            );
          },
          routes: {
            '/login': (_) => const LoginScreen(),
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
