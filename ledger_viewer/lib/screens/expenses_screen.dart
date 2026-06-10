// lib/screens/expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class ExpensesScreen extends StatefulWidget {
  final Project project;
  const ExpensesScreen({super.key, required this.project});

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

  List<Expense> get _filtered {
    var list = widget.project.expenses.toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
        e.description.toLowerCase().contains(q) ||
        e.vendor.toLowerCase().contains(q) ||
        e.category.toLowerCase().contains(q) ||
        e.notes.toLowerCase().contains(q)
      ).toList();
    }
    if (_filterCat.isNotEmpty)  list = list.where((e) => e.category == _filterCat).toList();
    if (_filterMode.isNotEmpty) list = list.where((e) => e.mode == _filterMode).toList();
    if (_filterTag.isNotEmpty)  list = list.where((e) => e.tags.contains(_filterTag)).toList();

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

  String _fmt(double v) {
    final cur = widget.project.currency;
    return '$cur${NumberFormat('#,##0.00', 'en_IN').format(v)}';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilters() {
    final p = widget.project;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Filters & Sort',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppTheme.text)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterCat = ''; _filterMode = ''; _filterTag = '';
                      _sort = 'date_desc';
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Clear all',
                      style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 14),

              // Category
              _filterLabel('Category'),
              _dropdownRow(
                value: _filterCat,
                items: ['', ...p.categories],
                label: (v) => v.isEmpty ? 'All' : v,
                onChanged: (v) { setState(() => _filterCat = v!); setModal(() {}); },
              ),
              const SizedBox(height: 10),

              // Mode
              _filterLabel('Payment Mode'),
              _dropdownRow(
                value: _filterMode,
                items: ['', ...p.paymentModes],
                label: (v) => v.isEmpty ? 'All' : v,
                onChanged: (v) { setState(() => _filterMode = v!); setModal(() {}); },
              ),
              const SizedBox(height: 10),

              // Tag
              _filterLabel('Tag'),
              _dropdownRow(
                value: _filterTag,
                items: ['', ...p.tags],
                label: (v) => v.isEmpty ? 'All' : v,
                onChanged: (v) { setState(() => _filterTag = v!); setModal(() {}); },
              ),
              const SizedBox(height: 10),

              // Sort
              _filterLabel('Sort by'),
              _dropdownRow(
                value: _sort,
                items: ['date_desc','date_asc','amount_desc','amount_asc','id_desc','id_asc'],
                label: (v) => {
                  'date_desc': 'Date ↓ (newest)',
                  'date_asc':  'Date ↑ (oldest)',
                  'amount_desc': 'Amount ↓',
                  'amount_asc':  'Amount ↑',
                  'id_desc': 'Entry # ↓',
                  'id_asc':  'Entry # ↑',
                }[v]!,
                onChanged: (v) { setState(() => _sort = v!); setModal(() {}); },
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(t, style: const TextStyle(fontSize: 10, color: AppTheme.text3,
        fontWeight: FontWeight.w700, letterSpacing: 1)),
  );

  Widget _dropdownRow<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppTheme.surface2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: DropdownButton<T>(
      value: value,
      isExpanded: true,
      dropdownColor: AppTheme.surface2,
      underline: const SizedBox(),
      style: const TextStyle(color: AppTheme.text, fontSize: 13),
      items: items.map((v) => DropdownMenuItem(
        value: v,
        child: Text(label(v)),
      )).toList(),
      onChanged: onChanged,
    ),
  );

  bool get _hasActiveFilters =>
      _filterCat.isNotEmpty || _filterMode.isNotEmpty ||
      _filterTag.isNotEmpty || _sort != 'date_desc';

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = filtered.fold(0.0, (s, e) => s + e.amount);

    return Column(children: [
      // ── Search + filter bar ──────────────────────────────
      Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppTheme.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search vendor, description...',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppTheme.text3),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 16, color: AppTheme.text3),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: _hasActiveFilters,
            backgroundColor: AppTheme.accent,
            child: IconButton(
              onPressed: _showFilters,
              icon: const Icon(Icons.tune_rounded, color: AppTheme.text2),
              tooltip: 'Filter & Sort',
            ),
          ),
        ]),
      ),

      // ── Summary strip ────────────────────────────────────
      Container(
        color: AppTheme.surface2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(children: [
          Text('${filtered.length} entries',
              style: const TextStyle(fontSize: 11, color: AppTheme.text3)),
          const Spacer(),
          Text('Total: ',
              style: const TextStyle(fontSize: 11, color: AppTheme.text3)),
          Text(_fmt(total), style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppTheme.yellow, fontFamily: 'monospace')),
        ]),
      ),
      const Divider(height: 0),

      // ── List ─────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.inbox_rounded, size: 40, color: AppTheme.text3),
                  const SizedBox(height: 10),
                  Text(
                    _search.isNotEmpty || _hasActiveFilters
                        ? 'No entries match your filters'
                        : 'No expenses in this project',
                    style: const TextStyle(color: AppTheme.text2, fontSize: 13),
                  ),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 0, indent: 16, endIndent: 16),
                itemBuilder: (_, i) => _buildExpenseTile(filtered[i]),
              ),
      ),
    ]);
  }

  Widget _buildExpenseTile(Expense e) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ID badge
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Text('${e.id}', style: const TextStyle(
              fontSize: 10, color: AppTheme.text3,
              fontFamily: 'monospace', fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(width: 12),

      // Main info
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Vendor + amount
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(e.vendor, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.text)),
            ),
            const SizedBox(width: 8),
            Text(_fmt(e.amount), style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppTheme.yellow, fontFamily: 'monospace')),
          ]),
          const SizedBox(height: 3),

          // Description
          Text(e.description,
              style: const TextStyle(fontSize: 12, color: AppTheme.text2)),

          if (e.notes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('📝 ${e.notes}',
                style: const TextStyle(fontSize: 10, color: AppTheme.text3)),
          ],

          const SizedBox(height: 6),

          // Badges row
          Row(children: [
            Text(e.date, style: const TextStyle(
                fontSize: 10, color: AppTheme.text3, fontFamily: 'monospace')),
            const SizedBox(width: 8),
            CatBadge(e.category),
            const SizedBox(width: 4),
            ModeBadge(e.mode),
            const SizedBox(width: 4),
            ...e.tags.map((t) => TagChip(t)),
          ]),
        ]),
      ),
    ]),
  );
}
