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
      id: json['id'],
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
      userId: json['user_id'],
      gudangId: json['gudang_id'],
      user: json['user'],
      gudang: json['gudang'],
      approver: json['approver'],
      items: items,
      lampiranPaths: json['lampiran_paths'] != null
          ? List<String>.from(json['lampiran_paths'])
          : null,
    );
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
      id: json['id'],
      pembelianId: json['pembelian_id'],
      produkId: json['produk_id'],
      namaProduk: json['nama_produk'] ?? json['produk']?['nama_produk'],
      kuantitas: qty,
      satuan: json['satuan'] ?? json['unit'],
      hargaSatuan: harga,
      diskon: disk,
      total: parsedTotal,
      produk: json['produk'],
    );
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
