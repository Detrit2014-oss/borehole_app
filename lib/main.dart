import 'package:flutter/material.dart';
import 'database.dart';
import 'models.dart';
import 'projects_screen.dart';
import 'project_detail_screen.dart';
import 'soil_manager_screen.dart';

void main() {
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projects = await loadProjects();
    final soilTypes = await loadSoilTypes();
    if (mounted) {
      setState(() {
        _projects = projects;
        _soilTypes = soilTypes;
        _loading = false;
      });
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
              _projects.removeWhere((p) => p.id == project.id);
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
          : ProjectsScreen(
              projects: _projects,
              onAddProject: (project) {
                setState(() => _projects.insert(0, project));
                _persist();
              },
              onDeleteProject: (id) {
                setState(() => _projects.removeWhere((p) => p.id == id));
                _persist();
              },
              onSelectProject: _openProject,
            ),
    );
  }
}
