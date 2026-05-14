// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override ConsumerState<DashboardScreen> createState() => _DS();
}

class _DS extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override void dispose()  { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user    = ref.watch(userProfileProvider).valueOrNull;
    final alerts  = ref.watch(activeAlertsProvider).valueOrNull ?? [];
    final summary = ref.watch(monthlyConsumptionProvider);
    final budget  = ref.watch(budgetAnalysisProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            floating: true, snap: true,
            backgroundColor: AppTheme.bgDark,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hola, ${user?.name.split(' ').first ?? 'Usuario'} 👋',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              Text(user?.isOwner ?? false ? '● Modo Propietario' : '● Modo Inquilino',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
            ]),
            actions: [
              Stack(children: [
                IconButton(icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.go('/alerts')),
                if (alerts.isNotEmpty) Positioned(right: 8, top: 8, child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppTheme.dangerRed, shape: BoxShape.circle),
                    child: Center(child: Text('${alerts.length}',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))))),
              ]),
            ],
            bottom: TabBar(
              controller: _tab,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(icon: Icon(Icons.bolt, size:18),       text: 'Energía'),
                Tab(icon: Icon(Icons.water_drop, size:18), text: 'Agua'),
                Tab(icon: Icon(Icons.local_fire_department, size:18), text: 'Gas'),
              ],
            ),
          ),
        ],
        body: TabBarView(controller: _tab, children: [
          _ServiceTab(service: ServiceType.electricity, summary: summary, budget: budget, user: user),
          _ServiceTab(service: ServiceType.water,       summary: summary, budget: budget, user: user),
          _ServiceTab(service: ServiceType.gas,         summary: summary, budget: budget, user: user),
        ]),
      ),
    );
  }
}

