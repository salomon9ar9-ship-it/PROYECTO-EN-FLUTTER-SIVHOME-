// lib/screens/zones/appliance_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';  // ✅ AGREGADO: Para context.pop()
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class ApplianceDetailScreen extends ConsumerWidget {
  const ApplianceDetailScreen({super.key, required this.appId});
  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(appliancesProvider).valueOrNull ?? DemoData.appliances;
    final a   = all.firstWhere((x) => x.id == appId,
        orElse: () => DemoData.appliances.first);
    final c   = a.isOverLimit ? AppTheme.dangerRed : a.serviceColor;
    final fmt = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
    final pct = a.usagePct.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop()),  // ✅ Ahora funciona con el import de go_router
        title: Text(a.name),
        actions: [
          Container(margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: (a.isOn ? AppTheme.primaryGreen : AppTheme.textSecondary).withOpacity(.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(a.isOn ? '● Activo' : '○ Apagado',
                style: TextStyle(
                    color: a.isOn ? AppTheme.primaryGreen : AppTheme.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Header
          GlassCard(
            borderColor: c.withOpacity(.3),
            color: c.withOpacity(.05),
            child: Row(children: [
              Text(a.icon, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
                Text('Zona: ${a.zoneName}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  Text(_svcLabel(a.service),
                      style: TextStyle(color: a.serviceColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (a.isAnomaly) ...[
                    const SizedBox(width: 8),
                    const BadgeLabel('ANOMALÍA DETECTADA', color: AppTheme.dangerRed),
                  ],
                ]),
              ])),
            ]),
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          // Consumo actual
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Consumo en tiempo real',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(a.currentUsage.toStringAsFixed(2),
                  style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 38)),
              const SizedBox(width: 6),
              Padding(padding: const EdgeInsets.only(bottom: 6),
                  child: Text(a.unitLabel, style: TextStyle(color: c.withOpacity(.7), fontSize: 16))),
            ]),
            const SizedBox(height: 10),
            UsageBar(value: a.currentUsage, max: a.alertThreshold, color: c, height: 10),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Normal ≤ ${a.normalMax.toStringAsFixed(2)} ${a.unitLabel}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text('Alerta > ${a.alertThreshold.toStringAsFixed(2)} ${a.unitLabel}',
                  style: const TextStyle(color: AppTheme.warningAmber, fontSize: 11)),
            ]),
            if (a.isOverLimit) ...[
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.dangerRed.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dangerRed.withOpacity(.3))),
                child: Row(children: [
                  const Icon(Icons.warning_rounded, color: AppTheme.dangerRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Consumo ${((a.usagePct - 1) * 100).toStringAsFixed(0)}% sobre '
                    'el límite normal. Revisa el dispositivo.',
                    style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12))),
                ]),
              ),
            ],
          ])).animate().fadeIn(delay: 80.ms),

          const SizedBox(height: 14),

          // Estadísticas
          Row(children: [
            Expanded(child: GlassCard(child: Column(children: [
              const Icon(Icons.today_rounded, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(height: 6),
              Text('${a.dailyAvg.toStringAsFixed(1)} ${a.unitLabel}',
                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Promedio diario', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  textAlign: TextAlign.center),
            ]))),
            const SizedBox(width: 10),
            Expanded(child: GlassCard(child: Column(children: [
              const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(height: 6),
              Text('${a.monthlyAccum.toStringAsFixed(0)} ${a.service == ServiceType.electricity ? 'kWh' : a.service == ServiceType.water ? 'L' : 'uso'}',
                  style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Acumulado mes', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  textAlign: TextAlign.center),
            ]))),
            const SizedBox(width: 10),
            Expanded(child: GlassCard(child: Column(children: [
              const Icon(Icons.savings_rounded, color: AppTheme.warningAmber, size: 20),
              const SizedBox(height: 6),
              Text(fmt.format(a.monthlyCost),
                  style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis),
              const Text('Costo/mes', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  textAlign: TextAlign.center),
            ]))),
          ]).animate().fadeIn(delay: 120.ms),

          const SizedBox(height: 14),

          // Recomendación específica
          GlassCard(
            borderColor: AppTheme.primaryGreen.withOpacity(.2),
            color: AppTheme.primaryGreen.withOpacity(.04),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primaryGreen, size: 18),
                SizedBox(width: 8),
                Text('Recomendación del sistema IA',
                    style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(_rec(a), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 8),
              Text('Confianza del modelo: ${_conf(a)}%',
                  style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ).animate().fadeIn(delay: 160.ms),
        ],
      ),
    );
  }

  String _svcLabel(ServiceType s) {
    switch (s) {
      case ServiceType.electricity: return 'ELECTRICIDAD';
      case ServiceType.water:       return 'AGUA';
      case ServiceType.gas:         return 'GAS';
    }
  }

  String _rec(Appliance a) {
    if (a.isAnomaly) {
      return 'Isolation Forest detectó un patrón anómalo en este '
          'dispositivo. Consumo fuera del rango histórico esperado. '
          'Se recomienda inspección física inmediata.';
    }
    if (a.isOverLimit) {
      return 'El consumo actual supera el umbral normal. Considera '
          'apagarlo temporalmente o reducir el tiempo de uso diario para '
          'mantenerse dentro de la meta mensual.';
    }
    return 'El consumo está dentro del rango normal. '
        'Continúa con los patrones de uso actuales para mantenerte '
        'dentro del presupuesto mensual establecido.';
  }

  String _conf(Appliance a) {
    if (a.isAnomaly) return '89';
    if (a.isOverLimit) return '84';
    return '93';
  }
}