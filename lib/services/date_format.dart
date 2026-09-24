/// Formato de fecha en español, escrito a mano para no depender del
/// paquete intl (que exige inicializar los datos de la configuración
/// regional antes de usarse). Alcanza para lo que necesita esta app.
const List<String> _kMonthsEs = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Ej: "26 ago 2026".
String formatDateEs(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = _kMonthsEs[date.month - 1];
  return '$day $month ${date.year}';
}

/// Ej: "26 ago" — usado en las etiquetas del gráfico de progreso.
String formatDateShortEs(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = _kMonthsEs[date.month - 1];
  return '$day $month';
}
