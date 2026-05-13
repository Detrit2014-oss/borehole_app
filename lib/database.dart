import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

const _projectsKey = 'borehole_projects_db';

Future<List<Project>> loadProjects() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    // Если JSON повреждён — возвращаем пустой список, а не крашим приложение
    return [];
  }
}

Future<void> saveProjects(List<Project> projects) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _projectsKey,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  } catch (e) {
    // Логируем ошибку, но не крашим
  }
}

const _soilKey = 'borehole_soil_types';

const List<String> defaultSoilTypes = [
  'Насыпной грунт',
  'Почвенно-растительный слой',
  'Песок гравелистый',
  'Песок крупный',
  'Песок средней крупности',
  'Песок мелкий',
  'Песок пылеватый',
  'Супесь',
  'Супесь пылеватая',
  'Суглинок',
  'Суглинок пылеватый',
  'Глина',
  'Ил',
  'Ил суглинистый',
  'Торф',
  'Гравий',
  'Гравийно-галечный грунт',
  'Галечник',
  'Щебень',
  'Дресва',
  'Скальный грунт',
  'Элювиальный грунт',
  'Техногенный грунт',
  'Заторфованный грунт',
  'Мергель',
  'Известняк',
  'Песчаник',
  'Аргиллит',
  'Алевролит',
];

Future<List<String>> loadSoilTypes() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_soilKey);
    if (raw == null) return List<String>.from(defaultSoilTypes);
    final list = jsonDecode(raw) as List;
    if (list.isEmpty) return List<String>.from(defaultSoilTypes);
    return list.cast<String>();
  } catch (e) {
    // При повреждённых данных — возвращаем стандартный список
    return List<String>.from(defaultSoilTypes);
  }
}

Future<void> saveSoilTypes(List<String> types) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soilKey, jsonEncode(types));
  } catch (e) {
    // Логируем, но не крашим
  }
}
