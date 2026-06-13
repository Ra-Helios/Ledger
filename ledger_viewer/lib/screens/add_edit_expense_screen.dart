// lib/screens/add_edit_expense_screen.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final String slug;
  final Expense? expense; // null = add mode, non-null = edit mode

  const AddEditExpenseScreen(
      {super.key, required this.slug, this.expense});

  @override
  State<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState
    extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late TextEditingController _vendor;
  late TextEditingController _description;
  late TextEditingController _amount;
  late TextEditingController _notes;
  late TextEditingController _date;

  String _category = '';
  String _mode = '';
  List<String> _tags = [];

  bool get _editMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _vendor      = TextEditingController(text: e?.vendor ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _amount      = TextEditingController(
        text: e != null ? e.amount.toStringAsFixed(2) : '');
    _notes       = TextEditingController(text: e?.notes ?? '');
    _date        = TextEditingController(
        text: e?.date ?? DateTime.now().toIso8601String().split('T')[0]);
    _category    = e?.category ?? '';
    _mode        = e?.mode ?? '';
    _tags        = e != null ? List<String>.from(e.tags) : [];
  }

  @override
  void dispose() {
    _vendor.dispose(); _description.dispose();
    _amount.dispose(); _notes.dispose(); _date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) {
      _showError('Please select a category');
      return;
    }
    if (_mode.isEmpty) {
      _showError('Please select a payment mode');
      return;
    }
    setState(() => _saving = true);
    try {
      if (_editMode) {
        final updated = widget.expense!.copyWith(
          category: _category,
          vendor: _vendor.text.trim(),
          amount: double.parse(_amount.text),
          mode: _mode,
          description: _description.text.trim(),
          tags: _tags,
          date: _date.text,
          notes: _notes.text.trim(),
        );
        await AppState.instance.updateExpense(widget.slug, updated);
      } else {
        await AppState.instance.addExpense(
          widget.slug,
          category: _category,
          vendor: _vendor.text.trim(),
          amount: double.parse(_amount.text),
          mode: _mode,
          description: _description.text.trim(),
          tags: _tags,
          date: _date.text,
          notes: _notes.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.red,
    ));
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.surface2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _date.text =
            '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = AppState.instance.getProject(widget.slug)!;
    final cur = project.effectiveCurrency;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_editMode)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Text(
                  'Editing entry #${widget.expense!.id}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.accent),
                ),
              ),

            // Date
            _fieldLabel('Date'),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _date,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: _deco('YYYY-MM-DD',
                      suffix: const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppTheme.text3)),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Amount
            _fieldLabel('Amount ($cur)'),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              style: const TextStyle(color: AppTheme.text),
              decoration: _deco('0.00'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                if (double.parse(v) <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Category
            _fieldLabel('Category'),
            _dropdownField(
              value: _category.isEmpty ? null : _category,
              hint: 'Select category',
              items: project.categories,
              onChanged: (v) => setState(() => _category = v ?? ''),
            ),
            const SizedBox(height: 14),

            // Payment mode
            _fieldLabel('Payment Mode'),
            _dropdownField(
              value: _mode.isEmpty ? null : _mode,
              hint: 'Select mode',
              items: project.paymentModes,
              onChanged: (v) => setState(() => _mode = v ?? ''),
            ),
            const SizedBox(height: 14),

            // Vendor
            _fieldLabel('Vendor / Payee'),
            TextFormField(
              controller: _vendor,
              style: const TextStyle(color: AppTheme.text),
              decoration: _deco('Name of vendor, shop, contractor...'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Description
            _fieldLabel('Description'),
            TextFormField(
              controller: _description,
              style: const TextStyle(color: AppTheme.text),
              decoration: _deco('What was this expense for?'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Tags
            _fieldLabel('Tags'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: project.tags.map((tag) {
                final selected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag,
                      style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? AppTheme.accent
                              : AppTheme.text2)),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) { _tags.add(tag); }
                    else   { _tags.remove(tag); }
                  }),
                  backgroundColor: AppTheme.surface2,
                  selectedColor: AppTheme.accent.withOpacity(0.15),
                  checkmarkColor: AppTheme.accent,
                  side: BorderSide(
                    color: selected
                        ? AppTheme.accent.withOpacity(0.4)
                        : AppTheme.border,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Notes
            _fieldLabel('Notes (optional)'),
            TextFormField(
              controller: _notes,
              style: const TextStyle(color: AppTheme.text),
              decoration: _deco('Bill number, reference, extra detail...'),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.accent,
                ),
                child: Text(
                  _saving
                      ? 'Saving...'
                      : (_editMode ? 'Save Changes' : 'Add Expense'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppTheme.text3,
            letterSpacing: 0.8,
            decoration: TextDecoration.none)),
  );

  InputDecoration _deco(String hint, {Widget? suffix}) =>
      InputDecoration(hintText: hint, suffixIcon: suffix);

  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(
                  color: AppTheme.text3, fontSize: 13)),
          dropdownColor: AppTheme.surface2,
          underline: const SizedBox(),
          style: const TextStyle(color: AppTheme.text, fontSize: 13),
          items: items
              .map((v) =>
                  DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      );
}
