// lib/screens/project_screen.dart

import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'analytics_screen.dart';
import 'expenses_screen.dart';
import 'project_settings_screen.dart';
import 'add_edit_expense_screen.dart';

class ProjectScreen extends StatefulWidget {
  final String slug;
  const ProjectScreen({super.key, required this.slug});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final project = AppState.instance.getProject(widget.slug);
        if (project == null) {
          return const Scaffold(
            body: Center(child: Text('Project not found')));
        }
        final pushing = AppState.instance.pushing;
        final onExpensesTab = _tabs.index == 1;

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            title: Row(children: [
              Text(project.icon,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(project.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              if (pushing)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.accent),
                  ),
                ),
            ]),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppTheme.accent,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.text3,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: AppTheme.border,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Expenses'),
                Tab(text: 'Settings'),
              ],
            ),
          ),
          // FAB only on Expenses tab
          floatingActionButton: onExpensesTab
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditExpenseScreen(
                          slug: widget.slug),
                    ),
                  ),
                  backgroundColor: AppTheme.accent,
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white),
                )
              : null,
          body: TabBarView(
            controller: _tabs,
            children: [
              AnalyticsScreen(slug: widget.slug),
              ExpensesScreen(slug: widget.slug),
              ProjectSettingsScreen(slug: widget.slug),
            ],
          ),
        );
      },
    );
  }
}
