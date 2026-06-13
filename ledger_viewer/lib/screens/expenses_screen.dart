// lib/screens/expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'add_edit_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final String slug;
  const ExpensesScreen({super.key, required this.slug});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _search = '';
  String _filterCat = '';
  String _filterMode = '';
  String _filterTag = '';
  String _sort = 'date_desc';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Expense> _filtered(List<Expense> expenses) {
    var list = List<Expense>.from(expenses);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
          e.description.toLowerCase().contains(q) ||
          e.vendor.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.notes.toLowerCase().contains(q)).toList();
    }
    if (_filterCat.isNotEmpty)
      list = list.where((e) => e.category == _filterCat).toList();
    if (_filterMode.isNotEmpty)
      list = list.where((e) => e.mode == _filterMode).toList();
    if (_filterTag.isNotEmpty)
      list = list.where((e) => e.tags.contains(_filterTag)).toList();

    switch (_sort) {
      case 'date_asc':    list.sort((a, b) => a.date.compareTo(b.date));
      case 'date_desc':   list.sort((a, b) => b.date.compareTo(a.date));
      case 'amount_asc':  list.sort((a, b) => a.amount.compareTo(b.amount));
      case 'amount_desc': list.sort((a, b) => b.amount.compareTo(a.amount));
      case 'id_asc':      list.sort((a, b) => a.id.compareTo(b.id));
      case 'id_desc':     list.sort((a, b) => b.id.compareTo(a.id));
    }
    return list;
  }

  bool get _hasFilters =>
      _filterCat.isNotEmpty || _filterMode.isNotEmpty ||
      _filterTag.isNotEmpty || _sort != 'date_desc';

  void _showFilters(project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.border),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Text('Filter & Sort',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppTheme.text)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterCat = ''; _filterMode = '';
                    _filterTag = ''; _sort = 'date_desc';
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Clear all',
                    style: TextStyle(
                        color: AppTheme.accent, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),
            _filterDrop('Category', _filterCat,
                ['', ...project.categories],
                (v) { setState(() => _filterCat = v!); setModal(() {}); }),
            const SizedBox(height: 8),
            _filterDrop('Mode', _filterMode,
                ['', ...project.paymentModes],
                (v) { setState(() => _filterMode = v!); setModal(() {}); }),
            const SizedBox(height: 8),
            _filterDrop('Tag', _filterTag,
                ['', ...project.tags],
                (v) { setState(() => _filterTag = v!); setModal(() {}); }),
            const SizedBox(height: 8),
            _filterDrop('Sort', _sort,
                ['date_desc','date_asc','amount_desc','amount_asc','id_desc','id_asc'],
                (v) { setState(() => _sort = v!); setModal(() {}); },
                label: (v) => {
                  'date_desc': 'Date ↓', 'date_asc': 'Date ↑',
                  'amount_desc': 'Amount ↓', 'amount_asc': 'Amount ↑',
                  'id_desc': 'Entry # ↓', 'id_asc': 'Entry # ↑',
                }[v]!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done')),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _filterDrop(String label, String value, List<String> items,
      ValueChanged<String?> onChanged, {String Function(String)? label_fn}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          fontSize: 10, color: AppTheme.text3,
          fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surface2,
          underline: const SizedBox(),
          style: const TextStyle(color: AppTheme.text, fontSize: 13),
          items: items.map((v) => DropdownMenuItem(
            value: v,
            child: Text(label_fn != null
                ? label_fn(v)
                : (v.isEmpty ? 'All' : v)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    ]);

  Future<void> _confirmDelete(
      BuildContext context, String slug, Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.border)),
        title: const Text('Delete Expense?',
            style: TextStyle(
                color: AppTheme.red, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${e.description}" from ${e.vendor}?\nThis cannot be undone.',
          style: const TextStyle(color: AppTheme.text2, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.text2))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AppState.instance.deleteExpense(slug, e.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final project = AppState.instance.getProject(widget.slug);
        if (project == null) return const SizedBox();
        final cur = project.effectiveCurrency;
        final fmt = NumberFormat('#,##0.00', 'en_IN');
        final filtered = _filtered(project.sortedByDateDesc);
        final total = filtered.fold(0.0, (s, e) => s + e.amount);

        return Column(children: [
          // Search + filter bar
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(
                      color: AppTheme.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AppTheme.text3),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 16, color: AppTheme.text3),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            })
                        : null,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Badge(
                isLabelVisible: _hasFilters,
                backgroundColor: AppTheme.accent,
                child: IconButton(
                  onPressed: () => _showFilters(project),
                  icon: const Icon(Icons.tune_rounded,
                      color: AppTheme.text2),
                ),
              ),
            ]),
          ),

          // Summary strip
          Container(
            color: AppTheme.surface2,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 7),
            child: Row(children: [
              Text('${filtered.length} entries',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.text3)),
              const Spacer(),
              Text('$cur${fmt.format(total)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppTheme.yellow,
                      fontFamily: 'monospace')),
            ]),
          ),
          const Divider(height: 0),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      const Icon(Icons.inbox_rounded,
                          size: 40, color: AppTheme.text3),
                      const SizedBox(height: 10),
                      Text(
                        _search.isNotEmpty || _hasFilters
                            ? 'No entries match'
                            : 'No expenses yet',
                        style: const TextStyle(
                            color: AppTheme.text2,
                            fontSize: 13),
                      ),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 0, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) =>
                        _buildTile(context, filtered[i], cur),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _buildTile(BuildContext context, Expense e, String cur) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    return Dismissible(
      key: Key('expense_${e.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.red.withOpacity(0.15),
        child: const Icon(Icons.delete_rounded, color: AppTheme.red),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(context, widget.slug, e);
        return false; // we handle deletion ourselves
      },
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Text('${e.id}',
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.text3,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600)),
          ),
        ),
        title: Row(children: [
          Expanded(
            child: Text(e.vendor,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.text)),
          ),
          Text('$cur${fmt.format(e.amount)}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppTheme.yellow, fontFamily: 'monospace')),
        ]),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const SizedBox(height: 2),
          Text(e.description,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.text2)),
          if (e.notes.isNotEmpty)
            Text('📝 ${e.notes}',
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.text3)),
          const SizedBox(height: 4),
          Row(children: [
            Text(e.date,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.text3,
                    fontFamily: 'monospace')),
            const SizedBox(width: 6),
            CatBadge(e.category),
            const SizedBox(width: 4),
            ModeBadge(e.mode),
            const SizedBox(width: 4),
            ...e.tags.take(2).map((t) => TagChip(t)),
          ]),
        ]),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditExpenseScreen(
                slug: widget.slug, expense: e),
          ),
        ),
        onLongPress: () => _confirmDelete(context, widget.slug, e),
      ),
    );
  }
}
