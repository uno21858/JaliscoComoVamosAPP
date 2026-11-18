# App Jalisco Cómo Vamos

App móvil (Flutter, iOS y Android) del reto ago-dic 2026 con Jalisco Cómo Vamos. Equipo LinuxVSWindows, grupo 502, Tec GDL.

**Estado: fase 2.** Están las 34 pantallas del wireflow con navegación real. **Datos, Encuestas, el asistente (con dictado por voz) y el informe PDF ya son reales**, con la base de la Encuesta de Bienestar de Jóvenes AMG 2026 (Supabase + Claude Haiku). Donar sigue en mock. No hay login.

## Correr la app

Requisitos: Flutter 3.29 o más nuevo.

1. Pide el archivo **`.env`** al equipo (no está en git porque el repo es público) y ponlo en la raíz del proyecto. Lleva `SUPABASE_URL` y `SUPABASE_ANON_KEY`, como `.env.example`. Sin él la app no compila, igual que CCL.
2. Corre:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -t lib/main_dev.dart
```

En IntelliJ / Android Studio elige **main_dev.dart** junto al botón de play (viene en `.idea/runConfigurations/`). El `.env` viaja dentro de la app, así que solo lleva llaves públicas: la anon key lo es por diseño y la key de Anthropic vive únicamente en la Edge Function.

Como en CCL, `lib/main.dart` truena a propósito: siempre se corre con `main_dev.dart` o `main_prod.dart`. Los flavors de Gradle y Xcode (`--flavor dev`) se configuran cuando entre Cognito, porque ahí cambian llaves y proyectos.

## Estructura

Por capa, igual que CCL:

```
lib/
  main.dart, main_dev.dart, main_prod.dart, app.dart
  flavors/        FlavorConfig (mocks, latencia, fallas simuladas, Supabase desde el .env)
  core/           Result<T>/Failure, AppError, ErrorSanitizer, tema, router, utilidades
  models/         modelos inmutables (sin Flutter salvo lo mínimo)
  repositories/   interfaces: DataRepository, SurveyRepository, DonationRepository, AssistantRepository
  services/
    mock/         implementaciones con datos sintéticos
    local/        almacenamiento cifrado (borradores de encuesta, id del dispositivo)
    supabase/     implementaciones reales (hoy: el asistente)
  providers/      ChangeNotifier (Provider)
  widgets/        design system del wireflow
  screens/        una carpeta por flujo: home, data, surveys, donate, assistant
