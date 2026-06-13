// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-fetch on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState.instance.fetchAll();
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final projects = state.projects;
        final grandTotal =
            projects.fold(0.0, (s, p) => s + p.total);

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            title: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.book_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('Ledger'),
              if (state.pushing) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.accent),
                ),
              ],
            ]),
            actions: [
              if (state.lastFetched != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _timeAgo(state.lastFetched!),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.text3),
                    ),
                  ),
                ),
              IconButton(
                onPressed: state.loading ? null : state.fetchAll,
                icon: state.loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh from Drive',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: state.fetchAll,
            color: AppTheme.accent,
            backgroundColor: AppTheme.surface,
            child: _buildBody(state, projects, grandTotal),
          ),
        );
      },
    );
  }

  Widget _buildBody(AppState state, projects, double grandTotal) {
    if (state.loading && projects.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _shimmerTotal(),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ShimmerCard(),
          )),
        ],
      );
    }

    if (state.error != null && projects.isEmpty) {
      return ErrorView(
          message: state.error!, onRetry: state.fetchAll);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGrandTotal(grandTotal, projects.length),
        const SizedBox(height: 20),
        const SectionHeader('Projects'),
        if (projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(children: [
              Icon(Icons.folder_open_rounded,
                  size: 40, color: AppTheme.text3),
              SizedBox(height: 12),
              Text('No projects found on Drive',
                  style:
                      TextStyle(color: AppTheme.text2, fontSize: 14)),
            ]),
          )
        else
          ...projects.map((p) => _buildProjectCard(p)),
        const SizedBox(height: 16),
        const Center(
          child: Text('Pull down to refresh from Drive',
              style:
                  TextStyle(fontSize: 11, color: AppTheme.text3)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGrandTotal(double total, int count) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.surface, AppTheme.accent.withOpacity(0.05)],
      ),
    ),
    child: Row(children: [
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('COMBINED TOTAL',
              style: TextStyle(
                  fontSize: 10, color: AppTheme.text3,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(
            '₹${NumberFormat('#,##,##0.00', 'en_IN').format(total)}',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: AppTheme.accent, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 2),
          Text('across $count project${count == 1 ? '' : 's'}',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.text2)),
        ]),
      ),
      const Icon(Icons.account_balance_wallet_rounded,
          size: 40, color: AppTheme.accent),
    ]),
  );

  Widget _shimmerTotal() => Container(
    height: 90,
    decoration: BoxDecoration(
      color: AppTheme.surface2,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
  );

  Widget _buildProjectCard(p) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProjectScreen(slug: p.slug)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
                child: Text(p.icon,
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(p.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text)),
              const SizedBox(height: 2),
              Text(
                '${p.expenses.length} entries · ${p.effectiveCurrency}${fmt.format(p.total)} total',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.text2)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.text3),
        ]),
      ),
    );
  }
}
