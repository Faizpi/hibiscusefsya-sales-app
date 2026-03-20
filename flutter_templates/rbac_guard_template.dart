enum AppRole { superAdmin, admin, spectator, user }

class AuthUser {
  final int id;
  final AppRole role;
  final int? gudangId;
  final int? currentGudangId;
  final List<int> adminGudangIds;
  final List<int> spectatorGudangIds;

  const AuthUser({
    required this.id,
    required this.role,
    required this.gudangId,
    required this.currentGudangId,
    required this.adminGudangIds,
    required this.spectatorGudangIds,
  });
}

class PermissionSet {
  final bool canViewDashboard;
  final bool canViewCharts;
  final bool canExportReport;
  final bool canSwitchGudang;
  final bool canViewStock;
  final bool canExportStock;
  final bool canEditStockManual;
  final bool canViewStockLog;
  final bool canManageUsers;
  final bool canManageGudang;
  final bool canManageProduk;
  final bool canCreateTransaction;
  final bool canApproveTransaction;
  final bool canCancelApprovedTransaction;
  final bool canUncancelTransaction;
  final bool canDeleteTransaction;
  final bool canDeleteAttachment;
  final bool canEditKontakFull;
  final bool canEditKontakPinOnly;

  const PermissionSet({
    required this.canViewDashboard,
    required this.canViewCharts,
    required this.canExportReport,
    required this.canSwitchGudang,
    required this.canViewStock,
    required this.canExportStock,
    required this.canEditStockManual,
    required this.canViewStockLog,
    required this.canManageUsers,
    required this.canManageGudang,
    required this.canManageProduk,
    required this.canCreateTransaction,
    required this.canApproveTransaction,
    required this.canCancelApprovedTransaction,
    required this.canUncancelTransaction,
    required this.canDeleteTransaction,
    required this.canDeleteAttachment,
    required this.canEditKontakFull,
    required this.canEditKontakPinOnly,
  });
}

class RolePermissionMapper {
  static PermissionSet fromRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return const PermissionSet(
          canViewDashboard: true,
          canViewCharts: true,
          canExportReport: true,
          canSwitchGudang: false,
          canViewStock: true,
          canExportStock: true,
          canEditStockManual: true,
          canViewStockLog: true,
          canManageUsers: true,
          canManageGudang: true,
          canManageProduk: true,
          canCreateTransaction: true,
          canApproveTransaction: true,
          canCancelApprovedTransaction: true,
          canUncancelTransaction: true,
          canDeleteTransaction: true,
          canDeleteAttachment: true,
          canEditKontakFull: true,
          canEditKontakPinOnly: true,
        );
      case AppRole.admin:
        return const PermissionSet(
          canViewDashboard: true,
          canViewCharts: true,
          canExportReport: true,
          canSwitchGudang: true,
          canViewStock: true,
          canExportStock: true,
          canEditStockManual: false,
          canViewStockLog: true,
          canManageUsers: false,
          canManageGudang: false,
          canManageProduk: false,
          canCreateTransaction: true,
          canApproveTransaction: true,
          canCancelApprovedTransaction: false,
          canUncancelTransaction: false,
          canDeleteTransaction: false,
          canDeleteAttachment: false,
          canEditKontakFull: false,
          canEditKontakPinOnly: true,
        );
      case AppRole.spectator:
        return const PermissionSet(
          canViewDashboard: true,
          canViewCharts: true,
          canExportReport: false,
          canSwitchGudang: true,
          canViewStock: true,
          canExportStock: true,
          canEditStockManual: false,
          canViewStockLog: false,
          canManageUsers: false,
          canManageGudang: false,
          canManageProduk: false,
          canCreateTransaction: false,
          canApproveTransaction: false,
          canCancelApprovedTransaction: false,
          canUncancelTransaction: false,
          canDeleteTransaction: false,
          canDeleteAttachment: false,
          canEditKontakFull: false,
          canEditKontakPinOnly: false,
        );
      case AppRole.user:
        return const PermissionSet(
          canViewDashboard: true,
          canViewCharts: false,
          canExportReport: false,
          canSwitchGudang: false,
          canViewStock: false,
          canExportStock: false,
          canEditStockManual: false,
          canViewStockLog: false,
          canManageUsers: false,
          canManageGudang: false,
          canManageProduk: false,
          canCreateTransaction: true,
          canApproveTransaction: false,
          canCancelApprovedTransaction: false,
          canUncancelTransaction: false,
          canDeleteTransaction: false,
          canDeleteAttachment: false,
          canEditKontakFull: false,
          canEditKontakPinOnly: true,
        );
    }
  }
}

