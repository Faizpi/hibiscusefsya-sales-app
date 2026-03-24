import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Global multiplier for glass blur intensity.
  // 0.3 means around 30% of the original blur strength.
  static const double glassBlurStrength = 0.4;

  // ── Core Brand Colors ──
  static const Color primaryColor = Color(0xFF3B82F6); // Soft blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEAF3FF);
  static const Color primarySurface = Color(0xFFF0F5FF);
  static const Color pinkAccent = Color(0xFFF472B6); // Soft pink accent
  static const Color pinkLight = Color(0xFFFDE8F3);

  // Accent / Secondary
  static const Color accentColor = Color(0xFFEC4899);
  static const Color accentLight = Color(0xFFFCE7F3);

  // Semantic
  static const Color successColor = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningColor = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color infoColor = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Light Neutrals ──
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color bgSecondary = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color dividerColor = Color(0xFFF1F5F9);

  // ── Dark Neutrals ──
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkBgSecondary = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF334155);

  // ── Gradients (Soft Blue -> Soft Pink, cohesive system-wide) ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF567FE6),
      Color(0xFF759BEA),
      Color(0xFFC789AF),
    ],
    stops: [0.0, 0.58, 1.0],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF567FE6),
      Color(0xFF759BEA),
      Color(0xFFC789AF),
    ],
    stops: [0.0, 0.58, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F79E8),
      Color(0xFF6F93E8),
      Color(0xFFC274A4),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEAF1FF),
      Color(0xFFF4F7FF),
      Color(0xFFFBEFF7),
    ],
    stops: [0.0, 0.62, 1.0],
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF243B66),
      Color(0xFF2F4D7F),
      Color(0xFF5A3B60),
    ],
    stops: [0.0, 0.58, 1.0],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A263D),
      Color(0xFF202F4A),
      Color(0xFF3A2941),
    ],
    stops: [0.0, 0.62, 1.0],
  );

  // For menu icon backgrounds
  static const List<Color> menuIconColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF059669), // Green
    Color(0xFFD97706), // Amber
    Color(0xFF7C3AED), // Purple
    Color(0xFF0EA5E9), // Sky
    Color(0xFFDC2626), // Red
    Color(0xFF0D9488), // Teal
    Color(0xFFEC4899), // Pink
    Color(0xFF4F46E5), // Indigo
    Color(0xFFF97316), // Orange
    Color(0xFF2563EB), // Blue bright
    Color(0xFF64748B), // Slate
    Color(0xFF8B5CF6), // Violet
  ];

  static Color menuIconColor(int index) {
    return menuIconColors[index % menuIconColors.length];
  }

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withAlpha(10),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF2563EB).withAlpha(12),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withAlpha(8),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get floatingNavShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withAlpha(12),
          blurRadius: 24,
          offset: const Offset(0, -2),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF2563EB).withAlpha(6),
          blurRadius: 40,
          offset: const Offset(0, -4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withAlpha(40),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get darkFloatingNavShadow => [
        BoxShadow(
          color: Colors.black.withAlpha(50),
          blurRadius: 24,
          offset: const Offset(0, -2),
          spreadRadius: 0,
        ),
      ];

  // ── Light Theme ──
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primaryColor,
    brightness: Brightness.light,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: const Color(0xFFF6FAFF),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, height: 1.25),
      titleMedium: TextStyle(fontSize: 16, height: 1.28),
      bodyLarge: TextStyle(fontSize: 16, height: 1.35),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35),
      bodySmall: TextStyle(fontSize: 12, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, height: 1.2),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: const Color(0x284FA8FF),
        overlayColor: Colors.white.withAlpha(20),
        surfaceTintColor: Colors.white.withAlpha(30),
        side: BorderSide(color: Colors.white.withAlpha(90), width: 1),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        backgroundColor: Colors.white.withAlpha(80),
        side: BorderSide(color: Colors.white.withAlpha(160), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shadowColor: Colors.transparent,
        overlayColor: Colors.white.withAlpha(26),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        backgroundColor: Colors.white.withAlpha(50),
        side: BorderSide(color: Colors.white.withAlpha(120), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: 0,
        shadowColor: Colors.transparent,
        overlayColor: Colors.white.withAlpha(24),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: CircleBorder(),
    ),
    chipTheme: ChipThemeData(
      selectedColor: primaryColor.withAlpha(25),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: textPrimary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondary,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  // ── Dark Theme ──
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primaryColor,
    brightness: Brightness.dark,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: darkBg,
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, height: 1.25),
      titleMedium: TextStyle(fontSize: 16, height: 1.28),
      bodyLarge: TextStyle(fontSize: 16, height: 1.35),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35),
      bodySmall: TextStyle(fontSize: 12, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, height: 1.2),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBgSecondary,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: darkCard,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: const Color(0x442563EB),
        overlayColor: Colors.white.withAlpha(24),
        surfaceTintColor: Colors.white.withAlpha(18),
        side: BorderSide(color: Colors.white.withAlpha(55), width: 1),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF93C5FD),
        backgroundColor: Colors.white.withAlpha(10),
        side: BorderSide(color: Colors.white.withAlpha(45), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shadowColor: Colors.transparent,
        overlayColor: Colors.white.withAlpha(22),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF93C5FD),
        backgroundColor: Colors.white.withAlpha(8),
        side: BorderSide(color: Colors.white.withAlpha(32), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: 0,
        shadowColor: Colors.transparent,
        overlayColor: Colors.white.withAlpha(20),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: darkTextTertiary, fontSize: 14),
      labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: CircleBorder(),
    ),
    chipTheme: ChipThemeData(
      selectedColor: primaryColor.withAlpha(40),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF334155),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: Color(0xFF93C5FD),
      unselectedItemColor: darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      surfaceTintColor: Colors.transparent,
      backgroundColor: darkCard,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      surfaceTintColor: Colors.transparent,
      backgroundColor: darkCard,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Color(0xFF93C5FD),
      unselectedLabelColor: darkTextSecondary,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  // ── Theme-aware helpers ──
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? darkBg : const Color(0xFFF6FAFF);

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkCard : cardColor;

  static Color textPrimaryColor(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color textTertiaryColor(BuildContext context) =>
      isDark(context) ? darkTextTertiary : textTertiary;

  static Color borderColorOf(BuildContext context) =>
      isDark(context) ? darkBorder : borderColor;

  static Color dividerColorOf(BuildContext context) =>
      isDark(context) ? darkDivider : dividerColor;

  static Color bgSecondaryColor(BuildContext context) =>
      isDark(context) ? darkBgSecondary : bgSecondary;

  static LinearGradient mainGradient(BuildContext context) =>
      isDark(context) ? darkPrimaryGradient : primaryGradient;

  static LinearGradient cardGradientOf(BuildContext context) =>
      isDark(context) ? darkCardGradient : cardGradient;

  static LinearGradient softBluePinkSurface(BuildContext context) {
    if (isDark(context)) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A2740),
          Color(0xFF253550),
          Color(0xFF35273E),
        ],
        stops: [0.0, 0.62, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFEFF5FF),
        Color(0xFFF5F2FF),
        Color(0xFFFCEFF8),
      ],
      stops: [0.0, 0.62, 1.0],
    );
  }

  static List<BoxShadow> cardShadowOf(BuildContext context) =>
      isDark(context) ? darkCardShadow : cardShadow;

  static List<BoxShadow> navShadowOf(BuildContext context) =>
      isDark(context) ? darkFloatingNavShadow : floatingNavShadow;

  // ── Glass Helpers ──
  static Color glassColor(BuildContext context) => isDark(context)
      ? const Color(0xFF1A2538).withAlpha(164)
      : const Color(0xFFF9FBFF).withAlpha(202);

  static Color glassBorderColor(BuildContext context) => isDark(context)
      ? Colors.white.withAlpha(36)
      : const Color(0xFFC7D9FF).withAlpha(184);

  static Color glassInputFill(BuildContext context) =>
      isDark(context) ? Colors.white.withAlpha(10) : Colors.white.withAlpha(154);

  static Color glassChipBg(BuildContext context) => isDark(context)
      ? Colors.white.withAlpha(10)
      : Colors.white.withAlpha(140);

  /// Screen-aware blur scale.
  /// Compact phones get lighter blur for smoother performance.
  static double glassDeviceScale(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return 1.0;

    final shortestSide = mq.size.shortestSide;
    final dpr = mq.devicePixelRatio;

    if (shortestSide <= 360) return 0.72;
    if (shortestSide <= 392) return 0.82;
    if (shortestSide <= 430 && dpr <= 2.3) return 0.9;
    if (shortestSide >= 900) return 1.12;
    return 1.0;
  }

  /// Theme-aware + device-aware blur sigma.
  static double glassBlur(
    BuildContext context, {
    double base = 12,
    double darkBoost = 1.4,
    double min = 6,
    double max = 24,
  }) {
    final themedBase = isDark(context) ? base * darkBoost : base;
    final scaled = themedBase * glassDeviceScale(context);
    final adjusted = scaled * glassBlurStrength;
    return adjusted.clamp(2.0, max * glassBlurStrength);
  }

  /// Overlay alpha used above the global glass blur layer.
  static int glassOverlayAlpha(BuildContext context,
      {int light = 12, int dark = 14}) {
    final baseAlpha = isDark(context) ? dark : light;
    final scaled = (baseAlpha * glassDeviceScale(context)).round();
    return scaled.clamp(8, 18);
  }

  /// Standard glass shadow for the current theme.
  static List<BoxShadow> glassShadow(BuildContext context) => isDark(context)
      ? [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ]
      : [
          BoxShadow(
            color: primaryColor.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ];

  // ── Status Helpers ──
  static Color statusColor(String status) {
    switch (status) {
      case 'Approved':
        return successColor;
      case 'Pending':
        return warningColor;
      case 'Canceled':
        return dangerColor;
      case 'Lunas':
        return infoColor;
      default:
        return textTertiary;
    }
  }

  static Color statusBgColor(String status) {
    switch (status) {
      case 'Approved':
        return successLight;
      case 'Pending':
        return warningLight;
      case 'Canceled':
        return dangerLight;
      case 'Lunas':
        return infoLight;
      default:
        return bgSecondary;
    }
  }
}
