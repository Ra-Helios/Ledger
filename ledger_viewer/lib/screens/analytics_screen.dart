// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  final Project project;
  const AnalyticsScreen({super.key, required this.project});

  String get cur => project.currency;
  String _fmt(double v) => '$cur${NumberFormat('#,##0', 'en_IN').format(v)}';
  String _fmtFull(double v) => '$cur${NumberFormat('#,##0.00', 'en_IN').format(v)}';

  @override
  Widget build(BuildContext context) {
    if (project.expenses.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.text3),
          SizedBox(height: 12),
          Text('No expenses yet', style: TextStyle(color: AppTheme.text2)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary Stats ──────────────────────────────────
        _buildStats(),
        const SizedBox(height: 20),

        // ── Category Doughnut ──────────────────────────────
        const SectionHeader('Category Distribution'),
        _buildCategoryChart(),
        const SizedBox(height: 20),

        // ── Category Progress Bars ─────────────────────────
        const SectionHeader('Category Breakdown'),
        _buildCard(_buildCategoryBars()),
        const SizedBox(height: 20),

        // ── Payment Modes ──────────────────────────────────
        const SectionHeader('Payment Modes'),
        _buildModeCards(),
        const SizedBox(height: 20),

        // ── Vendor Breakdown ───────────────────────────────
        const SectionHeader('Top Vendors'),
        _buildCard(_buildVendorList()),
        const SizedBox(height: 20),

        // ── Tag Breakdown ──────────────────────────────────
        if (project.tagBreakdown.isNotEmpty) ...[
          const SectionHeader('By Tag'),
          _buildCard(_buildTagList()),
          const SizedBox(height: 20),
        ],

        // ── Daily Timeline ─────────────────────────────────
        if (project.dailyBreakdown.length > 1) ...[
          const SectionHeader('Daily Expenditure'),
          _buildDailyChart(),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────

  Widget _buildStats() {
    final total   = project.total;
    final cash    = project.cashTotal;
    final digital = project.digitalTotal;
    final avg     = project.avg;
    final cashPct = total > 0 ? '${(cash / total * 100).toStringAsFixed(1)}%' : '0%';
    final digPct  = total > 0 ? '${(digital / total * 100).toStringAsFixed(1)}%' : '0%';

    return Column(children: [
      Row(children: [
        Expanded(child: StatCard(
          label: 'Total Spent',
          value: _fmt(total),
          color: AppTheme.accent,
          sub: '${project.expenses.length} entries',
        )),
        const SizedBox(width: 10),
        Expanded(child: StatCard(
          label: 'Average',
          value: _fmt(avg),
          color: AppTheme.yellow,
          sub: 'per entry',
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: StatCard(
          label: 'Cash',
          value: _fmt(cash),
          color: AppTheme.green,
          sub: cashPct,
        )),
        const SizedBox(width: 10),
        Expanded(child: StatCard(
          label: 'Digital',
          value: _fmt(digital),
          color: AppTheme.purple,
          sub: digPct,
        )),
      ]),
    ]);
  }

  // ── Category doughnut chart ────────────────────────────────

  Widget _buildCategoryChart() {
    final bd = project.categoryBreakdown;
    if (bd.isEmpty) return const SizedBox();
    final total = project.total;
    final entries = bd.entries.toList();

    return _buildCard(
      SizedBox(
        height: 240,
        child: Row(children: [
          // Pie
          Expanded(
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: entries.asMap().entries.map((e) {
                final color = AppTheme.chartColors[e.key % AppTheme.chartColors.length];
                final pct = total > 0 ? e.value.value / total * 100 : 0;
                return PieChartSectionData(
                  color: color,
                  value: e.value.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 55,
                  titleStyle: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                );
              }).toList(),
            )),
          ),
          // Legend
          SizedBox(
            width: 130,
            child: ListView(
              shrinkWrap: true,
              children: entries.asMap().entries.map((e) {
                final color = AppTheme.chartColors[e.key % AppTheme.chartColors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.value.key,
                        style: const TextStyle(fontSize: 10, color: AppTheme.text2),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Category progress bars ─────────────────────────────────

  Widget _buildCategoryBars() {
    final bd    = project.categoryBreakdown;
    final total = project.total;
    final colors = AppTheme.chartColors;
    return Column(
      children: bd.entries.toList().asMap().entries.map((e) => ProgressRow(
        label: e.value.key,
        amount: e.value.value,
        total: total,
        color: colors[e.key % colors.length],
        currency: cur,
      )).toList(),
    );
  }

  // ── Mode cards ─────────────────────────────────────────────

  Widget _buildModeCards() {
    final bd = project.modeBreakdown;
    return Row(
      children: bd.entries.map((e) => Expanded(
        child: Container(
          margin: EdgeInsets.only(
              right: e.key == bd.keys.last ? 0 : 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: [
            ModeBadge(e.key),
            const SizedBox(height: 6),
            Text(_fmt(e.value), style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppTheme.text, fontFamily: 'monospace')),
          ]),
        ),
      )).toList(),
    );
  }

  // ── Vendor list ────────────────────────────────────────────

  Widget _buildVendorList() {
    final bd    = project.vendorBreakdown;
    final total = project.total;
    return Column(
      children: bd.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(e.key,
              style: const TextStyle(fontSize: 12, color: AppTheme.text2),
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(_fmt(e.value), style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppTheme.accent, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Text('${(e.value / total * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 10, color: AppTheme.text3,
                  fontFamily: 'monospace')),
        ]),
      )).toList(),
    );
  }

  // ── Tag list ───────────────────────────────────────────────

  Widget _buildTagList() {
    final bd = project.tagBreakdown;
    return Column(
      children: bd.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          TagChip(e.key),
          const Spacer(),
          Text(_fmt(e.value), style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppTheme.yellow, fontFamily: 'monospace')),
        ]),
      )).toList(),
    );
  }

  // ── Daily line chart ───────────────────────────────────────

  Widget _buildDailyChart() {
    final bd = project.dailyBreakdown;
    final dates  = bd.keys.toList();
    final values = bd.values.toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return _buildCard(
      SizedBox(
        height: 200,
        child: LineChart(LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppTheme.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                v >= 1000 ? '${(v/1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9, color: AppTheme.text3),
              ),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (dates.length / 4).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= dates.length) return const SizedBox();
                final d = dates[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(d.length >= 10 ? d.substring(5) : d,
                      style: const TextStyle(fontSize: 8, color: AppTheme.text3)),
                );
              },
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: (dates.length - 1).toDouble(),
          minY: 0, maxY: maxVal * 1.15,
          lineBarsData: [LineChartBarData(
            spots: values.asMap().entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: AppTheme.accent,
            barWidth: 2.5,
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withOpacity(0.08),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.accent,
                strokeWidth: 0,
              ),
            ),
          )],
        )),
      ),
    );
  }

  // ── Card wrapper ───────────────────────────────────────────

  Widget _buildCard(Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: child,
  );
}
