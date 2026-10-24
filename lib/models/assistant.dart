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
  final double tec;
  final int nAmg;
  final int nTec;
}

/// Respuesta del asistente. El texto sale de una plantilla del servidor con
/// cifras calculadas por el mismo código del dashboard, nunca de Gemini.
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
