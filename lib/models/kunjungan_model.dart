import 'produk_model.dart';

class KunjunganModel {
  final int id;
  final String? nomor;
  final String? uuid;
  final int? userId;
  final int? approverId;
  final int? gudangId;
  final int? kontakId;
  final String? salesNama;
  final String? salesEmail;
  final String? salesAlamat;
  final String? tglKunjungan;
  final String? tujuan;
  final String? koordinat;
  final String? memo;
  final String status;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? approver;
  final Map<String, dynamic>? gudang;
  final Map<String, dynamic>? kontak;
  final List<KunjunganItemModel>? items;
  final List<String>? lampiranPaths;

  KunjunganModel({
    required this.id,
    this.nomor,
    this.uuid,
    this.userId,
    this.approverId,
    this.gudangId,
    this.kontakId,
    this.salesNama,
    this.salesEmail,
    this.salesAlamat,
    this.tglKunjungan,
    this.tujuan,
    this.koordinat,
    this.memo,
    required this.status,
    this.user,
    this.approver,
    this.gudang,
    this.kontak,
    this.items,
    this.lampiranPaths,
  });

  factory KunjunganModel.fromJson(Map<String, dynamic> json) {
    List<KunjunganItemModel>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((e) => KunjunganItemModel.fromJson(e))
          .toList();
    }
    return KunjunganModel(
      id: json['id'],
      nomor: json['nomor'],
      uuid: json['uuid'],
      userId: json['user_id'],
      approverId: json['approver_id'],
      gudangId: json['gudang_id'],
      kontakId: json['kontak_id'],
      salesNama: json['sales_nama'],
      salesEmail: json['sales_email'],
      salesAlamat: json['sales_alamat'],
      tglKunjungan: json['tgl_kunjungan'],
      tujuan: json['tujuan'],
      koordinat: json['koordinat'],
      memo: json['memo'],
      status: json['status'] ?? 'Pending',
      user: json['user'],
      approver: json['approver'],
      gudang: json['gudang'],
      kontak: json['kontak'],
      items: items,
      lampiranPaths: json['lampiran_paths'] != null
          ? List<String>.from(json['lampiran_paths'])
          : null,
    );
  }

  String get userName => user?['name'] ?? '-';
  String get kontakNama => kontak?['nama'] ?? '-';
  String get gudangName => gudang?['nama_gudang'] ?? '-';
  String get publicUrl =>
      'https://sales.hibiscusefsya.com/public/invoice/kunjungan/$uuid';
}

class KunjunganItemModel {
  final int? id;
  final int? kunjunganId;
  final int? produkId;
  final String? namaProduk;
  final int? kuantitas;
  final String? tipeStok;
  final String? keterangan;
  final ProdukModel? produk;

  KunjunganItemModel({
    this.id,
    this.kunjunganId,
    this.produkId,
    this.namaProduk,
    this.kuantitas,
    this.tipeStok,
    this.keterangan,
    this.produk,
  });

  factory KunjunganItemModel.fromJson(Map<String, dynamic> json) {
    return KunjunganItemModel(
      id: json['id'],
      kunjunganId: json['kunjungan_id'],
      produkId: json['produk_id'],
      namaProduk: json['nama_produk'],
      kuantitas: json['kuantitas'],
      tipeStok: json['tipe_stok'],
      keterangan: json['keterangan'],
      produk:
          json['produk'] != null ? ProdukModel.fromJson(json['produk']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'produk_id': produkId,
        'kuantitas': kuantitas,
        'tipe_stok': tipeStok,
        'keterangan': keterangan,
      };
}
