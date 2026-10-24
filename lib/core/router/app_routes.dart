/// Rutas de la app. Siempre navegar con estas funciones, nunca con strings
/// sueltos, para que un cambio de ruta truene en compilación.
abstract final class AppRoutes {
  static const splash = '/';
  static const assistant = '/asistente';

  // Pestaña Inicio
  static const home = '/inicio';

  // Pestaña Datos
  static const data = '/datos';
  static String topic(String topicId) => '/datos/tema/$topicId';
  static String comparison(String topicId) => '/datos/tema/$topicId/comparativa';
  static String chart(String topicId, String chartId) =>
      '/datos/tema/$topicId/grafica/$chartId';
  static const report = '/datos/informe';
  static const reportPreview = '/datos/informe/vista-previa';

  // Pestaña Encuestas
  static const surveys = '/encuestas';
  static String privacyNotice(String surveyId) => '/encuestas/$surveyId/aviso';
  static String answerSurvey(String surveyId) => '/encuestas/$surveyId/responder';
  static String surveyThanks(String surveyId) => '/encuestas/$surveyId/gracias';

  // Pestaña Donar
  static const donate = '/donar';
  static const donationSuccess = '/donar/exito';
  static const donationFailed = '/donar/rechazado';
}
