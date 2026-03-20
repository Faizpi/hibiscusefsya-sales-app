import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';

class KoordinatLokasiField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool autoFetchOnInit;

  const KoordinatLokasiField({
    super.key,
    required this.controller,
    this.label = 'Koordinat Lokasi',
    this.autoFetchOnInit = true,
  });

  @override
  State<KoordinatLokasiField> createState() => _KoordinatLokasiFieldState();
}

class _KoordinatLokasiFieldState extends State<KoordinatLokasiField> {
  bool _isLoading = false;
  bool _didAutoFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.autoFetchOnInit) return;
      if (widget.controller.text.trim().isNotEmpty) return;
      _didAutoFetch = true;
      _getLocation();
    });
  }

  @override
  void didUpdateWidget(covariant KoordinatLokasiField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;
    if (!widget.autoFetchOnInit) return;
    if (_didAutoFetch) return;
    if (widget.controller.text.trim().isNotEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAutoFetch) return;
      _didAutoFetch = true;
      _getLocation();
    });
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan lokasi tidak aktif')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Izin lokasi ditolak secara permanen')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      widget.controller.text = '${position.latitude}, ${position.longitude}';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'Otomatis terisi saat halaman dibuat',
        hintStyle: TextStyle(
          fontSize: 12,
          color: AppTheme.textTertiaryColor(context),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.my_location,
                    color: AppTheme.primaryColor, size: 20),
                onPressed: _getLocation,
                tooltip: 'Dapatkan lokasi saat ini',
              ),
            IconButton(
              icon: Icon(Icons.open_in_new,
                  color: AppTheme.textTertiaryColor(context), size: 20),
              onPressed: widget.controller.text.isNotEmpty
                  ? () {
                      // Could open maps in the future
                    }
                  : null,
              tooltip: 'Buka di peta',
            ),
          ],
        ),
      ),
    );
  }
}
