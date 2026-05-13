import 'package:flutter/material.dart';
import 'models.dart';
import 'utils.dart';

class ProjectsScreen extends StatelessWidget {
  final List<Project> projects;
  final Function(Project) onAddProject;
  final Function(String) onDeleteProject;
  final Function(Project) onSelectProject;

  const ProjectsScreen({
    super.key,
    required this.projects,
    required this.onAddProject,
    required this.onDeleteProject,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.domain_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Нет объектов',
                  style: TextStyle(fontSize: 20, color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('Создайте первый объект',
                  style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Новый объект'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('Объекты (${projects.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Новый объект'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelectProject(p),
                  onLongPress: () => _confirmDelete(context, p),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1e3a5f)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.apartment,
                                  color: Color(0xFF1e3a5f)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  if (p.address.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(children: [
                                        Icon(Icons.location_on,
                                            size: 14, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(p.address,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[500]),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.science,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text('${p.boreholes.length} скв.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[400])),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(formatDate(p.createdAt),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[400])),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Project p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить "${p.name}"?'),
        content: const Text('Все скважины будут удалены.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              onDeleteProject(p.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.add_circle, color: Color(0xFF1e3a5f)),
          SizedBox(width: 8),
          Text('Новый объект'),
        ]),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Название *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Обязательное поле'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                    labelText: 'Адрес', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Описание', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onAddProject(Project.create(
                  name: nameCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
