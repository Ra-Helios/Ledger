// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  final String slug;
  const AnalyticsScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final project = AppState.instance.getProject(slug);
        if (project == null) return const SizedBox();
        final cur = project.effectiveCurrency; // uses effectiveCurrency not currency

        String fmt(double v) =>
            '$cur${NumberFormat('#,##0', 'en_IN').format(v)}';

        if (project.expenses.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.text3),
              SizedBox(height: 12),
              Text('No expenses yet',
                  style: TextStyle(color: AppTheme.text2)),
            ]),
          );
        }

        final total   = project.total;
        final cash    = project.cashTotal;
        final digital = project.digitalTotal;
        final avg     = project.avg;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats
            Row(children: [
              Expanded(child: StatCard(
                  label: 'Total', value: fmt(total),
                  color: AppTheme.accent,
                  sub: '${project.expenses.length} entries')),
              const SizedBox(width: 10),
              Expanded(child: StatCard(
                  label: 'Average', value: fmt(avg),
                  color: AppTheme.yellow, sub: 'per entry')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: StatCard(
                  label: 'Cash', value: fmt(cash),
                  color: AppTheme.green,
                  sub: total > 0
                      ? '${(cash / total * 100).toStringAsFixed(1)}%'
                      : '0%')),
              const SizedBox(width: 10),
              Expanded(child: StatCard(
                  label: 'Digital', value: fmt(digital),
                  color: AppTheme.purple,
                  sub: total > 0
                      ? '${(digital / total * 100).toStringAsFixed(1)}%'
                      : '0%')),
            ]),
            const SizedBox(height: 20),

            // Category doughnut
            const SectionHeader('Category Distribution'),
            _buildCategoryChart(project),
            const SizedBox(height: 20),

            // Category bars
            const SectionHeader('Category Breakdown'),
            _buildCard(_buildCategoryBars(project, cur)),
            const SizedBox(height: 20),

            // Mode cards
            const SectionHeader('Payment Modes'),
            _buildModeCards(project, cur),
            const SizedBox(height: 20),

            // Vendors
            const SectionHeader('Top Vendors'),
            _buildCard(_buildVendorList(project, cur)),
            const SizedBox(height: 20),

            // Tags
            if (project.tagBreakdown.isNotEmpty) ...[
              const SectionHeader('By Tag'),
              _buildCard(_buildTagList(project, cur)),
              const SizedBox(height: 20),
            ],

            // Daily
            if (project.dailyBreakdown.length > 1) ...[
              const SectionHeader('Daily Expenditure'),
              _buildDailyChart(project),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCard(Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: child,
  );

  Widget _buildCategoryChart(project) {
    final bd      = project.categoryBreakdown as Map<String, double>;
    if (bd.isEmpty) return const SizedBox();
    final total   = project.total as double;
    final entries = bd.entries.toList();
    return _buildCard(SizedBox(
      height: 240,
      child: Row(children: [
        Expanded(
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            sections: entries.asMap().entries.map((e) {
              final color = AppTheme.chartColors[
                  e.key % AppTheme.chartColors.length];
              final pct = total > 0 ? e.value.value / total * 100 : 0;
              return PieChartSectionData(
                color: color,
                value: e.value.value,
                title: '${pct.toStringAsFixed(0)}%',
                radius: 55,
                titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              );
            }).toList(),
          )),
        ),
        SizedBox(
          width: 130,
          child: ListView(
            shrinkWrap: true,
            children: entries.asMap().entries.map((e) {
              final color = AppTheme.chartColors[
                  e.key % AppTheme.chartColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(e.value.key,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.text2),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    ));
  }

  Widget _buildCategoryBars(project, String cur) {
    final bd    = project.categoryBreakdown as Map<String, double>;
    final total = project.total as double;
    return Column(
      children: bd.entries.toList().asMap().entries.map((e) => ProgressRow(
        label: e.value.key,
        amount: e.value.value,
        total: total,
        color: AppTheme.chartColors[e.key % AppTheme.chartColors.length],
        currency: cur,
      )).toList(),
    );
  }

  Widget _buildModeCards(project, String cur) {
    final bd  = project.modeBreakdown as Map<String, double>;
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Row(
      children: bd.entries.map((e) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: e.key == bd.keys.last ? 0 : 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: [
            ModeBadge(e.key),
            const SizedBox(height: 6),
            Text('$cur${fmt.format(e.value)}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppTheme.text, fontFamily: 'monospace')),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _buildVendorList(project, String cur) {
    final bd    = project.vendorBreakdown as Map<String, double>;
    final total = project.total as double;
    final fmt   = NumberFormat('#,##0', 'en_IN');
    return Column(
      children: bd.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(e.key,
              style: const TextStyle(fontSize: 12, color: AppTheme.text2),
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text('$cur${fmt.format(e.value)}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.accent, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Text('${(e.value / total * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.text3,
                  fontFamily: 'monospace')),
        ]),
      )).toList(),
    );
  }

  Widget _buildTagList(project, String cur) {
    final bd  = project.tagBreakdown as Map<String, double>;
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Column(
      children: bd.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          TagChip(e.key),
          const Spacer(),
          Text('$cur${fmt.format(e.value)}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.yellow, fontFamily: 'monospace')),
        ]),
      )).toList(),
    );
  }

  Widget _buildDailyChart(project) {
    final bd     = project.dailyBreakdown as Map<String, double>;
    final dates  = bd.keys.toList();
    final values = bd.values.toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return _buildCard(SizedBox(
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
              v >= 1000
                  ? '${(v / 1000).toStringAsFixed(0)}k'
                  : v.toStringAsFixed(0),
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
                    style: const TextStyle(
                        fontSize: 8, color: AppTheme.text3)),
              );
            },
          )),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
        minY: 0,
        maxY: maxVal * 1.15,
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
                radius: 3, color: AppTheme.accent, strokeWidth: 0),
          ),
        )],
      )),
    ));
  }
}
