import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../services/incident_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/industrial_tokens.dart';
import '../../widgets/admin_dashboard/activity_timeline.dart';
import '../../widgets/admin_dashboard/circular_gauge.dart';
import '../../widgets/admin_dashboard/critical_incident_card.dart';
import '../../widgets/admin_dashboard/dashboard_charts.dart';
import '../../widgets/admin_dashboard/kpi_card.dart';
import '../../widgets/admin_dashboard/technician_podium.dart';
import '../../widgets/app_top_bar.dart';
import 'admin_dashboard_metrics.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with TickerProviderStateMixin {
  late AnimationController _pulse;
  bool _intlReady = false;
  final IncidentService _incidentService = IncidentService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    initializeDateFormatting('fr_FR', null).then((_) {
      if (mounted) setState(() => _intlReady = true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _dateLine() {
    final now = DateTime.now();
    if (!_intlReady) {
      return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(now);
  }

  Future<void> _onRefresh() async {
    await FirebaseFirestore.instance.collection('incidents').get();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?.trim();
    final firstName =
        (display != null && display.isNotEmpty)
            ? display.split(RegExp(r'\s+')).first
            : null;
    final em = user?.email;
    final emailLocal =
        (em != null && em.contains('@')) ? em.split('@').first : null;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        final urgentCount =
            snapshot.hasData
                ? AdminDashboardMetrics.fromDocs(snapshot.data!.docs).unassignedOpen
                : 0;

        PreferredSizeWidget appBar = AppTopBar(
          title: 'Espace Administrateur',
          actionsPrefix: [
            _DashboardUrgentBadge(count: urgentCount, pulse: _pulse),
            const SizedBox(width: 4),
          ],
        );

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: appBar,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur incidents : ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.statRed),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: appBar,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final metrics = AdminDashboardMetrics.fromDocs(docs);
        final total = metrics.total == 0 ? 1 : metrics.total;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppTopBar(
            title: 'Tableau de bord',
            actionsPrefix: [
              _DashboardUrgentBadge(count: metrics.unassignedOpen, pulse: _pulse),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surfaceElevated,
            displacement: 64,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.background,
                            AppColors.surfaceElevated.withValues(alpha: 0.88),
                          ],
                        ),
                        border: Border.all(color: AppColors.borderMuted),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}${(firstName != null && firstName.isNotEmpty) ? ', $firstName' : (emailLocal != null && emailLocal.isNotEmpty) ? ', $emailLocal' : ''}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dateLine(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AnimatedUrgentBanner(count: metrics.unassignedOpen),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _sectionTitle('Indicateurs clés', 'Vue opérationnelle'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildListDelegate.fixed([
                      DashboardKpiCard(
                        icon: Icons.dashboard_rounded,
                        label: 'Total incidents',
                        value: '${metrics.total}',
                        progress: (metrics.total / (total + 20)).clamp(0.0, 1.0),
                        accent: AppColors.statBlue,
                      ),
                      DashboardKpiCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Résolus',
                        value: '${metrics.resolved}',
                        progress: metrics.resolved / total,
                        accent: AppColors.statGreen,
                      ),
                      DashboardKpiCard(
                        icon: Icons.hourglass_top_rounded,
                        label: 'En cours',
                        value: '${metrics.inProgress}',
                        progress: metrics.inProgress / total,
                        accent: AppColors.statOrange,
                      ),
                      DashboardKpiCard(
                        icon: Icons.person_off_rounded,
                        label: 'Non affectés',
                        value: '${metrics.unassignedOpen}',
                        progress: metrics.unassignedOpen / total,
                        accent: AppColors.statRed,
                      ),
                      DashboardKpiCard(
                        icon: Icons.fact_check_rounded,
                        label: 'En validation',
                        value: '${metrics.pendingValidation}',
                        progress: metrics.pendingValidation / total,
                        accent: AppColors.statPurple,
                      ),
                      DashboardKpiCard(
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        label: 'Satisfaction',
                        value: '${metrics.satisfactionIndex}%',
                        progress: metrics.satisfactionIndex / 100,
                        accent: AppColors.accent,
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                    child: _sectionTitle('Performance', 'Résolution & délais'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.borderMuted),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: DashboardCircularGauge(
                              label: 'Taux de résolution',
                              valueFraction: (metrics.resolutionRatePercent / 100).clamp(0.0, 1.0),
                              centerLabel: '${metrics.resolutionRatePercent.round()}%',
                              subLabel: 'fermés / total',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 120,
                            color: AppColors.border.withValues(alpha: 0.4),
                          ),
                          Expanded(
                            child: DashboardCircularGauge(
                              label: 'Temps moyen résolution',
                              valueFraction: _avgHoursFraction(metrics.averageResolutionHours),
                              centerLabel: _avgHoursLabel(metrics.averageResolutionHours),
                              subLabel: 'heures',
                              progressColor: AppColors.statBlue,
                              trackColor: AppColors.border,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: _sectionTitle('Répartition par type', 'Donut interactif'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _chartShell(
                      child: IncidentTypeDonutChart(metrics: metrics),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: _sectionTitle('Volume — 7 derniers jours', 'Histogramme'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _chartShell(
                      child: IncidentsLast7DaysBarChart(metrics: metrics),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: _sectionTitle('Tendance — 30 jours', 'Courbe d’activité'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _chartShell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              'Incidents créés par jour (cumul visuel)',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IncidentsSparkline30d(metrics: metrics),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: _sectionTitle('Top techniciens', 'Podium & classement'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _incidentService.watchTechnicians(),
                      builder: (context, techSnap) {
                        final raw = techSnap.data?.docs ?? [];
                        final sorted = [...raw]..sort((a, b) {
                          final sa = (a.data()['score'] as num?)?.toInt() ?? 0;
                          final sb = (b.data()['score'] as num?)?.toInt() ?? 0;
                          return sb.compareTo(sa);
                        });
                        return _chartShell(
                          child: TechnicianPodium(
                            technicians: sorted,
                            metrics: metrics,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: _sectionTitle('Incidents critiques récents', 'Priorité élevée'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: metrics.criticalRecent.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Aucun incident critique enregistré.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : Column(
                            children: metrics.criticalRecent
                                .map((d) => DashboardCriticalIncidentTile(doc: d))
                                .toList(),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: _sectionTitle('Activité récente', 'Fil des événements'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: user?.uid == null
                        ? const Text(
                            'Connectez-vous pour voir les notifications.',
                            style: TextStyle(color: AppColors.textMuted),
                          )
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _notificationService.watchForUser(user!.uid),
                            builder: (context, nSnap) {
                              if (nSnap.hasError) {
                                return Text(
                                  'Notifications : ${nSnap.error}',
                                  style: const TextStyle(color: AppColors.statRed),
                                );
                              }
                              final items = NotificationService.sortedNotificationDocs(
                                nSnap.data,
                              ).take(14).toList();
                              return _chartShell(
                                child: DashboardActivityTimeline(docs: items),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static double _avgHoursFraction(double? hours) {
    if (hours == null || hours <= 0) return 0;
    return (hours / 72).clamp(0.0, 1.0);
  }

  static String _avgHoursLabel(double? hours) {
    if (hours == null || hours <= 0) return '—';
    if (hours < 1) return '${(hours * 60).round()}m';
    return hours >= 100 ? '${hours.round()}h' : '${hours.toStringAsFixed(1)}h';
  }

  static Widget _chartShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderMuted),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }

  static Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Badge « incidents non affectés » (animation) — couleurs alignées sur [IndustrialTokens].
class _DashboardUrgentBadge extends StatelessWidget {
  const _DashboardUrgentBadge({
    required this.count,
    required this.pulse,
  });

  final int count;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: IndustrialTokens.statRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: IndustrialTokens.statRed.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: IndustrialTokens.statRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: IndustrialTokens.statRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bannière urgente + animation d’entrée lorsque [count] > 0.
class _AnimatedUrgentBanner extends StatefulWidget {
  const _AnimatedUrgentBanner({required this.count});

  final int count;

  @override
  State<_AnimatedUrgentBanner> createState() => _AnimatedUrgentBannerState();
}

class _AnimatedUrgentBannerState extends State<_AnimatedUrgentBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    if (widget.count > 0) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _c.forward());
    }
  }

  @override
  void didUpdateWidget(_AnimatedUrgentBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count == 0 && widget.count > 0) {
      _c.forward(from: 0);
    } else if (oldWidget.count > 0 && widget.count == 0) {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.urgentBanner,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.urgentBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.statRed.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.75, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (context, v, child) {
                    return Opacity(
                      opacity: 0.35 + 0.65 * v,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.statRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.count} incident(s) non affecté(s) — Action requise',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
