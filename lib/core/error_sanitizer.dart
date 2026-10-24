import 'package:flutter/foundation.dart';

import 'app_error.dart';
import 'result.dart';

/// Ejecuta [body] y convierte cualquier excepción en [Err]. Úsalo en todos
/// los métodos públicos de los servicios para que nada truene en la UI.
Future<Result<T>> guardResult<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } catch (error, stack) {
    return Err(ErrorSanitizer.toFailure(error, stack));
  }
}

/// Convierte cualquier error en un Failure con mensaje para personas.
/// Regla de CCL: nunca `e.toString()` en la UI.
abstract final class ErrorSanitizer {
  static Failure toFailure(Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('ErrorSanitizer: $error');
      if (stack != null) debugPrintStack(stackTrace: stack, maxFrames: 8);
    }
    return switch (error) {
      NetworkError() => Failure(
          FailureType.network,
          'No pudimos conectarnos. Revisa tu conexión a internet.',
          cause: error,
        ),
      ValidationError(:final detail) => Failure(
          FailureType.validation,
          detail,
          cause: error,
        ),
      ConflictError(:final detail) => Failure(
          FailureType.conflict,
          detail,
          cause: error,
        ),
      ServerError() => Failure(
          FailureType.server,
          'Algo falló de nuestro lado. Inténtalo en unos minutos.',
          cause: error,
        ),
      _ => Failure(
          FailureType.unknown,
          'Ocurrió un error inesperado. Inténtalo de nuevo.',
          cause: error,
        ),
    };
  }
}
