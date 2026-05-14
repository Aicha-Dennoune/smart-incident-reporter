import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../screens/admin/admin_dashboard_metrics.dart';
import '../../theme/app_colors.dart';

class IncidentTypeDonutChart extends StatelessWidget {
  const IncidentTypeDonutChart({super.key, required this.metrics});

  final AdminDashboardMetrics metrics;

  static String _label(String code) {
    switch (code) {
      case 'Electricite':
        return 'Électricité';
      case 'Mecanique':
        return 'Mécanique';
      case 'Autre':
        return 'Autre';
      default:
        return code;
    }
  }

  static Color _color(String type) {
    switch (type) {
      case 'IT':
        return AppColors.chartIt;
      case 'Electricite':
        return AppColors.chartElectricite;
      case 'Mecanique':
        return AppColors.chartMecanique;
      case 'Eau':
        return AppColors.chartEau;
      case 'Autre':
        return AppColors.textMuted;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = metrics.countsByType;
    final typedSum = counts.values.fold<int>(0, (a, b) => a + b);
    final total = metrics.total;
    final other = (total - typedSum).clamp(0, 9999999);
    final entries =
        AdminDashboardMetrics.typesOrder
            .map((t) => MapEntry(t, counts[t] ?? 0))
            .where((e) => e.value > 0)
            .toList();
    if (other > 0) {
      entries.add(MapEntry('Autre', other));
    }

    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Aucune donnée',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '$total incident(s) — types non catégorisés',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final sections =
        entries.map((e) {
          return PieChartSectionData(
            color: _color(e.key),
            value: e.value.toDouble(),
            title: '',
            radius: 52,
            badgeWidget: const SizedBox.shrink(),
            titlePositionPercentageOffset: 0.55,
          );
        }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 56,
                  sections: sections,
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                  const Text(
                    'incidents',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children:
              entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _color(e.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_label(e.key)} (${e.value})',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ],
    );
  }
}

class IncidentsLast7DaysBarChart extends StatefulWidget {
  const IncidentsLast7DaysBarChart({super.key, required this.metrics});

  final AdminDashboardMetrics metrics;

  @override
  State<IncidentsLast7DaysBarChart> createState() => _IncidentsLast7DaysBarChartState();
}

class _IncidentsLast7DaysBarChartState extends State<IncidentsLast7DaysBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  int? _touched;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
  }

  @override
  void didUpdateWidget(IncidentsLast7DaysBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.metrics.incidentsLast7Days;
    final maxY = buckets.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 9999).toDouble();
    final now = DateTime.now();
    final fmt = DateFormat.E('fr_FR');

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_c.value);
          return BarChart(
            BarChartData(
              maxY: maxY * 1.15,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, m) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (i, m) {
                      final day = now.subtract(Duration(days: 6 - i.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          fmt.format(day),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceHighlight,
                  tooltipPadding: const EdgeInsets.all(10),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    final v = buckets[idx];
                    final day = now.subtract(Duration(days: 6 - idx));
                    return BarTooltipItem(
                      '${DateFormat.yMd('fr_FR').format(day)}\n',
                      const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: '$v incident(s)',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (e, r) {
                  setState(() {
                    _touched = r?.spot?.touchedBarGroupIndex;
                  });
                },
              ),
              barGroups: List.generate(7, (i) {
                final v = buckets[i] * t;
                final touched = _touched == i;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: v,
                      width: touched ? 16 : 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.barGradientStart,
                          AppColors.barGradientEnd,
                        ],
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY * 1.15,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class IncidentsSparkline30d extends StatefulWidget {
  const IncidentsSparkline30d({super.key, required this.metrics});

  final AdminDashboardMetrics metrics;

  @override
  State<IncidentsSparkline30d> createState() => _IncidentsSparkline30dState();
}

class _IncidentsSparkline30dState extends State<IncidentsSparkline30d>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void didUpdateWidget(IncidentsSparkline30d oldWidget) {
    super.didUpdateWidget(oldWidget);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.metrics.incidentsLast30DaysSparkline;
    final maxV = raw.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 99999);
    final spots = <FlSpot>[];
    for (var i = 0; i < raw.length; i++) {
      spots.add(FlSpot(i.toDouble(), raw[i].toDouble()));
    }

    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_c.value);
          final animatedSpots = spots.map((s) => FlSpot(s.x, s.y * t)).toList();
          return LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              minY: 0,
              maxY: maxV * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: animatedSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  barWidth: 2,
                  color: AppColors.sparklineLine,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.sparklineLine.withValues(alpha: 0.35),
                        AppColors.sparklineFill,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
