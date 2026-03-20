class PembayaranModel {
  final int id;
  final String? nomor;
  final String? uuid;
  final int? userId;
  final int? approverId;
  final int? gudangId;
  final int? penjualanId;
  final String? tglPembayaran;
  final String? metodePembayaran;
  final num? jumlahBayar;
  final String? buktiBayar;
  final String? keterangan;
  final String status;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? approver;
  final Map<String, dynamic>? penjualan;
  final List<String>? lampiranPaths;

  PembayaranModel({
    required this.id,
    this.nomor,
    this.uuid,
    this.userId,
    this.approverId,
    this.gudangId,
    this.penjualanId,
    this.tglPembayaran,
    this.metodePembayaran,
    this.jumlahBayar,
    this.buktiBayar,
    this.keterangan,
    required this.status,
    this.user,
    this.approver,
    this.penjualan,
    this.lampiranPaths,
  });

  factory PembayaranModel.fromJson(Map<String, dynamic> json) {
    return PembayaranModel(
      id: json['id'],
      nomor: json['nomor'],
      uuid: json['uuid'],
      userId: json['user_id'],
      approverId: json['approver_id'],
      gudangId: json['gudang_id'],
      penjualanId: json['penjualan_id'],
      tglPembayaran: json['tgl_pembayaran'],
      metodePembayaran: json['metode_pembayaran'],
      jumlahBayar: _parseNum(json['jumlah_bayar']),
      buktiBayar: json['bukti_bayar'],
      keterangan: json['keterangan'],
      status: json['status'] ?? 'Pending',
      user: json['user'],
      approver: json['approver'],
      penjualan: json['penjualan'],
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
  String get penjualanNomor => penjualan?['nomor'] ?? '-';
  String get publicUrl =>
      'https://sales.hibiscusefsya.com/public/invoice/pembayaran/$uuid';
}
