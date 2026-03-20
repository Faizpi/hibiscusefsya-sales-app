import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_theme.dart';

class AppListSkeleton extends StatelessWidget {
  final int itemCount;

  const AppListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.isDark(context)
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(8);
    final highlight = AppTheme.isDark(context)
        ? Colors.white.withAlpha(32)
        : Colors.black.withAlpha(14);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class AppDetailSkeleton extends StatelessWidget {
  const AppDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.isDark(context)
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(8);
    final highlight = AppTheme.isDark(context)
        ? Colors.white.withAlpha(32)
        : Colors.black.withAlpha(14);

    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          block(96),
          const SizedBox(height: 12),
          block(140),
          const SizedBox(height: 12),
          block(140),
          const SizedBox(height: 12),
          block(96),
        ],
      ),
    );
  }
}

class AppFormSkeleton extends StatelessWidget {
  const AppFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.isDark(context)
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(8);
    final highlight = AppTheme.isDark(context)
        ? Colors.white.withAlpha(32)
        : Colors.black.withAlpha(14);

    Widget field() => Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          field(),
          const SizedBox(height: 12),
          field(),
          const SizedBox(height: 12),
          field(),
          const SizedBox(height: 12),
          field(),
          const SizedBox(height: 12),
          field(),
          const SizedBox(height: 20),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
