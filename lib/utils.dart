import 'package:intl/intl.dart';

/// Форматирование ISO-даты в DD.MM.YYYY
String formatDate(String iso) {
  try {
    return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso));
  } catch (_) {
    return '—';
  }
}
