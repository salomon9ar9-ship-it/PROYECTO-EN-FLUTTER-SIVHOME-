// lib/screens/zones/zone_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class ZoneDetailScreen extends ConsumerWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});
  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zonesProvider).valueOrNull ?? DemoData.zones;
    final zone  = zones.firstWhere((z) => z.id == zoneId,
        orElse: () => DemoData.zones.first);
    final apps  = ref.watch(appliancesByZoneProvider(zoneId));
    final actuators = ref.watch(actuatorProvider);
    final fmt   = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop()),
        title: Text(zone.name),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Header zona
          GlassCard(child: Row(children: [
            Text(zone.icon, style: const TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                  color: AppTheme.textPrimary)),
              Row(children: [
                OnlineDot(online: zone.isActive),
                const SizedBox(width: 6),
                Text(zone.isActive ? 'Activa' : 'Inactiva',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Costo mensual est.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text(fmt.format(zone.monthlyCost),
                  style: const TextStyle(color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ])).animate().fadeIn(),

          const SizedBox(height: 16),

          // Sensores en tiempo real
          Row(children: [
            if (zone.currentKw != null)
              Expanded(child: _SensorTile(label:'Electricidad',
                  value:'${zone.currentKw!.toStringAsFixed(2)} kW',
                  color:AppTheme.electricColor, icon:Icons.bolt_rounded)),
            if (zone.currentKw != null && (zone.currentLpm != null || zone.currentPpm != null))
              const SizedBox(width: 8),
            if (zone.currentLpm != null)
              Expanded(child: _SensorTile(label:'Agua',
                  value:'${zone.currentLpm!.toStringAsFixed(1)} L/min',
                  color:AppTheme.waterColor, icon:Icons.water_drop_rounded)),
            if (zone.currentLpm != null && zone.currentPpm != null) const SizedBox(width: 8),
            if (zone.currentPpm != null)
              Expanded(child: _SensorTile(label:'Gas',
                  value:'${zone.currentPpm!.toStringAsFixed(0)} ppm',
                  color:AppTheme.gasColor, icon:Icons.local_fire_department_rounded)),
          ]).animate().fadeIn(delay: 80.ms),

          const SizedBox(height: 20),

          // Electrodomésticos de esta zona
          const SectionHeader('Dispositivos en esta zona'),
          const SizedBox(height: 10),

          if (apps.isEmpty)
            const _ZoneEmpty()
          else
            ...apps.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ZoneApplianceTile(appliance: a),
            )).toList().animate(interval: 40.ms).fadeIn().slideX(begin: .05, end: 0),

          const SizedBox(height: 20),

          // Control de actuadores de la zona
          const SectionHeader('Control de dispositivos'),
          const SizedBox(height: 10),
          _ActuatorGroup(zoneId: zoneId, actuators: actuators, ref: ref)
              .animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({required this.label, required this.value,
      required this.color, required this.icon});
  final String label, value; final Color color; final IconData icon;
  @override
  Widget build(BuildContext _) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    ]),
  );
}

class _ZoneApplianceTile extends StatelessWidget {
  const _ZoneApplianceTile({required this.appliance});
  final Appliance appliance;
  @override
  Widget build(BuildContext context) {
    final c   = appliance.isOverLimit ? AppTheme.dangerRed : appliance.serviceColor;
    final pct = appliance.usagePct.clamp(0.0, 1.0);
    final fmt = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
    return GestureDetector(
      onTap: () => context.go('/appliances/${appliance.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.withOpacity(.06), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(appliance.isOverLimit ? .4 : .16))),
        child: Row(children: [
          Text(appliance.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appliance.name, style: TextStyle(
                color: appliance.isOverLimit ? AppTheme.dangerRed : AppTheme.textPrimary,
                fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 5),
            UsageBar(value: appliance.currentUsage, max: appliance.normalMax, color: c),
            const SizedBox(height: 3),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${appliance.currentUsage.toStringAsFixed(2)} ${appliance.unitLabel}',
                  style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
              Text(fmt.format(appliance.monthlyCost) + '/mes',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }
}

class _ActuatorGroup extends StatelessWidget {
  const _ActuatorGroup({required this.zoneId, required this.actuators, required this.ref});
  final String zoneId; final Map<String, bool> actuators; final WidgetRef ref;
  @override
  Widget build(BuildContext _) {
    final keys = actuators.keys.where((k) => k.startsWith(zoneId)).toList();
    if (keys.isEmpty) {
      return GlassCard(child: const Text('No hay actuadores en esta zona.',
          style: TextStyle(color: AppTheme.textSecondary)));
    }
    return Column(children: keys.map((k) {
      final label = k.split('/').last.replaceAll('_', ' ').toUpperCase();
      final isOn  = actuators[k] ?? false;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(.06))),
        child: Row(children: [
          Icon(Icons.power_settings_new_rounded,
              color: isOn ? AppTheme.primaryGreen : AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary))),
          Switch.adaptive(value: isOn, onChanged: (v) =>
              ref.read(actuatorProvider.notifier).toggle(k, v),
              activeColor: AppTheme.primaryGreen),
        ]),
      );
    }).toList());
  }
}

class _ZoneEmpty extends StatelessWidget {
  const _ZoneEmpty();
  @override
  Widget build(BuildContext _) => GlassCard(
    child: const Row(children: [
      Icon(Icons.devices_other_rounded, color: AppTheme.textSecondary),
      SizedBox(width: 10),
      Text('Sin dispositivos registrados en esta zona.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]),
  );
}
