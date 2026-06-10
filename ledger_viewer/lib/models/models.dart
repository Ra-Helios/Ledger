// lib/models/models.dart

class Project {
  final String slug;
  final String name;
  final String icon;
  final String description;
  final String created;
  final String currency;
  final List<String> categories;
  final List<String> paymentModes;
  final List<String> tags;
  final int nextId;
  final List<Expense> expenses;

  Project({
    required this.slug,
    required this.name,
    required this.icon,
    required this.description,
    required this.created,
    required this.currency,
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
      currency: json['currency'] ?? '₹',
      categories: List<String>.from(json['categories'] ?? []),
      paymentModes: List<String>.from(json['payment_modes'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      nextId: json['next_id'] ?? 1,
      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Analytics ──────────────────────────────────────────

  double get total => expenses.fold(0, (s, e) => s + e.amount);
  double get cashTotal => expenses.where((e) => e.mode == 'Cash').fold(0, (s, e) => s + e.amount);
  double get digitalTotal => total - cashTotal;
  double get avg => expenses.isEmpty ? 0 : total / expenses.length;

  Map<String, double> get categoryBreakdown {
    final m = <String, double>{};
    for (final e in expenses) {
      m[e.category] = (m[e.category] ?? 0) + e.amount;
    }
    final sorted = Map.fromEntries(
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  Map<String, double> get vendorBreakdown {
    final m = <String, double>{};
    for (final e in expenses) {
      m[e.vendor] = (m[e.vendor] ?? 0) + e.amount;
    }
    final sorted = Map.fromEntries(
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  Map<String, double> get modeBreakdown {
    final m = <String, double>{};
    for (final e in expenses) {
      m[e.mode] = (m[e.mode] ?? 0) + e.amount;
    }
    return m;
  }

  Map<String, double> get tagBreakdown {
    final m = <String, double>{};
    for (final e in expenses) {
      for (final t in e.tags) {
        m[t] = (m[t] ?? 0) + e.amount;
      }
    }
    final sorted = Map.fromEntries(
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  Map<String, double> get dailyBreakdown {
    final m = <String, double>{};
    for (final e in expenses) {
      m[e.date] = (m[e.date] ?? 0) + e.amount;
    }
    final sorted = Map.fromEntries(
      m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  Map<String, double> get monthlyBreakdown {
    final m = <String, double>{};
    for (final e in expenses) {
      final month = e.date.length >= 7 ? e.date.substring(0, 7) : e.date;
      m[month] = (m[month] ?? 0) + e.amount;
    }
    final sorted = Map.fromEntries(
      m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }
}

class Expense {
  final int id;
  final String category;
  final String vendor;
  final double amount;
  final String mode;
  final String description;
  final List<String> tags;
  final String date;
  final String notes;

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

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
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
  }
}