// ─── Pestaña por servicio ───────────────────────────────────────────────────
class _ServiceTab extends ConsumerWidget {
  const _ServiceTab({required this.service, required this.summary,
      required this.budget, required this.user});
  final ServiceType service;
  final AsyncValue<ConsumptionSummary> summary;
  final BudgetAnalysis budget;
  final UserProfile? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color  = _color(service);
    final icon   = _icon(service);
    final zones  = ref.watch(zonesProvider).valueOrNull ?? DemoData.zones;
    final apps   = ref.watch(appliancesProvider).valueOrNull ?? DemoData.appliances;
    final svcApps= apps.where((a) => a.service == service).toList()
      ..sort((a, b) => b.currentUsage.compareTo(a.currentUsage));
    final fmt    = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [

        // ── 1. Tarjeta resumen del mes ──────────────────────────────────────
        summary.when(
          data: (s) => _MonthCard(service: service, summary: s, color: color),
          loading: () => _SkeletonCard(height: 130),
          error: (_, __) => _MonthCard(
              service: service, summary: ConsumptionSummary.demo(), color: color),
        ).animate().fadeIn(),

        const SizedBox(height: 20),

        // ── 2. Gráfico 24h ──────────────────────────────────────────────────
        SectionHeader('Consumo últimas 24h'),
        const SizedBox(height: 10),
        _Chart24h(service: service).animate().fadeIn(delay: 80.ms),

        const SizedBox(height: 22),

        // ── 3. Consumo por zona ─────────────────────────────────────────────
        SectionHeader('Consumo por zona',
            action: () => context.go('/zones/${zones.first.id}'),
            actionLabel: 'Ver zonas →'),
        const SizedBox(height: 10),
        ...zones.map((z) => _ZoneTileForService(zone: z, service: service))
            .toList()
            .animate(interval: 40.ms)
            .fadeIn().slideX(begin: .05, end: 0),

        const SizedBox(height: 22),

        // ── 4. Consumo por electrodoméstico / punto ─────────────────────────
        SectionHeader('Consumo por ${_deviceLabel(service)}'),
        const SizedBox(height: 10),
        if (svcApps.isEmpty)
          const _Empty(msg: 'Sin dispositivos registrados')
        else
          ...svcApps.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ApplianceTile(appliance: a),
          )).toList()
              .animate(interval: 30.ms)
              .fadeIn().slideX(begin: .05, end: 0),

        const SizedBox(height: 22),

        // ── 5. Meta del usuario (presupuesto) ───────────────────────────────
        if (user?.isOwner ?? false) ...[
          SectionHeader('Meta mensual',
              action: () => _editBudget(context, ref, user!),
              actionLabel: 'Editar meta →'),
          const SizedBox(height: 10),
          _BudgetCard(budget: budget).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),

          // Recomendaciones del servicio actual
          ...budget.recommendations
              .where((r) => r.service == service)
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RecommendationTile(rec: r),
                  ))
              .toList()
              .animate(interval: 40.ms)
              .fadeIn(),
        ],
      ],
    );
  }

  void _editBudget(BuildContext ctx, WidgetRef ref, UserProfile user) {
    double tmp = user.monthlyBudget;
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: const Text('Meta mensual total (Bs.)'),
      content: StatefulBuilder(builder: (ctx2, set) => Column(mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ingresa cuánto deseas gastar al mes en todos los servicios.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: user.monthlyBudget.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Presupuesto (BOB)', prefixIcon: Icon(Icons.savings_outlined)),
            onChanged: (v) => tmp = double.tryParse(v) ?? tmp,
          ),
          const SizedBox(height: 12),
          Text('Gasto actual: Bs. ${ConsumptionSummary.demo().totalCost.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).updateBudget(user.uid, tmp);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Guardar'),
        ),
      ],
    ));
  }

  Color  _color(ServiceType s) {
    switch (s) {
      case ServiceType.electricity: return AppTheme.electricColor;
      case ServiceType.water:       return AppTheme.waterColor;
      case ServiceType.gas:         return AppTheme.gasColor;
    }
  }

  IconData _icon(ServiceType s) {
    switch (s) {
      case ServiceType.electricity: return Icons.bolt_rounded;
      case ServiceType.water:       return Icons.water_drop_rounded;
      case ServiceType.gas:         return Icons.local_fire_department_rounded;
    }
  }

  String _deviceLabel(ServiceType s) {
    switch (s) {
      case ServiceType.electricity: return 'electrodoméstico';
      case ServiceType.water:       return 'punto de consumo';
      case ServiceType.gas:         return 'aparato de gas';
    }
  }
}

// ─── Tarjeta resumen del mes ──────────────────────────────────────────────────
class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.service, required this.summary, required this.color});
  final ServiceType service; final ConsumptionSummary summary; final Color color;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
    final (val, unit, cost, label) = switch (service) {
      ServiceType.electricity => (summary.electricityKwh, 'kWh',
          fmt.format(summary.electricityCost), 'Electricidad consumida'),
      ServiceType.water => (summary.waterLiters, 'L',
          fmt.format(summary.waterCost), 'Agua consumida'),
      ServiceType.gas   => (summary.gasKg, 'kg GLP',
          fmt.format(summary.gasCost), 'Gas consumido'),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(.18), AppTheme.bgDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(children: [
        Container(width: 56, height: 56,
          decoration: BoxDecoration(color: color.withOpacity(.15), shape: BoxShape.circle),
          child: Icon(_sIcon(service), color: color, size: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          RichText(text: TextSpan(children: [
            TextSpan(text: val.toStringAsFixed(1),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 28)),
            TextSpan(text: '  $unit',
                style: TextStyle(color: color.withOpacity(.7), fontSize: 13)),
          ])),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('Costo est.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Text(cost, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(.12),
                borderRadius: BorderRadius.circular(6)),
            child: const Text('Este mes', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10))),
        ]),
      ]),
    );
  }

  IconData _sIcon(ServiceType s) {
    switch (s) {
      case ServiceType.electricity: return Icons.bolt_rounded;
      case ServiceType.water:       return Icons.water_drop_rounded;
      case ServiceType.gas:         return Icons.local_fire_department_rounded;
    }
  }
}

