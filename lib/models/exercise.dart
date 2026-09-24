/// Los 10 ejercicios que el instructor evalúa en cada ficha. Cada uno se
/// califica de 0 a 3 según la técnica observada; los que salen débiles
/// pasan al plan del estudiante con su prescripción (ver
/// lib/services/recommendation.dart).
class Exercise {
  final String id;
  final String name;

  /// Qué observa el instructor al evaluar la técnica.
  final String criteria;

  /// Series, repeticiones y foco cuando el ejercicio entra al plan.
  final String prescription;

  const Exercise({
    required this.id,
    required this.name,
    required this.criteria,
    required this.prescription,
  });
}

const List<Exercise> kExercises = [
  Exercise(
    id: 'press-banca',
    name: 'Press banca',
    criteria: 'Trayectoria de la barra, escápulas retraídas y control de los codos.',
    prescription: 'Press con barra en banco plano, 3x8, control de la fase excéntrica.',
  ),
  Exercise(
    id: 'dominadas',
    name: 'Dominadas',
    criteria: 'Rango completo, control escapular y sin balanceo del tronco.',
    prescription: 'Agarre prono, 3 series al fallo técnico (asistidas con banda si hace falta).',
  ),
  Exercise(
    id: 'peso-muerto',
    name: 'Peso muerto',
    criteria: 'Bisagra de cadera, espalda neutra y barra cerca del cuerpo.',
    prescription: 'Convencional o rumano, 3x6, foco en bisagra de cadera y espalda neutra.',
  ),
  Exercise(
    id: 'sentadilla',
    name: 'Sentadilla',
    criteria: 'Profundidad, alineación de rodillas y talones apoyados.',
    prescription: 'Con barra o goblet, 3x8, foco en profundidad y control de rodillas.',
  ),
  Exercise(
    id: 'plancha-lateral',
    name: 'Plancha lateral',
    criteria: 'Cadera alineada con hombros y tobillos, sin rotar el tronco.',
    prescription: '3 series de 20-30 segundos por lado, cadera alineada.',
  ),
  Exercise(
    id: 'plancha-frontal',
    name: 'Plancha frontal',
    criteria: 'Columna neutra, sin hundir ni elevar la cadera.',
    prescription: '3 series de 30-45 segundos, sin dejar caer la cadera.',
  ),
  Exercise(
    id: 'estocada',
    name: 'Estocada',
    criteria: 'Estabilidad de la rodilla, tronco erguido y descenso controlado.',
    prescription: 'Caminando o estática, 3x8 por lado.',
  ),
  Exercise(
    id: 'remo',
    name: 'Remo',
    criteria: 'Retracción escapular y espalda neutra, sin impulso.',
    prescription: 'Con barra o mancuerna, 3x10, foco en retracción escapular.',
  ),
  Exercise(
    id: 'jalon-pecho',
    name: 'Jalón al pecho',
    criteria: 'Depresión escapular, sin inclinar el tronco en exceso.',
    prescription: 'En polea, 3x10, control del descenso.',
  ),
  Exercise(
    id: 'biceps',
    name: 'Curl de bíceps',
    criteria: 'Codos fijos junto al cuerpo, sin balanceo, bajada controlada.',
    prescription: 'Con barra o mancuernas, 3x12, accesorio de tren superior.',
  ),
];

final Map<String, Exercise> kExerciseById = {
  for (final e in kExercises) e.id: e,
};

/// Nombre legible de un ejercicio por su id, con respaldo si no existe.
String exerciseName(String id) => kExerciseById[id]?.name ?? id;

/// Puntaje máximo posible de la ficha completa (10 ejercicios x 3 puntos).
final int kMaxScore = kExercises.length * 3;

/// Etiqueta de cada puntaje posible (0 a 3).
const Map<int, String> kScoreLabels = {
  0: 'Dolor — remitir a evaluación clínica',
  1: 'No logra ejecutar el ejercicio',
  2: 'Lo ejecuta con compensaciones',
  3: 'Técnica correcta sin compensaciones',
};
