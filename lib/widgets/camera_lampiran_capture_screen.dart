import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../utils/location_helper.dart';

class CameraLampiranResult {
  final String imagePath;
  final DateTime capturedAt;
  final String placeLabel;
  final String coordinateLabel;

  const CameraLampiranResult({
    required this.imagePath,
    required this.capturedAt,
    required this.placeLabel,
    required this.coordinateLabel,
  });
}

class CameraLampiranCaptureScreen extends StatefulWidget {
  const CameraLampiranCaptureScreen({super.key});

  @override
  State<CameraLampiranCaptureScreen> createState() =>
      _CameraLampiranCaptureScreenState();
}

class _CameraLampiranCaptureScreenState
    extends State<CameraLampiranCaptureScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String _placeLabel = 'Lokasi tidak tersedia';
  String _coordinateLabel = 'Koordinat tidak tersedia';
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await Future.wait([
        _initializeCamera(),
        _initializeLocationInfo(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('Kamera tidak tersedia pada perangkat ini.');
    }

    CameraDescription selected = cameras.first;
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        selected = camera;
        break;
      }
    }

    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
    });
  }

  Future<void> _initializeLocationInfo() async {
    final position = await LocationHelper.getCurrentPosition();
    if (position == null) return;

    var place = 'Lokasi tidak tersedia';
    final coordinate =
        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        place = _composePlaceName(placemarks.first);
      }
    } catch (_) {
      // Keep fallback place label when reverse geocoding fails.
    }

    if (!mounted) return;
    setState(() {
      _placeLabel = place;
      _coordinateLabel = coordinate;
    });
  }

  String _composePlaceName(Placemark placemark) {
    final parts = <String>[
      placemark.name ?? '',
      placemark.subLocality ?? '',
      placemark.locality ?? '',
      placemark.subAdministrativeArea ?? '',
      placemark.administrativeArea ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'Lokasi tidak tersedia';
    return parts.toSet().join(', ');
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

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() => _isCapturing = true);
      final capturedAt = DateTime.now();
      final xFile = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(
        CameraLampiranResult(
          imagePath: xFile.path,
          capturedAt: capturedAt,
          placeLabel: _placeLabel,
          coordinateLabel: _coordinateLabel,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  TextStyle _overlayTextStyle() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      shadows: [
        Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 3),
      ],
    );
  }

  Widget _overlayInfoRow(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: _overlayTextStyle(),
      ),
    );
  }

  Widget _buildPreview(CameraController controller) {
    final size = controller.value.previewSize;
    if (size == null) return CameraPreview(controller);

    // Camera previewSize is landscape-based, so invert for portrait UI.
    final aspectRatio = size.height / size.width;
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : controller == null || !controller.value.isInitialized
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: Colors.white70, size: 42),
                        const SizedBox(height: 8),
                        const Text(
                          'Kamera tidak dapat dibuka',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(child: _buildPreview(controller)),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.18),
                                Colors.black.withValues(alpha: 0.90),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _overlayInfoRow(
                                  'Waktu: ${_formatDateTimeId(_now)}'),
                              const SizedBox(height: 4),
                              _overlayInfoRow('Tempat: $_placeLabel'),
                              const SizedBox(height: 4),
                              _overlayInfoRow('Koordinat: $_coordinateLabel'),
                              const SizedBox(height: 16),
                              Center(
                                child: InkWell(
                                  onTap: _isCapturing ? null : _capture,
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      color: _isCapturing
                                          ? Colors.white54
                                          : Colors.white,
                                    ),
                                    child: _isCapturing
                                        ? const Padding(
                                            padding: EdgeInsets.all(20),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.black,
                                            size: 34,
                                          ),
                                  ),
                                ),
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
}