// ─── Gráfico 24h ──────────────────────────────────────────────────────────────
class _Chart24h extends ConsumerWidget {
  const _Chart24h({required this.service});
  final ServiceType service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _c(service);
    return ref.watch(hourlySeriesProvider(service)).when(
      data: (pts) {
        if (pts.isEmpty) return const _Empty(msg: 'Sin datos de las últimas 24h');
        final spots = pts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
        final maxY  = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        final minY  = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
        return Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(4, 12, 12, 6),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.06))),
          child: LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false,
                horizontalInterval: ((maxY - minY) / 3).clamp(.01, double.infinity),
                getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 6,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}h',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: minY * .85, maxY: maxY * 1.1,
            lineBarsData: [LineChartBarData(
              spots: spots, isCurved: true, curveSmoothness: .3,
              color: color, barWidth: 2.5, isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  colors: [color.withOpacity(.22), color.withOpacity(0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            )],
            lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.bgCardLight,
              getTooltipItems: (s) => s.map((p) => LineTooltipItem(p.y.toStringAsFixed(2),
                  TextStyle(color: color, fontWeight: FontWeight.bold))).toList(),
            )),
          )),
        );
      },
      loading: () => _SkeletonCard(height: 160),
      error: (_, __) => const _Empty(msg: 'Error cargando datos'),
    );
  }
  Color _c(ServiceType s) {
    switch(s) {
      case ServiceType.electricity: return AppTheme.electricColor;
      case ServiceType.water:       return AppTheme.waterColor;
      case ServiceType.gas:         return AppTheme.gasColor;
    }
  }
}

// ─── Zona para servicio ───────────────────────────────────────────────────────
class _ZoneTileForService extends StatelessWidget {
  const _ZoneTileForService({required this.zone, required this.service});
  final IoTZone zone; final ServiceType service;

