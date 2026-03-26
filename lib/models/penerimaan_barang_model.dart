import 'dart:convert';

import 'produk_model.dart';

class PenerimaanBarangModel {
  final int id;
  final String? nomor;
  final String? uuid;
  final int? userId;
  final int? approverId;
  final int? gudangId;
  final int? pembelianId;
  final String? tglPenerimaan;
  final String? noSuratJalan;
  final String? keterangan;
  final String status;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? approver;
  final Map<String, dynamic>? gudang;
  final Map<String, dynamic>? pembelian;
  final List<PenerimaanBarangItemModel>? items;
  final List<String>? lampiranPaths;

  PenerimaanBarangModel({
    required this.id,
    this.nomor,
    this.uuid,
    this.userId,
    this.approverId,
    this.gudangId,
    this.pembelianId,
    this.tglPenerimaan,
    this.noSuratJalan,
    this.keterangan,
    required this.status,
    this.user,
    this.approver,
    this.gudang,
    this.pembelian,
    this.items,
    this.lampiranPaths,
  });

  factory PenerimaanBarangModel.fromJson(Map<String, dynamic> json) {
    List<PenerimaanBarangItemModel>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((e) => PenerimaanBarangItemModel.fromJson(e))
          .toList();
    }
    return PenerimaanBarangModel(
      id: json['id'],
      nomor: json['nomor'],
      uuid: json['uuid'],
      userId: json['user_id'],
      approverId: json['approver_id'],
      gudangId: json['gudang_id'],
      pembelianId: json['pembelian_id'],
      tglPenerimaan: json['tgl_penerimaan'],
      noSuratJalan: json['no_surat_jalan'],
      keterangan: json['keterangan'],
      status: json['status'] ?? 'Pending',
      user: json['user'],
      approver: json['approver'],
      gudang: json['gudang'],
      pembelian: json['pembelian'],
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

  String get userName => user?['name'] ?? '-';
  String get gudangName => gudang?['nama_gudang'] ?? '-';
  String get pembelianNomor => pembelian?['nomor'] ?? '-';
  String get publicUrl =>
      'https://sales.hibiscusefsya.com/public/invoice/penerimaan-barang/$uuid';
}

class PenerimaanBarangItemModel {
  final int? id;
  final int? penerimaanBarangId;
  final int? produkId;
  final String? namaProduk;
  final int? qtyDiterima;
  final int? qtyReject;
  final String? tipeStok;
  final String? batchNumber;
  final String? expiredDate;
  final String? keterangan;
  final ProdukModel? produk;

  PenerimaanBarangItemModel({
    this.id,
    this.penerimaanBarangId,
    this.produkId,
    this.namaProduk,
    this.qtyDiterima,
    this.qtyReject,
    this.tipeStok,
    this.batchNumber,
    this.expiredDate,
    this.keterangan,
    this.produk,
  });

  factory PenerimaanBarangItemModel.fromJson(Map<String, dynamic> json) {
    return PenerimaanBarangItemModel(
      id: json['id'],
      penerimaanBarangId: json['penerimaan_barang_id'],
      produkId: json['produk_id'],
      namaProduk: json['nama_produk'],
      qtyDiterima: json['qty_diterima'],
      qtyReject: json['qty_reject'],
      tipeStok: json['tipe_stok'],
      batchNumber: json['batch_number'],
      expiredDate: json['expired_date'],
      keterangan: json['keterangan'],
      produk:
          json['produk'] != null ? ProdukModel.fromJson(json['produk']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'produk_id': produkId,
        'qty_diterima': qtyDiterima,
        'qty_reject': qtyReject,
        'tipe_stok': tipeStok,
        'batch_number': batchNumber,
        'expired_date': expiredDate,
        'keterangan': keterangan,
      };
}
