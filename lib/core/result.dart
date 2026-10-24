/// Resultado de una operación que puede fallar, igual que en CCL.
///
/// Los repositorios nunca lanzan excepciones hacia la UI: devuelven [Ok] o
/// [Err]. La UI hace `switch` sobre el resultado.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  /// El valor si es [Ok]; null si es [Err].
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

enum FailureType { network, validation, notFound, conflict, server, unknown }

/// Error ya listo para mostrarse: [message] está en español y no trae
/// detalles técnicos. El detalle original va en [cause] solo para logs.
class Failure {
  const Failure(this.type, this.message, {this.cause});

  final FailureType type;
  final String message;
  final Object? cause;

  @override
  String toString() => 'Failure($type, $message)';
}
