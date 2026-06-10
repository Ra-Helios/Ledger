// lib/widgets/widgets.dart

import 'package:flutter/material.dart';
import '../theme.dart';

// ── Section header ────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: AppTheme.text3, letterSpacing: 1.5,
      ),
    ),
  );
}

// ── Stat card — uses Stack to overlay left accent bar cleanly ──

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? sub;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Stack(children: [
      // Card body
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
                fontSize: 10, color: AppTheme.text3,
                fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: color, fontFamily: 'monospace')),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!, style: const TextStyle(
                  fontSize: 11, color: AppTheme.text2)),
            ],
          ],
        ),
      ),
      // Left accent bar on top via Positioned
      Positioned(
        left: 0, top: 0, bottom: 0,
        child: Container(width: 3, color: color),
      ),
    ]),
  );
}

// ── Mode badge ────────────────────────────────────────────────

class ModeBadge extends StatelessWidget {
  final String mode;
  const ModeBadge(this.mode, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = modeColor(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: modeColorBg(mode),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(mode, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: color, fontFamily: 'monospace',
      )),
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────

class TagChip extends StatelessWidget {
  final String tag;
  const TagChip(this.tag, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    margin: const EdgeInsets.only(right: 3),
    decoration: BoxDecoration(
      color: AppTheme.surface3,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: AppTheme.border),
    ),
    child: Text(tag, style: const TextStyle(
      fontSize: 9, color: AppTheme.text2, fontFamily: 'monospace',
    )),
  );
}

// ── Category badge ────────────────────────────────────────────

class CatBadge extends StatelessWidget {
  final String category;
  const CatBadge(this.category, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.accent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
    ),
    child: Text(category, style: const TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: AppTheme.accent,
    )),
  );
}

// ── Progress bar row ──────────────────────────────────────────

class ProgressRow extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final String currency;

  const ProgressRow({
    super.key,
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.text2))),
            Text('$currency${_fmt(amount)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.text,
                    fontFamily: 'monospace', fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppTheme.surface3,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 2),
          Text('${(pct * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 9, color: AppTheme.text3)),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ── Error view ────────────────────────────────────────────────

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.text3),
        const SizedBox(height: 16),
        const Text('Could not load data', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.text)),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.text2),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ]),
    ),
  );
}

// ── Loading shimmer card ──────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppTheme.surface2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
  );
}
