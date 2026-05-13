import 'package:flutter/material.dart';
import 'database.dart';
import 'models.dart';
import 'projects_screen.dart';
import 'project_detail_screen.dart';
import 'soil_manager_screen.dart';

void main() {
  // Глобальный обработчик неперехваченных ошибок Flutter
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  runApp(const BoreholeApp());
}

class BoreholeApp extends StatelessWidget {
  const BoreholeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Буровые скважины',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1e3a5f),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> _projects = [];
  List<String> _soilTypes = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final projects = await loadProjects();
      final soilTypes = await loadSoilTypes();
      if (mounted) {
        setState(() {
          _projects = projects;
          _soilTypes = soilTypes;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Ошибка загрузки данных: $e';
        });
      }
    }
  }

  Future<void> _persist() async {
    await saveProjects(_projects);
  }

  Future<void> _persistSoil(List<String> types) async {
    await saveSoilTypes(types);
    if (mounted) setState(() => _soilTypes = types);
  }

  void _openProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          project: project,
          soilTypes: _soilTypes,
          onUpdate: (updated) {
            setState(() {
              _projects = _projects
                  .map((p) => p.id == updated.id ? updated : p)
                  .toList();
            });
            _persist();
          },
          onDelete: () {
            setState(() {
              _projects = _projects.where((p) => p.id != project.id).toList();
            });
            _persist();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _openSoilManager() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SoilManagerScreen(initialTypes: _soilTypes),
      ),
    );
    if (result != null) _persistSoil(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Буровые скважины'),
        backgroundColor: const Color(0xFF1e3a5f),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Справочник грунтов',
            onPressed: _openSoilManager,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_loadError!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _loadError = null;
                            });
                            _loadData();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : ProjectsScreen(
                  projects: _projects,
                  onAddProject: (project) {
                    setState(() => _projects = [project, ..._projects]);
                    _persist();
                  },
                  onDeleteProject: (id) {
                    setState(() {
                      _projects = _projects.where((p) => p.id != id).toList();
                    });
                    _persist();
                  },
                  onSelectProject: _openProject,
                ),
    );
  }
}
