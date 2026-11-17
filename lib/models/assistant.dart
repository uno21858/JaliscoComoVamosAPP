/// Mini gráfica AMG vs Tec dentro de una respuesta del asistente (5.3).
class AssistantFigure {
  const AssistantFigure({
    required this.caption,
    required this.amg,
    required this.tec,
    required this.nAmg,
    required this.nTec,
  });

  final String caption;
  final double amg;

  /// null: todavía no hay suficientes respuestas del Tec (umbral de privacidad).
  final double? tec;
  final int nAmg;
  final int nTec;
}

/// Respuesta del asistente. Haiku redacta, pero cada cifra del texto la
/// revisa el servidor contra la DB (RF-IA-04/05); si no cuadra, usa plantilla.
class AssistantAnswer {
  const AssistantAnswer({required this.text, this.figure, this.topicId});

  final String text;
  final AssistantFigure? figure;

  /// Temática para el botón "Ver en Datos".
  final String? topicId;
}

enum MessageAuthor { user, assistant }

class ChatMessage {
  const ChatMessage.user(this.text)
      : author = MessageAuthor.user,
        answer = null;

  ChatMessage.assistant(AssistantAnswer this.answer)
      : author = MessageAuthor.assistant,
        text = answer.text;

  final MessageAuthor author;
  final String text;
  final AssistantAnswer? answer;
}
