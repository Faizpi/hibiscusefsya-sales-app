import 'dart:convert';

class PenjualanModel {
  final int id;
  final String? nomor;
  final String? uuid;
  final String? pelanggan;
  final String? email;
  final String? alamatPenagihan;
  final String? tglTransaksi;
  final String? tglJatuhTempo;
  final String? syaratPembayaran;
  final String? noReferensi;
  final String? tag;
  final String? koordinat;
  final String? memo;
  final String status;
  final num? diskonAkhir;
  final num? taxPercentage;
  final num? grandTotal;
  final int? userId;
  final int? approverId;
  final int? gudangId;
  final String? tipeHarga;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? gudang;
  final Map<String, dynamic>? approver;
  final List<PenjualanItemModel>? items;
  final List<String>? lampiranPaths;

  PenjualanModel({
    required this.id,
    this.nomor,
    this.uuid,
    this.pelanggan,
    this.email,
    this.alamatPenagihan,
    this.tglTransaksi,
    this.tglJatuhTempo,
    this.syaratPembayaran,
    this.noReferensi,
    this.tag,
    this.koordinat,
    this.memo,
    required this.status,
    this.diskonAkhir,
    this.taxPercentage,
    this.grandTotal,
    this.userId,
    this.approverId,
    this.gudangId,
    this.tipeHarga,
    this.user,
    this.gudang,
    this.approver,
    this.items,
    this.lampiranPaths,
  });

  factory PenjualanModel.fromJson(Map<String, dynamic> json) {
    List<PenjualanItemModel>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((e) => PenjualanItemModel.fromJson(e))
          .toList();
    }

    return PenjualanModel(
      id: _parseInt(json['id']) ?? 0,
      nomor: json['nomor'],
      uuid: json['uuid'],
      pelanggan: json['pelanggan'],
      email: json['email'],
      alamatPenagihan: json['alamat_penagihan'],
      tglTransaksi: json['tgl_transaksi'],
      tglJatuhTempo: json['tgl_jatuh_tempo'],
      syaratPembayaran: json['syarat_pembayaran'],
      noReferensi: json['no_referensi'],
      tag: json['tag'],
      koordinat: json['koordinat'],
      memo: json['memo'],
      status: json['status'] ?? 'Pending',
      diskonAkhir: _parseNum(json['diskon_akhir']),
      taxPercentage: _parseNum(json['tax_percentage']),
      grandTotal: _parseNum(json['grand_total']),
      userId: _parseInt(json['user_id']),
      approverId: _parseInt(json['approver_id']),
      gudangId: _parseInt(json['gudang_id']),
      tipeHarga: json['tipe_harga'],
      user: json['user'],
      gudang: json['gudang'],
      approver: json['approver'],
      items: items,
      lampiranPaths: _parseLampiranPaths(json['lampiran_paths']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    return null;
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
  String get gudangName => gudang?['nama_gudang'] ?? '-';
}

class PenjualanItemModel {
  final int id;
  final int penjualanId;
  final int produkId;
  final String namaProduk;
  final num kuantitas;
  final String? satuan;
  final num hargaSatuan;
  final num diskon;
  final num total;
  final String? deskripsi;
  final String? unit;
  final String? batchNumber;
  final String? expiredDate;
  final Map<String, dynamic>? produk;

  PenjualanItemModel({
    required this.id,
    required this.penjualanId,
    required this.produkId,
    required this.namaProduk,
    required this.kuantitas,
    this.satuan,
    required this.hargaSatuan,
    required this.diskon,
    required this.total,
    this.deskripsi,
    this.unit,
    this.batchNumber,
    this.expiredDate,
    this.produk,
  });

  factory PenjualanItemModel.fromJson(Map<String, dynamic> json) {
    final qty = _parseNum(json['kuantitas']);
    final harga = _parseNum(json['harga_satuan']);
    final disk = _parseNum(json['diskon']);
    num parsedTotal = _parseNum(json['total']) != 0
        ? _parseNum(json['total'])
        : (_parseNum(json['sub_total']) != 0
            ? _parseNum(json['sub_total'])
            : (_parseNum(json['subtotal']) != 0
                ? _parseNum(json['subtotal'])
                : 0));
    // Calculate if still 0
    if (parsedTotal == 0 && harga > 0 && qty > 0) {
      parsedTotal = qty * harga * (1 - disk / 100);
    }

    return PenjualanItemModel(
      id: _parseInt(json['id']) ?? 0,
      penjualanId: _parseInt(json['penjualan_id']) ?? 0,
      produkId: _parseInt(json['produk_id']) ?? 0,
      namaProduk: json['nama_produk'] ?? json['produk']?['nama_produk'] ?? '',
      kuantitas: qty,
      satuan: json['satuan'] ?? json['unit'],
      hargaSatuan: harga,
      diskon: disk,
      total: parsedTotal,
      deskripsi: json['deskripsi'],
      unit: json['unit'] ?? json['satuan'],
      batchNumber: json['batch_number'],
      expiredDate: json['expired_date'],
      produk: json['produk'],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    return null;
  }

  static num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}
