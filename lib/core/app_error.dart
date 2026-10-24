/// Excepciones internas de los servicios. Nunca llegan a la UI tal cual:
/// el servicio las atrapa y las convierte en Failure con ErrorSanitizer.
sealed class AppError implements Exception {
  const AppError(this.detail);
  final String detail;

  @override
  String toString() => '$runtimeType: $detail';
}

class NetworkError extends AppError {
  const NetworkError([super.detail = 'Sin conexión']);
}

class ValidationError extends AppError {
  const ValidationError(super.detail);
}

class ConflictError extends AppError {
  const ConflictError(super.detail);
}

class ServerError extends AppError {
  const ServerError(super.detail);
}
