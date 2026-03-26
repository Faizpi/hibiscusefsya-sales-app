import 'dart:convert';

class BiayaModel {
  final int id;
  final String? nomor;
  final String? uuid;
  final int? userId;
  final int? approverId;
  final String? jenisBiaya;
  final String? bayarDari;
  final String? penerima;
  final String? alamatPenagihan;
  final String? tglTransaksi;
  final String? caraPembayaran;
  final String? tag;
  final String? koordinat;
  final String? memo;
  final String status;
  final num? taxPercentage;
  final num? grandTotal;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? approver;
  final List<BiayaItemModel>? items;
  final List<String>? lampiranPaths;

  BiayaModel({
    required this.id,
    this.nomor,
    this.uuid,
    this.userId,
    this.approverId,
    this.jenisBiaya,
    this.bayarDari,
    this.penerima,
    this.alamatPenagihan,
    this.tglTransaksi,
    this.caraPembayaran,
    this.tag,
    this.koordinat,
    this.memo,
    required this.status,
    this.taxPercentage,
    this.grandTotal,
    this.user,
    this.approver,
    this.items,
    this.lampiranPaths,
  });

  factory BiayaModel.fromJson(Map<String, dynamic> json) {
    List<BiayaItemModel>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((e) => BiayaItemModel.fromJson(e))
          .toList();
    }
    return BiayaModel(
      id: json['id'],
      nomor: json['nomor'],
      uuid: json['uuid'],
      userId: json['user_id'],
      approverId: json['approver_id'],
      jenisBiaya: json['jenis_biaya'],
      bayarDari: json['bayar_dari'],
      penerima: json['penerima'],
      alamatPenagihan: json['alamat_penagihan'],
      tglTransaksi: json['tgl_transaksi'],
      caraPembayaran: json['cara_pembayaran'],
      tag: json['tag'],
      koordinat: json['koordinat'],
      memo: json['memo'],
      status: json['status'] ?? 'Pending',
      taxPercentage: _parseNum(json['tax_percentage']),
      grandTotal: _parseNum(json['grand_total']),
      user: json['user'],
      approver: json['approver'],
      items: items,
      lampiranPaths: _parseLampiranPaths(json['lampiran_paths']),
    );
  }

  static List<String>? _parseLampiranPaths(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return null;
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Ignore malformed payload and fallback to empty list.
      }
      return const [];
    }
    return null;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  String get userName => user?['name'] ?? '-';
  String get publicUrl =>
      'https://sales.hibiscusefsya.com/public/invoice/biaya/$uuid';
}

class BiayaItemModel {
  final int? id;
  final int? biayaId;
  final String? kategori;
  final String? deskripsi;
  final num? jumlah;

  BiayaItemModel({
    this.id,
    this.biayaId,
    this.kategori,
    this.deskripsi,
    this.jumlah,
  });

  factory BiayaItemModel.fromJson(Map<String, dynamic> json) {
    return BiayaItemModel(
      id: json['id'],
      biayaId: json['biaya_id'],
      kategori: json['kategori'],
      deskripsi: json['deskripsi'],
      jumlah: _parseNum(json['jumlah']),
    );
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'kategori': kategori,
        'deskripsi': deskripsi,
        'jumlah': jumlah,
      };
}