SQLScripts/       migraciones vX.XX_*.sql del schema jcv (se corren en orden)
scripts/          importar_amg.py + cargar_amg.sql (datos de JCV), deploy_asistente.sh
supabase/         edge functions, una carpeta por función (como CCL, no supabase/functions/)
```

## Backend del asistente

Vive en el proyecto Supabase de **CCL DEV**, aislado en el schema `jcv` (expuesto en Settings → API). Las tablas tienen RLS sin políticas: solo se entra por funciones `SECURITY DEFINER` que hoy solo puede ejecutar `service_role`. Del servidor a la app solo salen agregados, nunca filas.

- **Datos:** `jcv.personas` (municipio, edad, sexo, estrato, factor), `jcv.respuestas` (formato largo) y `jcv.preguntas` (catálogo). `jcv.grafica()` pondera con el factor de expansión y cuenta "No sabe/No contestó" en la base, igual que los cruces de JCV (verificado: 764 porcentajes, 0 diferencias).
- **Cargar la base de JCV:** `python3 -I scripts/importar_amg.py "<carpeta de datos>"` genera los CSV en `~/Downloads/jcv_import` (fuera del repo; se quitan colonia, fecha y respuestas abiertas) y se suben con `scripts/cargar_amg.sql` o desde el Table Editor, en orden: preguntas, personas, respuestas.
- **Edge Function `jcv-asistente`:** Haiku elige la pregunta y los filtros, consulta `jcv.grafica` y redacta. Toda cifra del texto se revisa contra la DB; si no cuadra, se responde con plantilla. Deploy: `sh scripts/deploy_asistente.sh`. Secret: `ANTHROPIC_API_KEY`.
- **Límites:** 20 preguntas al día y 10 por minuto por dispositivo (id aleatorio guardado en el teléfono); 1000 al día y 60 por minuto por IP. El tope de dinero es el límite de gasto en la consola de Anthropic.
- **Caché:** el system prompt se cachea en Anthropic y las preguntas repetidas sin historial salen de `jcv.cache_respuestas`. Si cambias prompt, modelo o datos, sube `CACHE_VERSION` en la función.
- **Bitácora:** cada pregunta queda en `jcv.bitacora`, anónima (IP y dispositivo con hash).

## Encuestas del Tec

Una encuesta por temática con **las mismas preguntas y opciones del AMG** que salen en Datos (`lib/services/supabase/graficas_destacadas.dart`), para que las respuestas se puedan comparar. Edad (18 a 29), sexo y municipio se preguntan una vez y se guardan en el teléfono; el estrato no se pregunta.

- `jcv.guardar_encuesta` (v1.05) valida cada respuesta contra el catálogo y las guarda como fuente `TEC`. La marca de "ya contestó" va en otra tabla, sin ligarse a las respuestas (RF-ENC-09).
- Una vez por encuesta y por teléfono, y máximo 300 envíos por hora por IP. Sin login, reinstalando la app se podría contestar otra vez.
- La comparativa AMG vs Tec aparece sola cuando una pregunta junta 30 respuestas del Tec.


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
| Metodología (nueva) | `screens/data/methodology_screen.dart` |
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

- **2.9 Sin suficientes respuestas:** en Filtros elige fuente Tec, una edad y un estrato. La muestra Tec simulada es de 150 y el umbral de 30.
- **Aviso de muestra pequeña (AMG):** con datos reales sale cuando dos filtros dejan menos de 30 respuestas. Máximo 2 filtros a la vez (privacidad, v1.03).
- **2.10 Sin conexión:** en `main_dev.dart` pon `mockFailureRate: 0.3` en `FlavorConfig`.
- **4.6 Pago rechazado:** en la hoja de pago, "Simular pago rechazado" (solo en dev).
- **Retomar encuesta:** responde unas preguntas, toca "Guardar y salir" y regresa a Encuestas.
- Encuesta ya contestada: con Supabase, contéstala y vuelve a la lista (sale como completada). Con mocks, Transporte arranca completada.

Los números son sintéticos. En dev aparece la etiqueta "Datos de ejemplo" para que nadie los confunda con resultados reales en una demo.

## Diferencias con el wireflow

- Sin login: Encuestas entra directo a la lista y el texto del aviso ya no menciona el correo.
- La hoja de pago es simulada y no captura tarjeta. En producción la dibuja Stripe.
- El informe PDF se arma en el teléfono (`services/local/report_pdf.dart`); en papel todas las gráficas van en barras. "Compartir" en el detalle copia el dato y su fuente.
- Por petición de JCV: sin filtro por municipio (v1.07) y sin mostrar cuántas respuestas hay (ni n, ni total, ni en el chat).
- Gráficas: dona hasta 6 opciones; anillos para preguntas de grupo (sus % no suman 100) y de 7 opciones en adelante; anillos dobles en la comparativa AMG vs Tec. Sin barras en la app (JCV): `python3 scripts/check_sin_barras.py` lo revisa.
- Se agregó la pantalla de metodología (JCV la pidió): se abre desde Datos y desde el detalle, y también va al final del PDF. El texto vive en `models/methodology.dart`. Faltan datos que solo JCV tiene: cómo se levantó, diseño de la muestra, margen de error y quién hizo las entrevistas.
- Se agregó "Comparar AMG vs Tec" al final de cada temática; en el wireflow solo se llegaba desde Filtros.
- La rueda de edad va de 18 a 29, por BR-13.

## Siguientes fases

1. Auth con AWS Cognito (pantallas 3.1 a 3.3 y 4.2), con el mismo patrón de CCL: tokens en `flutter_secure_storage`, interceptor de refresh y lambda pre-token-generation.
2. Donativos con Stripe; con login, los RPC validan al usuario con `validate_caller` como en CCL y las encuestas pasan de "una vez por teléfono" a "una vez por persona".
3. Stripe: decidir PaymentSheet dentro de la app contra Checkout en el navegador (RF-DON-01 y la regla 3.2.2 de App Store).
4. Historial del asistente guardado, ligado a la cuenta (con login, para validar dueño y evitar IDOR).

Pendientes del equipo: umbral k (hoy 10 AMG y 30 Tec en `jcv.grafica`), si el dashboard es público y si entran menores de 18 (la base AMG sí trae jóvenes de 15 a 17).

## Marcadores

- El logo es un marcador dibujado con código (`JcvRing`). Va el archivo oficial de JCV.
- Los textos entre corchetes del aviso de privacidad van del aviso oficial.
- Las preguntas de las encuestas mock salen del catálogo del SRS; las definitivas se acuerdan con JCV.
- Fuente Montserrat (licencia OFL, `assets/fonts/OFL.txt`).
