// lib/screens/project_settings_screen.dart

import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme.dart';

class ProjectSettingsScreen extends StatelessWidget {
  final String slug;
  const ProjectSettingsScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final project = AppState.instance.getProject(slug);
        if (project == null) return const SizedBox();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Project Info ─────────────────────────────
            _sectionHeader('Project Info'),
            _settingTile(
              context, 'Name', project.name,
              onTap: () => _editText(context, 'Project Name',
                  project.name, (v) async {
                await AppState.instance.updateProjectSettings(
                    slug, name: v);
              }),
            ),
            _settingTile(
              context, 'Icon', project.icon,
              onTap: () => _editText(context, 'Icon Emoji',
                  project.icon, (v) async {
                await AppState.instance.updateProjectSettings(
                    slug, icon: v);
              }),
            ),
            _settingTile(
              context, 'Description',
              project.description.isEmpty ? 'None' : project.description,
              onTap: () => _editText(context, 'Description',
                  project.description, (v) async {
                await AppState.instance.updateProjectSettings(
                    slug, description: v);
              }),
            ),
            _settingTile(
              context, 'Currency',
              project.currency ?? 'Global default (₹)',
              onTap: () => _editText(context, 'Currency Symbol',
                  project.currency ?? '', (v) async {
                await AppState.instance.updateProjectSettings(
                    slug, currency: v);
              }),
            ),
            const SizedBox(height: 20),

            // ── Categories ───────────────────────────────
            _sectionHeader('Categories'),
            _listManagerTile(
              context,
              items: project.categories,
              onAdd: (v) async => await AppState.instance
                  .updateProjectSettings(slug,
                      categories: [...project.categories, v]),
              onDelete: (i) async => await AppState.instance
                  .updateProjectSettings(slug,
                      categories: List<String>.from(project.categories)
                        ..removeAt(i)),
              onEdit: (i, v) async {
                final updated = List<String>.from(project.categories);
                updated[i] = v;
                await AppState.instance.updateProjectSettings(
                    slug, categories: updated);
              },
            ),
            const SizedBox(height: 20),

            // ── Payment Modes ────────────────────────────
            _sectionHeader('Payment Modes'),
            _listManagerTile(
              context,
              items: project.paymentModes,
              onAdd: (v) async => await AppState.instance
                  .updateProjectSettings(slug,
                      paymentModes: [...project.paymentModes, v]),
              onDelete: (i) async => await AppState.instance
                  .updateProjectSettings(slug,
                      paymentModes: List<String>.from(project.paymentModes)
                        ..removeAt(i)),
              onEdit: (i, v) async {
                final updated = List<String>.from(project.paymentModes);
                updated[i] = v;
                await AppState.instance.updateProjectSettings(
                    slug, paymentModes: updated);
              },
            ),
            const SizedBox(height: 20),

            // ── Tags ─────────────────────────────────────
            _sectionHeader('Tags'),
            _listManagerTile(
              context,
              items: project.tags,
              onAdd: (v) async => await AppState.instance
                  .updateProjectSettings(slug,
                      tags: [...project.tags, v]),
              onDelete: (i) async => await AppState.instance
                  .updateProjectSettings(slug,
                      tags: List<String>.from(project.tags)
                        ..removeAt(i)),
              onEdit: (i, v) async {
                final updated = List<String>.from(project.tags);
                updated[i] = v;
                await AppState.instance.updateProjectSettings(
                    slug, tags: updated);
              },
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppTheme.text3, letterSpacing: 1.5),
    ),
  );

  Widget _settingTile(
    BuildContext context,
    String label,
    String value, {
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.text3,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.text)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.text3, size: 18),
          ]),
        ),
      );

  Widget _listManagerTile(
    BuildContext context, {
    required List<String> items,
    required Future<void> Function(String) onAdd,
    required Future<void> Function(int) onDelete,
    required Future<void> Function(int, String) onEdit,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(children: [
                ListTile(
                  dense: true,
                  title: Text(item,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.text)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          size: 16, color: AppTheme.text3),
                      onPressed: () =>
                          _editText(context, 'Edit', item, (v) => onEdit(i, v)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: AppTheme.red),
                      onPressed: () =>
                          _confirmDelete(context, item, () => onDelete(i)),
                    ),
                  ]),
                ),
                if (i < items.length - 1)
                  const Divider(height: 0, indent: 16),
              ]);
            }),
            // Add button
            InkWell(
              onTap: () => _editText(context, 'Add New', '', (v) => onAdd(v),
                  addMode: true),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: items.isNotEmpty
                      ? const Border(
                          top: BorderSide(color: AppTheme.border))
                      : null,
                  borderRadius: items.isEmpty
                      ? BorderRadius.circular(8)
                      : const BorderRadius.vertical(
                          bottom: Radius.circular(8)),
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.add_rounded,
                      size: 16, color: AppTheme.accent),
                  SizedBox(width: 6),
                  Text('Add',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.accent,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      );

  Future<void> _editText(
    BuildContext context,
    String label,
    String initial,
    Future<void> Function(String) onSave, {
    bool addMode = false,
  }) async {
    final ctrl = TextEditingController(text: addMode ? '' : initial);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.border)),
        title: Text(label,
            style: const TextStyle(
                color: AppTheme.text, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: AppTheme.accent, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.text2))),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await onSave(result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String item,
    VoidCallback onDelete,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.border)),
        title: const Text('Remove?',
            style: TextStyle(
                color: AppTheme.red, fontWeight: FontWeight.w700)),
        content: Text('Remove "$item"?',
            style:
                const TextStyle(color: AppTheme.text2, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.text2))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) onDelete();
  }
}
