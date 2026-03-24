class GudangModel {
  final int id;
  final String namaGudang;
  final String? alamatGudang;

  GudangModel({
    required this.id,
    required this.namaGudang,
    this.alamatGudang,
  });

  factory GudangModel.fromJson(Map<String, dynamic> json) {
    return GudangModel(
      id: _parseInt(json['id']),
      namaGudang: (json['nama_gudang'] ?? json['nama'] ?? json['name'] ?? '')
          .toString(),
      alamatGudang: json['alamat_gudang'],
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ProdukModel {
  final int id;
  final String namaProduk;
  final String? itemCode;
  final num? harga;
  final num? hargaGrosir;
  final String? satuan;
  final String? deskripsi;

  ProdukModel({
    required this.id,
    required this.namaProduk,
    this.itemCode,
    this.harga,
    this.hargaGrosir,
    this.satuan,
    this.deskripsi,
  });

  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    return ProdukModel(
      id: _parseInt(json['id']),
      namaProduk: json['nama_produk'] ?? '',
      itemCode: json['item_code'],
      harga: _parseNum(json['harga']),
      hargaGrosir: _parseNum(json['harga_grosir']),
      satuan: json['satuan'],
      deskripsi: json['deskripsi'],
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}

class StokModel {
  final int gudangId;
  final int produkId;
  final int stok;
  final int stokPenjualan;
  final int stokGratis;
  final int stokSample;
  final ProdukModel? produk;
  final GudangModel? gudang;

  StokModel({
    required this.gudangId,
    required this.produkId,
    required this.stok,
    this.stokPenjualan = 0,
    this.stokGratis = 0,
    this.stokSample = 0,
    this.produk,
    this.gudang,
  });

  factory StokModel.fromJson(Map<String, dynamic> json) {
    final nestedProduk = json['produk'] is Map<String, dynamic>
        ? json['produk'] as Map<String, dynamic>
        : null;
    final nestedGudang = json['gudang'] is Map<String, dynamic>
        ? json['gudang'] as Map<String, dynamic>
        : null;

    final stokPenjualan = _parseInt(json['stok_penjualan']);
    final stokGratis = _parseInt(json['stok_gratis']);
    final stokSample = _parseInt(json['stok_sample']);
    final hasComponentStok = json.containsKey('stok_penjualan') ||
        json.containsKey('stok_gratis') ||
        json.containsKey('stok_sample');

    return StokModel(
      gudangId: _parseInt(json['gudang_id'] ?? nestedGudang?['id']),
      produkId: _parseInt(json['produk_id'] ?? nestedProduk?['id']),
      stok: hasComponentStok
          ? stokPenjualan + stokGratis + stokSample
          : _parseInt(json['stok']),
      stokPenjualan: stokPenjualan,
      stokGratis: stokGratis,
      stokSample: stokSample,
      produk: nestedProduk != null ? ProdukModel.fromJson(nestedProduk) : null,
      gudang: nestedGudang != null ? GudangModel.fromJson(nestedGudang) : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
