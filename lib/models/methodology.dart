/// Cómo se hizo la encuesta. Lo usan la pantalla de metodología y el final del PDF.
///
/// ponytail: solo trae lo que sale de los datos de JCV. Faltan, y JCV tiene que
/// pasarlos: cómo se levantó (cara a cara, teléfono o en línea), el diseño de la
/// muestra, el margen de error y quién hizo las entrevistas. Sin el tamaño de la
/// muestra porque JCV pidió no mostrar conteos.
typedef MethodologySection = ({String title, List<String> points});

const methodology = <MethodologySection>[
  (
    title: 'La encuesta',
    points: [
      'Encuesta de Bienestar de Jóvenes 2026, de Jalisco Cómo Vamos.',
      'A jóvenes de 15 a 29 años del Área Metropolitana de Guadalajara.',
      'Se levantó del 25 de julio al 24 de agosto de 2026.',
      'Cada respuesta pesa según el factor de expansión de la encuesta, para que '
          'los resultados representen a los jóvenes del AMG y no solo a quienes contestaron.',
    ],
  ),
  (
    title: 'Cómo leer los números',
    points: [
      'Los porcentajes se redondean a enteros, así que a veces suman 99 % o 101 %.',
      'Las respuestas «No sabe» y «No contesta» cuentan en el total.',
      'Cuando una gráfica tiene varios incisos, como la confianza en instituciones, '
          'cada uno se calcula por separado y no suman 100.',
    ],
  ),
  (
    title: 'Privacidad',
    points: [
      'No mostramos resultados de grupos muy chicos. Si con tus filtros hay pocas '
          'respuestas, verás un aviso en lugar de la gráfica.',
      'Si el grupo alcanza pero es chico, verás «Muestra pequeña»: interpreta con cuidado.',
      'Puedes usar hasta 2 filtros a la vez: edad, sexo o estrato.',
      'No hay resultados por municipio.',
    ],
  ),
  (
    title: 'Encuesta del Tec',
    points: [
      'Es voluntaria y se contesta en esta app, con preguntas de la encuesta del AMG.',
      'Muestra a quienes quisieron contestar, no a todos los estudiantes del Tec. '
          'Compárala con el AMG como referencia, no como dato exacto.',
      'Sus respuestas no usan factor de expansión: cada una pesa lo mismo.',
      'Cada teléfono puede contestarla una vez.',
    ],
  ),
];
