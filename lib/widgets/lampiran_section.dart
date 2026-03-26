import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Displays a list of attachment file paths with icons.
/// Shows image thumbnails for image files and file icons for others.
class LampiranSection extends StatelessWidget {
  final List<String> paths;
  final String baseUrl;

  const LampiranSection({
    super.key,
    required this.paths,
    this.baseUrl = 'https://sales.hibiscusefsya.com',
  });

  static const _imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return _imageExts.any((ext) => lower.endsWith(ext));
  }

  String _fileName(String path) {
    return path.split('/').last;
  }

  IconData _fileIcon(String path) {
    final lower = path.toLowerCase();
    if (_isImage(lower)) return Icons.image_rounded;
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    if (lower.endsWith('.zip')) return Icons.folder_zip_rounded;
    return Icons.attach_file_rounded;
  }

  String _publicStorageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalized = path.replaceAll('\\', '/');
    final encoded = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return '$baseUrl/storage/$encoded';
  }

  void _openImagePreview(BuildContext context, String imageUrl, String name) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.7,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Gagal memuat gambar lampiran.'),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
                child: IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();

    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Lampiran',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...paths.map((path) {
          final name = _fileName(path);
          final icon = _fileIcon(path);
          final isImg = _isImage(path);
          final imageUrl = _publicStorageUrl(path);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColorOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isImg)
                  GestureDetector(
                    onTap: () => _openImagePreview(context, imageUrl, name),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: isDark
                              ? Colors.white.withAlpha(8)
                              : AppTheme.bgSecondary,
                          child: Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: AppTheme.textTertiaryColor(context),
                                size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : AppTheme.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
