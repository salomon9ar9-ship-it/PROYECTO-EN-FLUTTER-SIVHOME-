// lib/providers/iot_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';
import 'auth_provider.dart';

// ── ZONAS ────────────────────────────────────────────────────────────────────
final zonesProvider = StreamProvider<List<IoTZone>>((ref) {
  return FirebaseDatabase.instance.ref('zones').onValue.map((e) {
    final v = e.snapshot.value;
    if (v == null) return DemoData.zones;
    final map = Map<String, dynamic>.from(v as Map);
    return map.entries.map((entry) {
      final d = Map<String, dynamic>.from(entry.value as Map);
      return IoTZone(
        id: entry.key, name: d['name'] ?? entry.key, icon: d['icon'] ?? '🏠',
        isActive: d['isActive'] ?? true,
        alertLevel: AlertLevel.values.firstWhere(
            (a) => a.name == (d['alertLevel'] ?? 'none'), orElse: () => AlertLevel.none),
        currentKw:     (d['currentKw']     as num?)?.toDouble(),
        currentLpm:    (d['currentLpm']    as num?)?.toDouble(),
        currentPpm:    (d['currentPpm']    as num?)?.toDouble(),
        monthlyKwh:    (d['monthlyKwh']    as num?)?.toDouble() ?? 0,
        monthlyLiters: (d['monthlyLiters'] as num?)?.toDouble() ?? 0,
        monthlyGasKg:  (d['monthlyGasKg']  as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }).handleError((_) => DemoData.zones);
});

// ── ELECTRODOMÉSTICOS ─────────────────────────────────────────────────────────
final appliancesProvider = StreamProvider<List<Appliance>>((ref) {
  return FirebaseDatabase.instance.ref('appliances').onValue.map((e) {
    if (e.snapshot.value == null) return DemoData.appliances;
    final map = Map<String, dynamic>.from(e.snapshot.value as Map);
    return map.entries.map((entry) {
      final d = Map<String, dynamic>.from(entry.value as Map);
      return Appliance(
        id: entry.key, zoneId: d['zoneId'] ?? '', zoneName: d['zoneName'] ?? '',
        name: d['name'] ?? entry.key, icon: d['icon'] ?? '🔌',
        service: ServiceType.values.firstWhere(
            (s) => s.name == d['service'], orElse: () => ServiceType.electricity),
        currentUsage:   (d['currentUsage']   as num?)?.toDouble() ?? 0,
        normalMax:      (d['normalMax']      as num?)?.toDouble() ?? 1,
        alertThreshold: (d['alertThreshold'] as num?)?.toDouble() ?? 2,
        isOn: d['isOn'] ?? false,
        dailyAvg:     (d['dailyAvg']     as num?)?.toDouble() ?? 0,
        monthlyAccum: (d['monthlyAccum'] as num?)?.toDouble() ?? 0,
        isAnomaly: d['isAnomaly'] ?? false,
      );
    }).toList();
  }).handleError((_) => DemoData.appliances);
});

// Filtrar por zona
final appliancesByZoneProvider =
    Provider.family<List<Appliance>, String>((ref, zoneId) {
  return ref.watch(appliancesProvider).valueOrNull?.where((a) => a.zoneId == zoneId).toList()
      ?? DemoData.appliances.where((a) => a.zoneId == zoneId).toList();
});

// Filtrar por servicio
final appliancesByServiceProvider =
    Provider.family<List<Appliance>, ServiceType>((ref, svc) {
  return ref.watch(appliancesProvider).valueOrNull?.where((a) => a.service == svc).toList()
      ?? DemoData.appliances.where((a) => a.service == svc).toList();
});

// Todos los que están sobre límite
final overLimitAppliancesProvider = Provider<List<Appliance>>((ref) {
  return (ref.watch(appliancesProvider).valueOrNull ?? DemoData.appliances)
      .where((a) => a.isOverLimit).toList();
});

// ── ALERTAS ──────────────────────────────────────────────────────────────────
final activeAlertsProvider = StreamProvider<List<IoTAlert>>((ref) {
  return FirebaseFirestore.instance
      .collection('alerts')
      .where('isResolved', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => IoTAlert.fromMap(d.data(), d.id)).toList())
      .handleError((_) => DemoData.alerts.where((a) => !a.isResolved).toList());
});

final alertHistoryProvider = StreamProvider<List<IoTAlert>>((ref) {
  return FirebaseFirestore.instance
      .collection('alerts').orderBy('timestamp', descending: true).limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => IoTAlert.fromMap(d.data(), d.id)).toList())
      .handleError((_) => DemoData.alerts);
});

// ── CONSUMO MENSUAL ───────────────────────────────────────────────────────────
final monthlyConsumptionProvider = FutureProvider<ConsumptionSummary>((ref) async {
  try {
    final now  = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final snap = await FirebaseFirestore.instance
        .collection('consumption_history')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .get();
    double kwh = 0, lit = 0, gas = 0;
    for (final d in snap.docs) {
      kwh += (d['electricityKwh'] as num?)?.toDouble() ?? 0;
      lit += (d['waterLiters']    as num?)?.toDouble() ?? 0;
      gas += (d['gasKg']          as num?)?.toDouble() ?? 0;
    }
    if (kwh == 0 && lit == 0 && gas == 0) return ConsumptionSummary.demo();
    return ConsumptionSummary(electricityKwh:kwh, waterLiters:lit, gasKg:gas, from:from, to:now);
  } catch (_) {
    return ConsumptionSummary.demo();
  }
});

// ── PRESUPUESTO ───────────────────────────────────────────────────────────────
final budgetAnalysisProvider = Provider<BudgetAnalysis>((ref) {
  final budget = ref.watch(userProfileProvider).valueOrNull?.monthlyBudget ?? 150.0;
  return DemoData.budgetFor(budget);
});

// ── SERIE TEMPORAL 24h ────────────────────────────────────────────────────────
final hourlySeriesProvider =
    FutureProvider.family<List<double>, ServiceType>((ref, svc) async {
  try {
    final now   = DateTime.now();
    final since = now.subtract(const Duration(hours: 24));
    final snap  = await FirebaseFirestore.instance
        .collection('readings')
        .where('service', isEqualTo: svc.name)
        .where('ts', isGreaterThan: since.millisecondsSinceEpoch)
        .orderBy('ts').limit(288).get();
    if (snap.docs.isEmpty) return _demo(svc);
    return snap.docs.map((d) => (d['value'] as num).toDouble()).toList();
  } catch (_) { return _demo(svc); }
});

List<double> _demo(ServiceType t) {
  const base = [0.8,0.7,0.6,0.5,0.5,0.6,1.2,1.8,1.5,1.3,1.1,1.2,
                1.4,1.3,1.2,1.0,1.1,1.5,1.8,1.6,1.3,1.0,0.9,0.8];
  switch (t) {
    case ServiceType.electricity: return base.map((v) => v * 0.8).toList();
    case ServiceType.water:       return base.map((v) => v * 5.0).toList();
    case ServiceType.gas:         return base.map((v) => v * 30.0).toList();
  }
}

// ── CONTROL ACTUADORES ────────────────────────────────────────────────────────
final actuatorProvider =
    StateNotifierProvider<ActuatorNotifier, Map<String, bool>>(
        (_) => ActuatorNotifier());

class ActuatorNotifier extends StateNotifier<Map<String, bool>> {
  ActuatorNotifier() : super({
    'cocina/gas_valve':   true,
    'cocina/water_valve': true,
    'tablero/main_relay': true,
    'garaje/ventilation': false,
    'salon/light':        true,
    'cocina/light':       false,
    'dormitorio1/light':  false,
    'dormitorio2/light':  false,
  });

  Future<void> toggle(String id, bool value) async {
    state = {...state, id: value};
    try {
      await FirebaseDatabase.instance.ref('actuators/$id')
          .set({'active': value, 'ts': ServerValue.timestamp});
    } catch (_) {
      state = {...state, id: !value};
    }
  }

  Future<void> emergencyShutdown() async {
    final next = <String, bool>{};
    for (final k in state.keys) {
      next[k] = !(k.contains('valve') || k.contains('relay'));
    }
    state = next;
    try {
      await FirebaseDatabase.instance.ref('emergency')
          .set({'active': true, 'ts': ServerValue.timestamp});
    } catch (_) {}
  }
}
