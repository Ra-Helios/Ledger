// lib/services/app_state.dart
//
// Central state holder. All screens read from and write to this.
// After every mutation it auto-pushes to Drive.

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'drive_service.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  List<Project> _projects = [];
  bool loading = false;
  bool pushing = false;
  String? error;
  DateTime? lastFetched;

  List<Project> get projects => _projects;

  Project? getProject(String slug) {
    try {
      return _projects.firstWhere((p) => p.slug == slug);
    } catch (_) {
      return null;
    }
  }

  // ── Fetch all from Drive ──────────────────────────────────

  Future<void> fetchAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _projects = await DriveService.instance.fetchAllProjects();
      lastFetched = DateTime.now();
      error = null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not_signed_in')) {
        error = 'Not signed in. Please sign in again.';
      } else {
        error = msg;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ── Auto-push after any mutation ─────────────────────────

  Future<void> _push(Project project) async {
    pushing = true;
    notifyListeners();
    try {
      await DriveService.instance.pushProject(project);
    } catch (_) {
      // Push failure is silent — data is safe locally in memory
      // User can use manual refresh to retry
    } finally {
      pushing = false;
      notifyListeners();
    }
  }

  // ── Expense mutations ─────────────────────────────────────

  Future<Expense> addExpense(String slug, {
    required String category,
    required String vendor,
    required double amount,
    required String mode,
    required String description,
    required List<String> tags,
    required String date,
    String notes = '',
  }) async {
    final project = getProject(slug)!;
    final expense = project.addExpense(
      category: category, vendor: vendor, amount: amount,
      mode: mode, description: description, tags: tags,
      date: date, notes: notes,
    );
    notifyListeners();
    await _push(project);
    return expense;
  }

  Future<void> updateExpense(String slug, Expense updated) async {
    final project = getProject(slug)!;
    project.updateExpense(updated);
    notifyListeners();
    await _push(project);
  }

  Future<void> deleteExpense(String slug, int id) async {
    final project = getProject(slug)!;
    project.deleteExpense(id);
    notifyListeners();
    await _push(project);
  }

  // ── Project settings mutations ────────────────────────────

  Future<void> updateProjectSettings(String slug, {
    String? name,
    String? icon,
    String? description,
    String? currency,
    List<String>? categories,
    List<String>? paymentModes,
    List<String>? tags,
  }) async {
    final project = getProject(slug)!;
    if (name != null)         project.name = name;
    if (icon != null)         project.icon = icon;
    if (description != null)  project.description = description;
    if (currency != null)     project.currency = currency.isEmpty ? null : currency;
    if (categories != null)   project.categories = categories;
    if (paymentModes != null) project.paymentModes = paymentModes;
    if (tags != null)         project.tags = tags;
    notifyListeners();
    await _push(project);
  }

  /// Reset state on sign-out
  void reset() {
    _projects = [];
    loading = false;
    pushing = false;
    error = null;
    lastFetched = null;
    notifyListeners();
  }
}
