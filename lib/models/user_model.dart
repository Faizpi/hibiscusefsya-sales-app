class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final Map<String, bool> permissions;
  final String? alamat;
  final String? noTelp;
  final int? gudangId;
  final int? currentGudangId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.permissions = const {},
    this.alamat,
    this.noTelp,
    this.gudangId,
    this.currentGudangId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleValue = (json['role'] ?? 'user').toString().trim().toLowerCase();
    final normalizedRole = roleValue == 'sales' ? 'user' : roleValue;
    final permissionMap = <String, bool>{};
    final rawPermissions = json['permissions'];
    if (rawPermissions is Map) {
      rawPermissions.forEach((key, value) {
        permissionMap[key.toString()] = value == true;
      });
    }

    final nestedGudang = json['gudang'] is Map ? json['gudang'] as Map : null;

    return UserModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: normalizedRole,
      permissions: permissionMap,
      alamat: json['alamat'],
      noTelp: json['no_telp'],
      gudangId: _parseInt(json['gudang_id'] ?? nestedGudang?['id']),
      currentGudangId: _parseInt(json['current_gudang_id']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'permissions': permissions,
        'alamat': alamat,
        'no_telp': noTelp,
        'gudang_id': gudangId,
        'current_gudang_id': currentGudangId,
      };

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin';
  bool get isSpectator => role == 'spectator';
  bool get isUser => role == 'user';
  bool get canCreate => !isSpectator;

  bool hasPermission(String key) {
    if (permissions.containsKey(key)) return permissions[key] == true;
    return _defaultPermissionsByRole[role]?[key] == true;
  }

  static const Map<String, Map<String, bool>> _defaultPermissionsByRole = {
    'super_admin': {
      'can_view_dashboard': true,
      'can_view_charts': true,
      'can_export_report': true,
      'can_switch_gudang': false,
      'can_view_stock': true,
      'can_export_stock': true,
      'can_edit_stock_manual': true,
      'can_view_stock_log': true,
      'can_manage_users': true,
      'can_manage_gudang': true,
      'can_manage_produk': true,
      'can_view_kontak': true,
      'can_create_kontak': true,
      'can_edit_kontak_pin_only': true,
      'can_edit_kontak_full': true,
      'can_delete_kontak': true,
      'can_create_transaction': true,
      'can_edit_transaction': true,
      'can_approve_transaction': true,
      'can_cancel_transaction': true,
      'can_cancel_approved_transaction': true,
      'can_uncancel_transaction': true,
      'can_delete_transaction': true,
      'can_delete_attachment': true,
    },
    'admin': {
      'can_view_dashboard': true,
      'can_view_charts': true,
      'can_export_report': true,
      'can_switch_gudang': true,
      'can_view_stock': true,
      'can_export_stock': true,
      'can_edit_stock_manual': true,
      'can_view_stock_log': true,
      'can_manage_users': false,
      'can_manage_gudang': false,
      'can_manage_produk': false,
      'can_view_kontak': true,
      'can_create_kontak': true,
      'can_edit_kontak_pin_only': true,
      'can_edit_kontak_full': false,
      'can_delete_kontak': false,
      'can_create_transaction': true,
      'can_edit_transaction': true,
      'can_approve_transaction': true,
      'can_cancel_transaction': true,
      'can_cancel_approved_transaction': false,
      'can_uncancel_transaction': false,
      'can_delete_transaction': false,
      'can_delete_attachment': false,
    },
    'spectator': {
      'can_view_dashboard': true,
      'can_view_charts': true,
      'can_export_report': false,
      'can_switch_gudang': true,
      'can_view_stock': true,
      'can_export_stock': false,
      'can_edit_stock_manual': false,
      'can_view_stock_log': false,
      'can_manage_users': false,
      'can_manage_gudang': false,
      'can_manage_produk': false,
      'can_view_kontak': true,
      'can_create_kontak': false,
      'can_edit_kontak_pin_only': false,
      'can_edit_kontak_full': false,
      'can_delete_kontak': false,
      'can_create_transaction': false,
      'can_edit_transaction': false,
      'can_approve_transaction': false,
      'can_cancel_transaction': false,
      'can_cancel_approved_transaction': false,
      'can_uncancel_transaction': false,
      'can_delete_transaction': false,
      'can_delete_attachment': false,
    },
    'user': {
      'can_view_dashboard': true,
      'can_view_charts': false,
      'can_export_report': false,
      'can_switch_gudang': false,
      'can_view_stock': false,
      'can_export_stock': false,
      'can_edit_stock_manual': false,
      'can_view_stock_log': false,
      'can_manage_users': false,
      'can_manage_gudang': false,
      'can_manage_produk': false,
      'can_view_kontak': true,
      'can_create_kontak': true,
      'can_edit_kontak_pin_only': true,
      'can_edit_kontak_full': false,
      'can_delete_kontak': false,
      'can_create_transaction': true,
      'can_edit_transaction': true,
      'can_approve_transaction': false,
      'can_cancel_transaction': false,
      'can_cancel_approved_transaction': false,
      'can_uncancel_transaction': false,
      'can_delete_transaction': false,
      'can_delete_attachment': false,
    },
  };

  String get roleLabel {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'spectator':
        return 'Spectator';
      default:
        return 'Sales';
    }
  }
}
