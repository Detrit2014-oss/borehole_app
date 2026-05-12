import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

const _projectsKey = 'borehole_projects_db';

Future<List<Project>> loadProjects() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_projectsKey);
  if (raw == null) return [];
  final list = jsonDecode(raw) as List;
  return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
}

Future<void> saveProjects(List<Project> projects) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _projectsKey,
    jsonEncode(projects.map((p) => p.toJson()).toList()),
  );
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
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_soilKey);
  if (raw == null) return List<String>.from(defaultSoilTypes);
  final list = jsonDecode(raw) as List;
  if (list.isEmpty) return List<String>.from(defaultSoilTypes);
  return list.cast<String>();
}

Future<void> saveSoilTypes(List<String> types) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_soilKey, jsonEncode(types));
}
