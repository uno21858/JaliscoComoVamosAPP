/// Rutas de la app. Siempre navegar con estas constantes, nunca con strings
/// sueltos, para que un cambio de ruta truene en compilación.
abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/bienvenida';
  static const assistant = '/asistente';

  // MAIN (barra inferior). Las 4 pestañas son la misma pantalla con ?tab=,
  // igual que buildMainWithTab de CCL. context.go(AppRoutes.data) cambia de pestaña.
  static const main = '/main';
  static const home = '$main?tab=0';
  static const data = '$main?tab=1';
  static const surveys = '$main?tab=2';
  static const donate = '$main?tab=3';
  static const tabs = [home, data, surveys, donate];

  // DATOS
  static String topic(String topicId) => '/datos/tema/$topicId';
  static String comparison(String topicId) => '/datos/tema/$topicId/comparativa';
  static String chart(String topicId, String chartId) =>
      '/datos/tema/$topicId/grafica/$chartId';
  static const report = '/datos/informe';
  static const reportPreview = '/datos/informe/vista-previa';
  static const methodology = '/datos/metodologia';

  // ACCESO (3.1, 3.3). Solo para Encuestas: Datos y el asistente son públicos.
  static const access = '/acceso';
  static const register = '$access?registro=1';
  static const verifyEmail = '$access/verificar';
  static const resetPassword = '$access/recuperar';

  // ENCUESTAS
  static String privacyNotice(String surveyId) => '/encuestas/$surveyId/aviso';
  static String answerSurvey(String surveyId) => '/encuestas/$surveyId/responder';
  static String surveyThanks(String surveyId) => '/encuestas/$surveyId/gracias';

  // DONAR
  static const donationSuccess = '/donar/exito';
  static const donationFailed = '/donar/rechazado';
}
