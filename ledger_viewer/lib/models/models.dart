// lib/models/models.dart

class Project {
  String slug;
  String name;
  String icon;
  String description;
  String created;
  String? currency;
  List<String> categories;
  List<String> paymentModes;
  List<String> tags;
  int nextId;
  List<Expense> expenses;

  Project({
    required this.slug,
    required this.name,
    required this.icon,
    required this.description,
    required this.created,
    this.currency,
    required this.categories,
    required this.paymentModes,
    required this.tags,
    required this.nextId,
    required this.expenses,
  });

  factory Project.fromJson(String slug, Map<String, dynamic> json) {
    return Project(
      slug: slug,
      name: json['name'] ?? slug,
      icon: json['icon'] ?? '📁',
      description: json['description'] ?? '',
      created: json['created'] ?? '',
      currency: json['currency'],
      categories: List<String>.from(json['categories'] ?? []),
      paymentModes: List<String>.from(json['payment_modes'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      nextId: json['next_id'] ?? 1,
      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'description': description,
    'created': created,
    'currency': currency,
    'categories': categories,
    'payment_modes': paymentModes,
    'tags': tags,
    'next_id': nextId,
    'expenses': expenses.map((e) => e.toJson()).toList(),
  };

  String get effectiveCurrency => currency ?? '₹';

  // ── CRUD ───────────────────────────────────────────────

  Expense addExpense({
    required String category,
    required String vendor,
    required double amount,
    required String mode,
    required String description,
    required List<String> tags,
    required String date,
    String notes = '',
  }) {
    final e = Expense(
      id: nextId,
      category: category,
      vendor: vendor,
      amount: amount,
      mode: mode,
      description: description,
      tags: List<String>.from(tags),
      date: date,
      notes: notes,
    );
    nextId++;
    expenses.add(e);
    return e;
  }

  void updateExpense(Expense updated) {
    final idx = expenses.indexWhere((e) => e.id == updated.id);
    if (idx != -1) expenses[idx] = updated;
  }

  void deleteExpense(int id) {
    expenses.removeWhere((e) => e.id == id);
  }

  Expense? getById(int id) {
    try {
      return expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Expense> get sortedByDateDesc {
    final copy = List<Expense>.from(expenses);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  // ── Analytics ──────────────────────────────────────────

  double get total => expenses.fold(0, (s, e) => s + e.amount);
  double get cashTotal =>
      expenses.where((e) => e.mode == 'Cash').fold(0, (s, e) => s + e.amount);
  double get digitalTotal => total - cashTotal;
  double get avg => expenses.isEmpty ? 0 : total / expenses.length;

  Map<String, double> get categoryBreakdown {
    final m = <String, double>{};
    for (final e in expenses) m[e.category] = (m[e.category] ?? 0) + e.amount;
    final sorted = Map.fromEntries(
        m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return sorted;
  }

  Map<String, double> get vendorBreakdown {
    final m = <String, double>{};
    for (final e in expenses) m[e.vendor] = (m[e.vendor] ?? 0) + e.amount;
    final sorted = Map.fromEntries(
        m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return sorted;
  }

  Map<String, double> get modeBreakdown {
    final m = <String, double>{};
    for (final e in expenses) m[e.mode] = (m[e.mode] ?? 0) + e.amount;
    return m;
  }

  Map<String, double> get tagBreakdown {
    final m = <String, double>{};
    for (final e in expenses) {
      for (final t in e.tags) m[t] = (m[t] ?? 0) + e.amount;
    }
    final sorted = Map.fromEntries(
        m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return sorted;
  }

  Map<String, double> get dailyBreakdown {
    final m = <String, double>{};
    for (final e in expenses) m[e.date] = (m[e.date] ?? 0) + e.amount;
    final sorted = Map.fromEntries(
        m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return sorted;
  }
}

class Expense {
  final int id;
  String category;
  String vendor;
  double amount;
  String mode;
  String description;
  List<String> tags;
  String date;
  String notes;

  Expense({
    required this.id,
    required this.category,
    required this.vendor,
    required this.amount,
    required this.mode,
    required this.description,
    required this.tags,
    required this.date,
    required this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] ?? 0,
        category: json['category'] ?? '',
        vendor: json['vendor'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        mode: json['mode'] ?? '',
        description: json['description'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        date: json['date'] ?? '',
        notes: json['notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'vendor': vendor,
        'amount': amount,
        'mode': mode,
        'description': description,
        'tags': tags,
        'date': date,
        'notes': notes,
      };

  Expense copyWith({
    String? category,
    String? vendor,
    double? amount,
    String? mode,
    String? description,
    List<String>? tags,
    String? date,
    String? notes,
  }) =>
      Expense(
        id: id,
        category: category ?? this.category,
        vendor: vendor ?? this.vendor,
        amount: amount ?? this.amount,
        mode: mode ?? this.mode,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        date: date ?? this.date,
        notes: notes ?? this.notes,
      );
}
