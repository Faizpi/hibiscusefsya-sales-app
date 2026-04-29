import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_theme.dart';

/// A polished bottom sheet shown after a file is downloaded.
/// "Buka File" opens the file with the device's native app chooser.
/// "Bagikan File" shares via system share sheet (WA, Email, etc).
Future<void> showFileActionSheet(
  BuildContext context, {
  required File file,
  required String shareText,
  String? subtitle,
}) async {
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(80),
    isScrollControlled: true,
    builder: (ctx) {
      final isDark = AppTheme.isDark(ctx);
      final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
      final divider = isDark ? Colors.white.withAlpha(16) : const Color(0xFFE2E8F0);
      final textPrimary = AppTheme.textPrimaryColor(ctx);
      final textSecondary = AppTheme.textSecondaryColor(ctx);
      final fileName = file.path.split(Platform.pathSeparator).last;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 30),
                  blurRadius: 32,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(40)
                          : Colors.black.withAlpha(20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // File info header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(isDark ? 40 : 20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_rounded,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Divider(color: divider, height: 1),
                ),

                // Action: Buka File — uses open_filex for native "Open with" picker
                _ActionTile(
                  icon: Icons.open_in_new_rounded,
                  iconColor: AppTheme.primaryColor,
                  iconBg: AppTheme.primaryColor.withAlpha(isDark ? 35 : 18),
                  title: 'Buka File',
                  subtitle: 'Pilih aplikasi untuk membuka file',
                  onTap: () async {
                    Navigator.pop(ctx);
                    // open_filex 4.x ships its own FileProvider with this authority.
                    // We must specify it explicitly so Android can resolve the content:// URI.
                    const authority =
                        'com.hibiscusefsya.sales_hibiscus_mobile.open_filex.provider';
                    final result = await OpenFilex.open(
                      file.path,
                    );
                    if (result.type != ResultType.done) {
                      // Fallback: share sheet if no PDF viewer installed
                      await Share.shareXFiles(
                        [XFile(file.path)],
                        text: shareText,
                      );
                    }
                  },
                ),

                const SizedBox(height: 4),

                // Action: Bagikan File — share sheet (WA, Drive, Email, etc)
                _ActionTile(
                  icon: Icons.ios_share_rounded,
                  iconColor: AppTheme.successColor,
                  iconBg: AppTheme.successColor.withAlpha(isDark ? 35 : 18),
                  title: 'Bagikan File',
                  subtitle: 'Kirim via WhatsApp, Email, Drive, dll.',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: shareText,
                    );
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = AppTheme.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: iconColor.withAlpha(20),
          highlightColor: iconColor.withAlpha(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(10)
                    : Colors.black.withAlpha(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
