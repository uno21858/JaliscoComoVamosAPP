# App Jalisco Cómo Vamos

App móvil (Flutter, iOS y Android) del reto ago-dic 2026 con Jalisco Cómo Vamos. Equipo LinuxVSWindows, grupo 502, Tec GDL.

**Estado: fase 1.** Están las 34 pantallas del wireflow con navegación real y datos de ejemplo. No hay login ni backend todavía: todo pasa por servicios mock que se cambian por los reales sin tocar pantallas.

## Correr la app

Requisitos: Flutter 3.29 o más nuevo.

Este zip no trae las carpetas `android/` ni `ios/`. Se generan una vez:

```bash
cd jcv_app
flutter create --org mx.jalisco.comovamos --project-name jcv_app --platforms android,ios .
flutter pub get
flutter analyze
flutter test
flutter run -t lib/main_dev.dart
```

`flutter create .` no sobrescribe `lib/` ni `pubspec.yaml`; solo agrega lo que falta. Si te pregunta por `test/widget_test.dart`, bórralo: apunta a un `MyApp` que no existe.

Como en CCL, `lib/main.dart` truena a propósito: siempre se corre con `main_dev.dart` o `main_prod.dart`. Los flavors de Gradle y Xcode (`--flavor dev`) se configuran cuando entren Supabase y Cognito, porque ahí cambian llaves y proyectos.

## Estructura

Por capa, igual que CCL:

```
lib/
  main.dart, main_dev.dart, main_prod.dart, app.dart
  flavors/        FlavorConfig (mocks, latencia, fallas simuladas)
  core/           Result<T>/Failure, AppError, ErrorSanitizer, tema, router, utilidades
  models/         modelos inmutables (sin Flutter salvo lo mínimo)
  repositories/   interfaces: DataRepository, SurveyRepository, DonationRepository, AssistantRepository
  services/
    mock/         implementaciones con datos sintéticos
    local/        almacenamiento cifrado (borradores de encuesta)
  providers/      ChangeNotifier (Provider)
  widgets/        design system del wireflow
  screens/        una carpeta por flujo: home, data, surveys, donate, assistant
```

**Barrels:** uno por capa (`core/core.dart`, `models/models.dart`, `repositories/repositories.dart`, `providers/providers.dart`, `widgets/widgets.dart`). Las pantallas importan barrels; dentro de una misma carpeta se importa el archivo directo para no crear ciclos.

## Reglas del proyecto

- Los repositorios nunca lanzan excepciones a la UI: regresan `Ok` o `Err`. Los mensajes pasan por `ErrorSanitizer`; nunca `e.toString()` en pantalla.
- Navegación solo con `AppRoutes` (go_router). Nada de strings sueltos.
- Dinero siempre en centavos y como `int` (`Money`). Nunca `double`.
- La app nunca recibe filas de la encuesta: solo agregados. El umbral de privacidad Tec lo aplica el servidor y la app solo pinta `Enough` o `TooFew`.
- Borradores de encuesta en `flutter_secure_storage`, nunca en SharedPreferences.
- Interfaz solo en español (RNF-ACC-03). Textos de la UI directo en los widgets.

## Pantallas

| Wireflow | Archivo |
|---|---|
| 1.1 Splash | `screens/splash/splash_screen.dart` |
| 1.2 Inicio | `screens/home/home_screen.dart` |
| Barra inferior y botón + | `widgets/jcv_tab_bar.dart`, `screens/shell/main_shell.dart` |
| 2.1 Temáticas | `screens/data/topics_screen.dart` |
| 2.2 Temática, 2.8, 2.9, 2.10 | `screens/data/topic_screen.dart` |
| 2.3 Filtros | `screens/data/widgets/filters_sheet.dart` |
| 2.4 Comparativa | `screens/data/comparison_screen.dart` |
| 2.5 Detalle | `screens/data/chart_detail_screen.dart` |
| 2.6 Generar informe | `screens/data/report_screen.dart` |
| 2.7 Vista previa | `screens/data/report_preview_screen.dart` |
| 3.4 Lista, 3.13 Retomar | `screens/surveys/survey_list_screen.dart` |
| 3.5, 3.6 Aviso de privacidad | `screens/surveys/privacy_notice_screen.dart` |
| 3.7 a 3.10, 3.12 Preguntas | `screens/surveys/survey_screen.dart` |
| 3.11 Gracias | `screens/surveys/survey_thanks_screen.dart` |
| 4.1, 4.3 Donativo | `screens/donate/donate_screen.dart` |
| 4.4 Hoja de pago | `screens/donate/mock_payment_sheet.dart` |
| 4.5, 4.6 Resultado | `screens/donate/donation_result_screen.dart` |
| 5.1 a 5.3 Asistente | `screens/assistant/assistant_screen.dart` |

Fuera por ahora, porque dependen del login: 3.1 Acceso, 3.2 Registro bloqueado, 3.3 Verifica tu correo y 4.2 Donativo con sesión.

## Probar los estados con los mocks

- **2.9 Sin suficientes respuestas:** en Filtros elige fuente Tec y un municipio. La muestra Tec simulada es de 150 y el umbral de 30.
- **Aviso de muestra pequeña (AMG):** elige municipio, edad, sexo y estrato a la vez.
- **2.10 Sin conexión:** en `main_dev.dart` pon `mockFailureRate: 0.3` en `FlavorConfig`.
- **4.6 Pago rechazado:** en la hoja de pago, "Simular pago rechazado" (solo en dev).
- **Retomar encuesta:** responde unas preguntas, toca "Guardar y salir" y regresa a Encuestas.
- La encuesta de Transporte arranca como completada para ver ese estado.

Los números son sintéticos. En dev aparece la etiqueta "Datos de ejemplo" para que nadie los confunda con resultados reales en una demo.

## Diferencias con el wireflow

- Sin login: Encuestas entra directo a la lista y el texto del aviso ya no menciona el correo.
- La hoja de pago es simulada y no captura tarjeta. En producción la dibuja Stripe.
- "Exportar PDF" y "Compartir" del informe avisan que todavía no están; "Compartir" en el detalle copia el dato y su fuente.
- Se agregó "Comparar AMG vs Tec" al final de cada temática; en el wireflow solo se llegaba desde Filtros.
- La rueda de edad va de 18 a 29, por BR-13.

## Siguientes fases

1. Auth con AWS Cognito (pantallas 3.1 a 3.3 y 4.2), con el mismo patrón de CCL: tokens en `flutter_secure_storage`, interceptor de refresh y lambda pre-token-generation.
2. Supabase: tablas con RLS deny-all y todo por RPC `SECURITY DEFINER` con `validate_caller`, como CCL. Servicios en `lib/services/supabase/` que implementan las mismas interfaces.
3. Stripe: decidir PaymentSheet dentro de la app contra Checkout en el navegador (RF-DON-01 y la regla 3.2.2 de App Store).
4. Asistente: Edge Function con Gemini en modo de llamada a función y `speech_to_text` con `onDevice: true`.
5. Informe PDF y compartir.

Pendientes del equipo antes del backend: umbral k, qué recibe Gemini, si el dashboard es público y si entran menores de 18.

## Marcadores

- El logo es un marcador dibujado con código (`JcvRing`). Va el archivo oficial de JCV.
- Los textos entre corchetes del aviso de privacidad van del aviso oficial.
- Las preguntas de las encuestas mock salen del catálogo del SRS; las definitivas se acuerdan con JCV.
- Fuente Montserrat (licencia OFL, `assets/fonts/OFL.txt`).
