// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/drive_service.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project>? _projects;
  String? _error;
  bool _loading = true;
  DateTime? _lastFetched;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final projects = await DriveService.instance.fetchAllProjects();
      setState(() {
        _projects = projects;
        _loading = false;
        _lastFetched = DateTime.now();
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatCurrency(String cur, double amount) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return '$cur${fmt.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = _projects?.fold(0.0, (s, p) => s + p.total) ?? 0;

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
            child: const Icon(Icons.book_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('Ledger'),
        ]),
        actions: [
          if (_lastFetched != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  'Updated ${_timeAgo(_lastFetched!)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.text3),
                ),
              ),
            ),
          IconButton(
            onPressed: _fetch,
            icon: _loading
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
        onRefresh: _fetch,
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        child: _buildBody(grandTotal),
      ),
    );
  }

  Widget _buildBody(double grandTotal) {
    if (_loading && _projects == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGrandTotalShimmer(),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ShimmerCard(),
          )),
        ],
      );
    }

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _fetch);
    }

    final projects = _projects ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Grand total card
        _buildGrandTotal(grandTotal, projects.length),
        const SizedBox(height: 20),

        // Projects list
        const SectionHeader('All Projects'),
        if (projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(children: [
              Icon(Icons.folder_open_rounded, size: 40, color: AppTheme.text3),
              SizedBox(height: 12),
              Text('No projects found on Drive',
                  style: TextStyle(color: AppTheme.text2, fontSize: 14)),
              SizedBox(height: 4),
              Text('Make sure LedgerJsons folder is shared with the service account',
                  style: TextStyle(color: AppTheme.text3, fontSize: 11),
                  textAlign: TextAlign.center),
            ]),
          )
        else
          ...projects.map((p) => _buildProjectCard(p)),

        const SizedBox(height: 20),

        // Pull to refresh hint
        const Center(
          child: Text('Pull down to refresh from Drive',
              style: TextStyle(fontSize: 11, color: AppTheme.text3)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('COMBINED TOTAL',
              style: TextStyle(fontSize: 10, color: AppTheme.text3,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text('₹${NumberFormat('#,##,##0.00', 'en_IN').format(total)}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                  color: AppTheme.accent, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text('across $count project${count == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: AppTheme.text2)),
        ]),
      ),
      const Icon(Icons.account_balance_wallet_rounded,
          size: 40, color: AppTheme.accent),
    ]),
  );

  Widget _buildGrandTotalShimmer() => Container(
    height: 90,
    decoration: BoxDecoration(
      color: AppTheme.surface2,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
  );

  Widget _buildProjectCard(Project p) {
    final pct = p.total > 0 ? '${NumberFormat('#,##0', 'en_IN').format(p.total)}' : '0';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectScreen(project: p)),
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
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(child: Text(p.icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.text)),
              const SizedBox(height: 2),
              Text('${p.expenses.length} entries · ${p.currency}$pct total',
                  style: const TextStyle(fontSize: 11, color: AppTheme.text2)),
            ]),
          ),
          // Arrow
          const Icon(Icons.chevron_right_rounded, color: AppTheme.text3),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
