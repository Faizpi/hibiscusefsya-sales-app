/// Maps database status to user-facing display text.
///
/// In the website:
/// - 'Lunas' → 'Lunas'
/// - 'Approved' → 'Belum Lunas'
/// - Others (Pending, Canceled) → as-is
String getStatusDisplay(String status) {
  switch (status) {
    case 'Lunas':
      return 'Lunas';
    case 'Approved':
      return 'Belum Lunas';
    default:
      return status;
  }
}