class GudangScope {
  static int? getActiveGudang(AuthUser user) {
    if (user.role == AppRole.user) return user.gudangId;
    return user.currentGudangId;
  }

  static bool canAccessGudang(AuthUser user, int gudangId) {
    if (user.role == AppRole.superAdmin) return true;

    if (user.role == AppRole.admin) {
      return user.adminGudangIds.contains(gudangId) ||
          user.currentGudangId == gudangId;
    }

    if (user.role == AppRole.spectator) {
      return user.spectatorGudangIds.contains(gudangId) ||
          user.currentGudangId == gudangId;
    }

    return user.gudangId == gudangId;
  }
}

enum TxStatus { pending, approved, lunas, canceled, rejected }

class TransactionActionGuard {
  static bool canCreate(AuthUser user) {
    return RolePermissionMapper.fromRole(user.role).canCreateTransaction;
  }

  static bool canApprove(AuthUser user, int gudangId, TxStatus status) {
    final p = RolePermissionMapper.fromRole(user.role);
    if (!p.canApproveTransaction) return false;
    if (status != TxStatus.pending) return false;
    if (user.role == AppRole.superAdmin) return true;
    return GudangScope.canAccessGudang(user, gudangId);
  }

  static bool canCancel(AuthUser user, TxStatus status) {
    if (user.role == AppRole.superAdmin) {
      return status == TxStatus.pending ||
          status == TxStatus.approved ||
          status == TxStatus.lunas;
    }
    if (user.role == AppRole.admin) {
      return status == TxStatus.pending;
    }
    return false;
  }

  static bool canUncancel(AuthUser user, TxStatus status) {
    return user.role == AppRole.superAdmin && status == TxStatus.canceled;
  }

  static bool canDelete(AuthUser user) {
    return RolePermissionMapper.fromRole(user.role).canDeleteTransaction;
  }

  static bool canDeleteAttachment(AuthUser user) {
    return RolePermissionMapper.fromRole(user.role).canDeleteAttachment;
  }
}

class AppRouteGuard {
  static bool canOpen(String routeName, AuthUser user) {
    final p = RolePermissionMapper.fromRole(user.role);

    switch (routeName) {
      case '/dashboard':
        return p.canViewDashboard;
      case '/users':
        return p.canManageUsers;
      case '/gudang':
        return p.canManageGudang;
      case '/produk':
        return p.canManageProduk;
      case '/stok':
        return p.canViewStock;
      case '/stok-log':
        return p.canViewStockLog;
      case '/report-export':
        return p.canExportReport;
      default:
        return true;
    }
  }
}

class EndpointGuard {
  static bool canCall({
    required AuthUser user,
    required String method,
    required String path,
  }) {
    final p = RolePermissionMapper.fromRole(user.role);

    if (path == '/api/v1/stok' && method == 'POST') {
      return p.canEditStockManual;
    }

    if (path.startsWith('/api/v1/users')) {
      return p.canManageUsers;
    }

    if (path == '/api/v1/dashboard/export' ||
        path == '/api/v1/dashboard/export/options') {
      return p.canExportReport;
    }

    return true;
  }
}
