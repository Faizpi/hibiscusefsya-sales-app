import 'dart:convert';

class PembelianModel {
  final int id;
  final String? nomor;
  final String? uuid;
  final String? tglTransaksi;
  final String? tglJatuhTempo;
  final String? syaratPembayaran;
  final String? urgensi;
  final String? tahunAnggaran;
  final String? stafPenyetuju;
  final String? emailPenyetuju;
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
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? gudang;
  final Map<String, dynamic>? approver;
  final List<PembelianItemModel>? items;
  final List<String>? lampiranPaths;

  PembelianModel({
    required this.id,
    this.nomor,
    this.uuid,
    this.tglTransaksi,
    this.tglJatuhTempo,
    this.syaratPembayaran,
    this.urgensi,
    this.tahunAnggaran,
    this.stafPenyetuju,
    this.emailPenyetuju,
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
    this.user,
    this.gudang,
    this.approver,
    this.items,
    this.lampiranPaths,
  });

  factory PembelianModel.fromJson(Map<String, dynamic> json) {
    List<PembelianItemModel>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((e) => PembelianItemModel.fromJson(e))
          .toList();
    }
    return PembelianModel(
      id: _parseInt(json['id']) ?? 0,
      nomor: json['nomor'],
      uuid: json['uuid'],
      tglTransaksi: json['tgl_transaksi'],
      tglJatuhTempo: json['tgl_jatuh_tempo'],
      syaratPembayaran: json['syarat_pembayaran'],
      urgensi: json['urgensi'],
      tahunAnggaran: json['tahun_anggaran'],
      stafPenyetuju: json['staf_penyetuju'],
      emailPenyetuju: json['email_penyetuju'],
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
  String get publicUrl =>
      'https://sales.hibiscusefsya.com/public/invoice/pembelian/$uuid';
}

class PembelianItemModel {
  final int? id;
  final int? pembelianId;
  final int? produkId;
  final String? namaProduk;
  final num? kuantitas;
  final String? satuan;
  final num? hargaSatuan;
  final num? diskon;
  final num? total;
  final String? deskripsi;
  final String? unit;
  final String? batchNumber;
  final String? expiredDate;
  final Map<String, dynamic>? produk;

  PembelianItemModel({
    this.id,
    this.pembelianId,
    this.produkId,
    this.namaProduk,
    this.kuantitas,
    this.satuan,
    this.hargaSatuan,
    this.diskon,
    this.total,
    this.deskripsi,
    this.unit,
    this.batchNumber,
    this.expiredDate,
    this.produk,
  });

  factory PembelianItemModel.fromJson(Map<String, dynamic> json) {
    final qty = _parseNum(json['kuantitas']);
    final harga = _parseNum(json['harga_satuan']);
    final disk = _parseNum(json['diskon']);
    num? parsedTotal = _parseNum(json['total']) ??
        _parseNum(json['sub_total']) ??
        _parseNum(json['subtotal']);
    // Calculate if still 0 or null
    if ((parsedTotal == null || parsedTotal == 0) &&
        (harga ?? 0) > 0 &&
        (qty ?? 0) > 0) {
      parsedTotal = (qty ?? 0) * (harga ?? 0) * (1 - (disk ?? 0) / 100);
    }

    return PembelianItemModel(
      id: _parseInt(json['id']),
      pembelianId: _parseInt(json['pembelian_id']),
      produkId: _parseInt(json['produk_id']),
      namaProduk: json['nama_produk'] ?? json['produk']?['nama_produk'],
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

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'produk_id': produkId,
        'kuantitas': kuantitas,
        'harga_satuan': hargaSatuan,
        'diskon': diskon,
      };
}
