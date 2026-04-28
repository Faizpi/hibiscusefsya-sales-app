import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'glass_container.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return GlassContainer(
      variant: GlassVariant.card,
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 35 : 25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondaryColor(context),
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor(context)),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCardRow extends StatelessWidget {
  final List<SummaryCard> cards;

  const SummaryCardRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: cards
            .map<Widget>((card) => Expanded(child: card))
            .expand((widget) sync* {
          yield widget;
          yield const SizedBox(width: 10);
        }).toList()
          ..removeLast(),
      ),
    );
  }
}
