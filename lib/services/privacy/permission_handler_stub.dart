// ============================================================================
// FILE: lib/core/permission_handler_stub.dart
// Web stub for permission_handler package
// ============================================================================
class Permission {
  const Permission._();

  static const notification = Permission._();
  static const sms = Permission._();
  static const camera = Permission._();

  Future<PermissionStatus> request() async {
    return PermissionStatus.denied;
  }
}

class PermissionStatus {
  const PermissionStatus._();

  static const granted = PermissionStatus._();
  static const denied = PermissionStatus._();
  static const permanentlyDenied = PermissionStatus._();

  bool get isGranted => false;
}