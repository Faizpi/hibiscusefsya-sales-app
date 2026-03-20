import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Glassmorphism variant — controls blur intensity and visual weight.
enum GlassVariant {
  /// Hero cards, stat cards, small count (1-4 on screen). Full BackdropFilter.
  card,

  /// List items in scrollable lists (10+). Faux glass — no BackdropFilter.
  list,

  /// Modal sheets, dialogs. Heavy blur for depth separation.
  modal,

  /// Bottom nav, app bars. Medium blur with stronger border.
  navbar,
}

/// A glassmorphism container widget with backdrop blur effect.
/// Supports both light and dark themes automatically.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blurSigma;
  final Color? overrideColor;
  final Border? overrideBorder;
  final List<BoxShadow>? overrideShadow;
  final VoidCallback? onTap;
  final GlassVariant variant;
  final bool _useFaux;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blurSigma = 12,
    this.overrideColor,
    this.overrideBorder,
    this.overrideShadow,
    this.onTap,
    this.variant = GlassVariant.card,
  }) : _useFaux = false;

  /// Faux glass — semi-transparent tint + border, NO BackdropFilter.
  /// Use for scrollable list items (10+) to avoid performance issues.
  const GlassContainer.faux({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.overrideColor,
    this.overrideBorder,
    this.overrideShadow,
    this.onTap,
  })  : blurSigma = 0,
        variant = GlassVariant.list,
        _useFaux = true;

  /// Resolved blur sigma accounting for variant, theme, and screen size.
  double _resolvedSigma(BuildContext context, bool isDark) {
    if (_useFaux) return 0;

    double base;
    switch (variant) {
      case GlassVariant.card:
        base = blurSigma; // default 12
        break;
      case GlassVariant.modal:
        base = blurSigma * 1.5; // heavier blur for modals
        break;
      case GlassVariant.navbar:
        base = blurSigma * 1.2; // medium blur for nav
        break;
      case GlassVariant.list:
        return 0; // list items skip blur entirely
    }

    return AppTheme.glassBlur(
      context,
      base: base,
      darkBoost: 1.35,
      min: variant == GlassVariant.modal ? 10 : 6,
      max: variant == GlassVariant.modal ? 26 : 22,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final sigma = _resolvedSigma(context, isDark);

    // Glass tint color
    final glassColor = overrideColor ??
        (isDark
            ? const Color(0xFF1E293B).withAlpha(_useFaux ? 176 : 146)
            : Colors.white.withAlpha(_useFaux ? 214 : 182));

    // Border — slightly more visible in dark mode for glass definition
    final glassBorder = overrideBorder ??
        Border.all(
          color: isDark
              ? Colors.white.withAlpha(_useFaux ? 18 : 34)
              : Colors.white.withAlpha(_useFaux ? 132 : 175),
        );

    // Shadow
    final glassShadow = overrideShadow ??
        [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(_useFaux ? 30 : 48)
                : AppTheme.primaryColor.withAlpha(_useFaux ? 8 : 16),
            blurRadius: _useFaux ? 10 : 20,
            offset: const Offset(0, 6),
          ),
          if (!_useFaux)
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(18)
                  : Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          if (!_useFaux)
            BoxShadow(
              color: isDark
                  ? AppTheme.pinkAccent.withAlpha(8)
                  : AppTheme.pinkAccent.withAlpha(10),
              blurRadius: 18,
              offset: const Offset(0, 0),
            ),
        ];

    // Gradient overlay for glass depth
    final glassGradient = isDark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withAlpha(_useFaux ? 7 : 12),
              Colors.white.withAlpha(_useFaux ? 3 : 5),
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withAlpha(_useFaux ? 170 : 210),
              Colors.white.withAlpha(_useFaux ? 110 : 145),
            ],
          );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    // Faux glass: no BackdropFilter, just styled container
    if (_useFaux || variant == GlassVariant.list) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: glassBorder,
          gradient: glassGradient,
          boxShadow: glassShadow,
        ),
        child: content,
      );
    }

    // Real glass: BackdropFilter with blur
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: glassBorder,
              gradient: glassGradient,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A convenience widget for list items with faux-glass styling.
/// Optimized for scrollable lists — no BackdropFilter for performance.
class GlassListItem extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassListItem({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer.faux(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// A scaffold wrapper that provides a gradient background for glassmorphism.
/// Use this instead of plain Scaffold to enable glass blur effects.
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.bgColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // Background gradient & decorative elements
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF131B2E),
                          Color(0xFF0F172A),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF0F5FF),
                          Color(0xFFF8FAFC),
                          Color(0xFFFCE7F3),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
              ),
            ),
          ),
          // Decorative blurred circle - top right
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppTheme.primaryColor.withAlpha(20),
                          Colors.transparent,
                        ]
                      : [
                          AppTheme.primaryColor.withAlpha(25),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
          // Decorative blurred circle - bottom left
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppTheme.accentColor.withAlpha(12),
                          Colors.transparent,
                        ]
                      : [
                          AppTheme.pinkAccent.withAlpha(15),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
          // Main content
          body,
        ],
      ),
    );
  }
}

/// Global app shell that paints a decorative background and blur layer.
/// Wrap MaterialApp child with this so every page gets a glass atmosphere.
class GlobalGlassBackground extends StatelessWidget {
  final Widget child;

  const GlobalGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B1222),
                        Color(0xFF111A2F),
                        Color(0xFF0E1528),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEAF2FF),
                        Color(0xFFF8FAFC),
                        Color(0xFFFDEDF6),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppTheme.primaryColor.withAlpha(36),
                        Colors.transparent,
                      ]
                    : [
                        AppTheme.primaryColor.withAlpha(44),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -70,
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppTheme.accentColor.withAlpha(22),
                        Colors.transparent,
                      ]
                    : [
                        AppTheme.pinkAccent.withAlpha(26),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppTheme.glassBlur(
                  context,
                  base: 14,
                  darkBoost: 1.28,
                  min: 8,
                  max: 20,
                ),
                sigmaY: AppTheme.glassBlur(
                  context,
                  base: 14,
                  darkBoost: 1.28,
                  min: 8,
                  max: 20,
                ),
              ),
              child: Container(
                color: isDark
                    ? Colors.black
                        .withAlpha(AppTheme.glassOverlayAlpha(context))
                    : Colors.white
                        .withAlpha(AppTheme.glassOverlayAlpha(context)),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
