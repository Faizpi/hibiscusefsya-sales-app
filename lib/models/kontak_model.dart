class KontakModel {
  final int id;
  final String? kodeKontak;
  final String nama;
  final String? email;
  final String? noTelp;
  final String? pin;
  final String? alamat;
  final num? diskonPersen;
  final int? gudangId;

  KontakModel({
    required this.id,
    this.kodeKontak,
    required this.nama,
    this.email,
    this.noTelp,
    this.pin,
    this.alamat,
    this.diskonPersen,
    this.gudangId,
  });

  factory KontakModel.fromJson(Map<String, dynamic> json) {
    return KontakModel(
      id: json['id'],
      kodeKontak: json['kode_kontak'],
      nama: json['nama'] ?? '',
      email: json['email'],
      noTelp: json['no_telp'],
      pin: json['pin'],
      alamat: json['alamat'],
      diskonPersen: _parseNum(json['diskon_persen']),
      gudangId: json['gudang_id'],
    );
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'email': email,
        'no_telp': noTelp,
        'alamat': alamat,
        'diskon_persen': diskonPersen,
        'gudang_id': gudangId,
      };
}
