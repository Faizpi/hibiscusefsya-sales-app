import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import 'camera_lampiran_capture_screen.dart';

class LampiranPickerWidget extends StatefulWidget {
  final List<PlatformFile> files;
  final ValueChanged<List<PlatformFile>> onFilesChanged;
  final int maxFiles;
  final int maxSizeBytes;
  final bool serverManagedNames;
  final String? fileNamePrefix;
  final int existingFileCount;

  const LampiranPickerWidget({
    super.key,
    required this.files,
    required this.onFilesChanged,
    this.maxFiles = 5,
    this.maxSizeBytes = 2 * 1024 * 1024,
    this.serverManagedNames = true,
    this.fileNamePrefix,
    this.existingFileCount = 0,
  });

  @override
  State<LampiranPickerWidget> createState() => _LampiranPickerWidgetState();
}

class _LampiranPickerWidgetState extends State<LampiranPickerWidget> {
  bool _isProcessingPhoto = false;

  static const _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'pdf',
    'zip',
    'doc',
    'docx',
  ];

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = <PlatformFile>[...widget.files];
        for (final file in result.files) {
          if (file.size > widget.maxSizeBytes) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${file.name} melebihi batas ukuran ${widget.maxSizeBytes ~/ (1024 * 1024)}MB'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            continue;
          }
          if (newFiles.length >= widget.maxFiles) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Maksimal ${widget.maxFiles} file'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            break;
          }
          final prepared = await _preparePickedFile(file, newFiles.length + 1);
          if (prepared != null) {
            newFiles.add(prepared);
          }
        }
        widget.onFilesChanged(newFiles);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    final newFiles = <PlatformFile>[...widget.files];
    newFiles.removeAt(index);
    widget.onFilesChanged(newFiles);
  }

  String _sanitizeFileToken(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '-');
    final compact = normalized.replaceAll(RegExp(r'-+'), '-');
    final trimmed = compact.replaceAll(RegExp(r'^-+|-+$'), '');
    return trimmed.isEmpty ? 'DRAFT' : trimmed;
  }

  String _resolvedPrefix() {
    final prefix = widget.fileNamePrefix?.trim();
    if (prefix == null || prefix.isEmpty) return 'DRAFT';
    return _sanitizeFileToken(prefix);
  }

  int _nextSequence(int localIndex) => widget.existingFileCount + localIndex;

  Future<PlatformFile?> _preparePickedFile(
      PlatformFile picked, int index) async {
    if (widget.serverManagedNames) {
      return picked;
    }

    final sourcePath = picked.path;
    if (sourcePath == null || sourcePath.isEmpty) return picked;

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return picked;

    final extension = (picked.extension ?? _extensionFromName(picked.name))
        .toLowerCase()
        .replaceAll('.', '');
    final safeExt = extension.isEmpty ? 'dat' : extension;
    final newName = '${_resolvedPrefix()}-${_nextSequence(index)}.$safeExt';
    final tempDir = await getTemporaryDirectory();
    final newPath = '${tempDir.path}${Platform.pathSeparator}$newName';
    await sourceFile.copy(newPath);
    final copied = File(newPath);

    return PlatformFile(
      name: newName,
      path: newPath,
      size: await copied.length(),
    );
  }

  String _extensionFromName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= name.length - 1) return '';
    return name.substring(dotIndex + 1);
  }

  Future<void> _takePhoto(BuildContext context) async {
    if (widget.files.length >= widget.maxFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal ${widget.maxFiles} file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final captureResult =
          await Navigator.of(context).push<CameraLampiranResult>(
        MaterialPageRoute(
          builder: (_) => const CameraLampiranCaptureScreen(),
        ),
      );

      if (captureResult == null) return;

      setState(() => _isProcessingPhoto = true);
      final stampedPath = await _createStampedPhoto(
        captureResult.imagePath,
        capturedAt: captureResult.capturedAt,
        placeLabel: captureResult.placeLabel,
        coordinateLabel: captureResult.coordinateLabel,
        sequence: _nextSequence(widget.files.length + 1),
      );
      final file = File(stampedPath);
      final size = await file.length();

      if (size > widget.maxSizeBytes) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto melebihi batas ukuran ${widget.maxSizeBytes ~/ (1024 * 1024)}MB. Coba ambil ulang.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newFiles = <PlatformFile>[...widget.files];
      newFiles.add(
        PlatformFile(
          name: _fileNameFromPath(stampedPath),
          path: stampedPath,
          size: size,
        ),
      );
      widget.onFilesChanged(newFiles);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingPhoto = false);
      }
    }
  }

  String _fileNameFromPath(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isNotEmpty ? parts.last : 'lampiran_foto.png';
  }

  Future<String> _createStampedPhoto(
    String sourcePath, {
    required DateTime capturedAt,
    required String placeLabel,
    required String coordinateLabel,
    required int sequence,
  }) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final original = frame.image;

    final lines = <String>[
      'Waktu: ${_formatDateTimeId(capturedAt)}',
      'Tempat: $placeLabel',
      'Koordinat: $coordinateLabel',
    ];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = original.width.toDouble();
    final height = original.height.toDouble();

    canvas.drawImage(original, Offset.zero, Paint());

    final baseFont = (width * 0.026).clamp(14.0, 24.0);
    final horizontalPadding = (width * 0.03).clamp(12.0, 26.0);
    final verticalPadding = (height * 0.02).clamp(10.0, 20.0);

    final linePainters = lines
        .map(
          (line) => TextPainter(
            text: TextSpan(
              text: line,
              style: TextStyle(
                color: Colors.white,
                fontSize: baseFont,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            maxLines: 2,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: width - (horizontalPadding * 2)),
        )
        .toList();

    final contentHeight = linePainters.fold<double>(
      0,
      (total, painter) => total + painter.height,
    );
    final panelHeight = contentHeight + (verticalPadding * 2);
    final panelTop = height - panelHeight;

    canvas.drawRect(
      Rect.fromLTWH(0, panelTop, width, panelHeight),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    var currentY = panelTop + verticalPadding;
    for (final painter in linePainters) {
      painter.paint(canvas, Offset(horizontalPadding, currentY));
      currentY += painter.height;
    }

    final picture = recorder.endRecording();
    final stampedImage = await picture.toImage(original.width, original.height);
    final byteData =
        await stampedImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Gagal memproses foto hasil kamera.');
    }

    final tempDir = await getTemporaryDirectory();
    final outputName = widget.serverManagedNames
        ? 'camera_${DateTime.now().microsecondsSinceEpoch}.png'
        : '${_resolvedPrefix()}-$sequence.png';
    final outputPath = '${tempDir.path}${Platform.pathSeparator}$outputName';
    await File(outputPath).writeAsBytes(byteData.buffer.asUint8List());
    return outputPath;
  }

  String _formatDateTimeId(DateTime dt) {
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final day = dayNames[dt.weekday - 1];
    final month = monthNames[dt.month - 1];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$day, ${dt.day} $month ${dt.year} $hh:$mm:$ss';
  }

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    if (lower.endsWith('.zip')) return Icons.folder_zip_rounded;
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif')) {
      return Icons.image_rounded;
    }
    return Icons.attach_file_rounded;
  }

  bool _isImageFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }

  Future<void> _previewFile(PlatformFile file) async {
    final path = file.path;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File tidak tersedia untuk dipreview.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isImageFile(file.name)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColorOf(context)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final fileUri = Uri.file(path);
    final opened =
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File tidak bisa dibuka di perangkat ini.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lampiran',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '(dapat memilih banyak file)',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.files.isNotEmpty) ...[
          ...widget.files.asMap().entries.map((entry) {
            final idx = entry.key;
            final file = entry.value;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _previewFile(file),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColorOf(context)),
                ),
                child: Row(
                  children: [
                    Icon(_fileIcon(file.name),
                        size: 20,
                        color: isDark
                            ? const Color(0xFF93C5FD)
                            : AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatSize(file.size),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Preview',
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      onPressed: () => _previewFile(file),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon:
                          const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () => _removeFile(idx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColorOf(context)),
                ),
                child: Text(
                  widget.files.isEmpty
                      ? 'Pilih file...'
                      : '${widget.files.length} file dipilih',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiaryColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isProcessingPhoto ? null : () => _pickFiles(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: const Text('Browse'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isProcessingPhoto ? null : () => _takePhoto(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: _isProcessingPhoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_rounded, size: 18),
              label: const Text('Foto'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Format: jpg, jpeg, png, pdf, zip, doc, docx (max 2MB per file)',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textTertiaryColor(context),
          ),
        ),
      ],
    );
  }
}
