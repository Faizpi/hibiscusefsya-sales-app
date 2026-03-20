import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';

class PhotoPickerWidget extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final void Function(int index) onRemove;

  const PhotoPickerWidget({
    super.key,
    required this.photos,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Foto Lampiran',
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Kamera', style: TextStyle(fontSize: 12)),
              onPressed: onPickCamera,
            ),
            TextButton.icon(
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Galeri', style: TextStyle(fontSize: 12)),
              onPressed: onPickGallery,
            ),
          ],
        ),
        if (photos.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (ctx, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(photos[i],
                            width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => onRemove(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.dangerColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  static Future<File?> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (picked != null) return File(picked.path);
    } catch (_) {}
    return null;
  }
}
