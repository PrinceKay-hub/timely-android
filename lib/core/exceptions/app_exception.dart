
/// A user-facing exception. Always safe to show `.message` directly in the UI.
class AppException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() => message;
}