  @override
  Widget build(BuildContext context) {
    final color = _c(service);
    final val   = switch (service) {
      ServiceType.electricity => zone.currentKw     != null ? '${zone.currentKw!.toStringAsFixed(2)} kW'    : null,
      ServiceType.water       => zone.currentLpm    != null ? '${zone.currentLpm!.toStringAsFixed(1)} L/min' : null,
      ServiceType.gas         => zone.currentPpm    != null ? '${zone.currentPpm!.toStringAsFixed(0)} ppm'   : null,
    };
    final monthly = switch (service) {
      ServiceType.electricity => zone.monthlyKwh > 0   ? '${zone.monthlyKwh.toStringAsFixed(1)} kWh/mes' : null,
      ServiceType.water       => zone.monthlyLiters > 0? '${zone.monthlyLiters.toStringAsFixed(0)} L/mes' : null,
      ServiceType.gas         => zone.monthlyGasKg > 0 ? '${zone.monthlyGasKg.toStringAsFixed(2)} kg/mes' : null,
    };
    if (val == null && monthly == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => context.go('/zones/${zone.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: zone.alertLevel != AlertLevel.none
              ? zone.alertColor.withOpacity(.3) : Colors.white.withOpacity(.06)),
        ),
        child: Row(children: [
          Text(zone.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(zone.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
            if (monthly != null)
              Text(monthly, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
          if (val != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
            child: Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: zone.alertColor, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: zone.alertColor.withOpacity(.4), blurRadius: 4)])),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }

  Color _c(ServiceType s) {
    switch (s) {
      case ServiceType.electricity: return AppTheme.electricColor;
      case ServiceType.water:       return AppTheme.waterColor;
      case ServiceType.gas:         return AppTheme.gasColor;
    }
  }
}

// ─── Electrodoméstico tile ───────────────────────────────────────────────────
class _ApplianceTile extends StatelessWidget {
  const _ApplianceTile({required this.appliance});
  final Appliance appliance;

  @override
  Widget build(BuildContext context) {
    final c    = appliance.isOverLimit ? AppTheme.dangerRed : appliance.serviceColor;
    final fmt  = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
    final pct  = appliance.usagePct.clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => context.go('/appliances/${appliance.id}'),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.withOpacity(appliance.isOverLimit ? .45 : .18),
              width: appliance.isOverLimit ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(appliance.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(appliance.name, style: TextStyle(
                    color: appliance.isOverLimit ? AppTheme.dangerRed : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600, fontSize: 13)),
                if (appliance.isAnomaly) ...[
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.dangerRed.withOpacity(.15),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('⚠ ANOMALÍA',
                        style: TextStyle(color: AppTheme.dangerRed, fontSize: 9, fontWeight: FontWeight.bold))),
                ],
              ]),
              Text(appliance.zoneName,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: .4)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${appliance.currentUsage.toStringAsFixed(2)} ${appliance.unitLabel}',
                  style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(appliance.isOn ? '● Activo' : '○ Inactivo',
                  style: TextStyle(
                      color: appliance.isOn ? AppTheme.primaryGreen : AppTheme.textSecondary,
                      fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 10),
          // Barra de uso
          ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(c))),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Límite: ${appliance.normalMax.toStringAsFixed(2)} ${appliance.unitLabel}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            Text(appliance.isOverLimit
                ? '${((appliance.usagePct - 1) * 100).toStringAsFixed(0)}% sobre límite'
                : '${(pct * 100).toStringAsFixed(0)}% del límite',
                style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Promedio diario: ${appliance.dailyAvg.toStringAsFixed(1)} ${appliance.unitLabel}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            Text(fmt.format(appliance.monthlyCost) + '/mes',
                style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Presupuesto card ─────────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});
  final BudgetAnalysis budget;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
    final over = budget.isOverBudget;
    final color = over ? AppTheme.dangerRed : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Meta mensual', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text(fmt.format(budget.budget),
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(over ? 'Excedido' : 'Disponible',
                style: TextStyle(color: color, fontSize: 11)),
            Text(fmt.format(budget.remaining.abs()),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: budget.progressPct.clamp(0.0, 1.0), minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
          )),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Gasto actual: ${fmt.format(budget.currentSpend)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Text('${(budget.progressPct * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ]),
        if (budget.totalPotentialSaving > 0) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(.08), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.trending_down_rounded, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  'Siguiendo las recomendaciones puedes ahorrar hasta '
                  '${fmt.format(budget.totalPotentialSaving)}/mes',
                  style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12))),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─── Recomendación tile ───────────────────────────────────────────────────────
class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.rec});
  final BudgetRecommendation rec;

  @override
  Widget build(BuildContext context) {
    final color = rec.service == ServiceType.electricity ? AppTheme.electricColor
        : rec.service == ServiceType.water ? AppTheme.waterColor : AppTheme.gasColor;
    final icon  = rec.service == ServiceType.electricity ? Icons.bolt_rounded
        : rec.service == ServiceType.water ? Icons.water_drop_rounded : Icons.local_fire_department_rounded;
    final fmt   = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
    final badge = rec.priority == 1 ? 'PRIORIDAD ALTA' : rec.priority == 2 ? 'MEDIA' : 'BAJA';
    final bCol  = rec.priority == 1 ? AppTheme.dangerRed
        : rec.priority == 2 ? AppTheme.warningAmber : AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.05), borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(rec.applianceName,
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: bCol.withOpacity(.15),
                  borderRadius: BorderRadius.circular(5)),
              child: Text(badge, style: TextStyle(color: bCol,
                  fontSize: 9, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 6),
        Text(rec.action, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.savings_outlined, color: AppTheme.primaryGreen, size: 14),
          const SizedBox(width: 5),
          Text('Ahorro potencial: ${fmt.format(rec.potentialSaving)}/mes',
              style: const TextStyle(color: AppTheme.primaryGreen,
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;
  @override
  Widget build(BuildContext _) => Container(height: height,
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)))
      .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds, color: Colors.white10);
}

class _Empty extends StatelessWidget {
  const _Empty({required this.msg});
  final String msg;
  @override
  Widget build(BuildContext _) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.inbox_rounded, color: AppTheme.textSecondary),
      const SizedBox(width: 10),
      Text(msg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]),
  );
}
