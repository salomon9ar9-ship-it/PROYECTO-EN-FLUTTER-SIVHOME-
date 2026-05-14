// lib/models/models.dart
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════

enum UserRole    { admin, owner, tenant }
enum AlertLevel  { none, low, medium, high, critical }
enum AlertType   { gasLeak, electricalOverload, waterLeak, waterExcess, motion, generic }
enum ServiceType { electricity, water, gas }

// ═══════════════════════════════════════════════════════════
// TARIFAS BOLIVIA 2024
// ═══════════════════════════════════════════════════════════

class Rates {
  static const double electricity = 0.55;  // BOB / kWh   (DELAPAZ)
  static const double water       = 0.012; // BOB / litro  (EPSAS)
  static const double gas         = 8.0;   // BOB / kg GLP
}

// ═══════════════════════════════════════════════════════════
// USER PROFILE
// ═══════════════════════════════════════════════════════════

class UserProfile {
  final String uid, name, email;
  final UserRole role;
  final bool notificationsEnabled;
  final double monthlyBudget;  // Meta en BOB

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.notificationsEnabled = true,
    this.monthlyBudget = 150.0,
  });

  bool get isOwner => role == UserRole.owner || role == UserRole.admin;

  factory UserProfile.fromMap(Map<String, dynamic> d, String uid) => UserProfile(
    uid: uid,
    name:  d['name']  ?? 'Usuario',
    email: d['email'] ?? '',
    role:  UserRole.values.firstWhere((e) => e.name == d['role'], orElse: () => UserRole.tenant),
    notificationsEnabled: d['notificationsEnabled'] ?? true,
    monthlyBudget: (d['monthlyBudget'] as num?)?.toDouble() ?? 150.0,
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'email': email, 'role': role.name,
    'notificationsEnabled': notificationsEnabled, 'monthlyBudget': monthlyBudget,
  };

  UserProfile copyWith({double? monthlyBudget, bool? notificationsEnabled}) => UserProfile(
    uid: uid, name: name, email: email, role: role,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    monthlyBudget: monthlyBudget ?? this.monthlyBudget,
  );
}

// ═══════════════════════════════════════════════════════════
// ZONE  (habitación / área del hogar)
// ═══════════════════════════════════════════════════════════

class IoTZone {
  final String id, name, icon;
  final bool isActive;
  final AlertLevel alertLevel;
  final double? currentKw;     // electricidad en tiempo real
  final double? currentLpm;    // agua L/min
  final double? currentPpm;    // gas ppm
  final double monthlyKwh;
  final double monthlyLiters;
  final double monthlyGasKg;

  const IoTZone({
    required this.id, required this.name, required this.icon,
    this.isActive = true, this.alertLevel = AlertLevel.none,
    this.currentKw, this.currentLpm, this.currentPpm,
    this.monthlyKwh = 0, this.monthlyLiters = 0, this.monthlyGasKg = 0,
  });

  double get monthlyCost =>
      monthlyKwh * Rates.electricity +
      monthlyLiters * Rates.water +
      monthlyGasKg * Rates.gas;

  Color get alertColor {
    switch (alertLevel) {
      case AlertLevel.critical: return const Color(0xFFFF3B3B);
      case AlertLevel.high:     return const Color(0xFFFFA500);
      case AlertLevel.medium:   return Colors.orange;
      case AlertLevel.low:      return const Color(0xFF0D7BF5);
      case AlertLevel.none:     return const Color(0xFF00C896);
    }
  }
}

// ═══════════════════════════════════════════════════════════
// APPLIANCE  (electrodoméstico / punto de consumo)
// ═══════════════════════════════════════════════════════════

class Appliance {
  final String id, zoneId, zoneName, name, icon;
  final ServiceType service;
  final double currentUsage;   // kW / L/min / ppm según servicio
  final double normalMax;      // valor normal máximo esperado
  final double alertThreshold; // umbral de alerta
  final bool isOn;
  final double dailyAvg;       // promedio diario de consumo
  final double monthlyAccum;   // acumulado del mes (kWh / litros / ppm·h)
  final bool isAnomaly;

  const Appliance({
    required this.id,    required this.zoneId,    required this.zoneName,
    required this.name,  required this.icon,      required this.service,
    required this.currentUsage, required this.normalMax, required this.alertThreshold,
    this.isOn = false,   this.dailyAvg = 0,       this.monthlyAccum = 0,
    this.isAnomaly = false,
  });

  bool   get isOverLimit   => currentUsage > alertThreshold;
  double get usagePct      => (currentUsage / normalMax.clamp(0.01, double.infinity)).clamp(0.0, 2.0);
  String get unitLabel {
    switch (service) {
      case ServiceType.electricity: return 'kW';
      case ServiceType.water:       return 'L/min';
      case ServiceType.gas:         return 'ppm';
    }
  }

  double get monthlyCost {
    switch (service) {
      case ServiceType.electricity: return monthlyAccum * Rates.electricity;
      case ServiceType.water:       return monthlyAccum * Rates.water;
      case ServiceType.gas:         return (monthlyAccum / 1000) * Rates.gas;
    }
  }

  Color get serviceColor {
    switch (service) {
      case ServiceType.electricity: return const Color(0xFFFFD60A);
      case ServiceType.water:       return const Color(0xFF00B4FF);
      case ServiceType.gas:         return const Color(0xFFFF6B35);
    }
  }
}

// ═══════════════════════════════════════════════════════════
// ALERT
// ═══════════════════════════════════════════════════════════

class IoTAlert {
  final String id, zoneId, zoneName, message;
  final String applianceName;
  final AlertType type;
  final AlertLevel level;
  final double triggerValue;
  final DateTime timestamp;
  final bool isResolved;
  final DateTime? resolvedAt;

  const IoTAlert({
    required this.id, required this.zoneId, required this.zoneName,
    required this.message, required this.type, required this.level,
    required this.triggerValue, required this.timestamp,
    this.applianceName = '', this.isResolved = false, this.resolvedAt,
  });

  factory IoTAlert.fromMap(Map<String, dynamic> d, String id) => IoTAlert(
    id: id,
    type:  AlertType.values.firstWhere((e) => e.name == d['type'],  orElse: () => AlertType.generic),
    level: AlertLevel.values.firstWhere((e) => e.name == d['level'], orElse: () => AlertLevel.low),
    zoneId: d['zoneId'] ?? '', zoneName: d['zoneName'] ?? '',
    applianceName: d['applianceName'] ?? '',
    message: d['message'] ?? '',
    triggerValue: (d['triggerValue'] as num?)?.toDouble() ?? 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(d['timestamp'] as int? ?? 0),
    isResolved: d['isResolved'] ?? false,
    resolvedAt: d['resolvedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(d['resolvedAt'] as int)
        : null,
  );

  Color get levelColor {
    switch (level) {
      case AlertLevel.critical: return const Color(0xFFFF3B3B);
      case AlertLevel.high:     return const Color(0xFFFFA500);
      case AlertLevel.medium:   return Colors.orange;
      default:                  return const Color(0xFF0D7BF5);
    }
  }

  String get levelLabel {
    switch (level) {
      case AlertLevel.critical: return 'CRÍTICO';
      case AlertLevel.high:     return 'ALTO';
      case AlertLevel.medium:   return 'MEDIO';
      default:                  return 'BAJO';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.gasLeak:            return Icons.local_fire_department_rounded;
      case AlertType.electricalOverload: return Icons.bolt_rounded;
      case AlertType.waterLeak:          return Icons.water_damage_rounded;
      case AlertType.waterExcess:        return Icons.water_drop_rounded;
      default:                           return Icons.warning_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// CONSUMPTION SUMMARY
// ═══════════════════════════════════════════════════════════

class ConsumptionSummary {
  final double electricityKwh, waterLiters, gasKg;
  final DateTime from, to;

  const ConsumptionSummary({
    required this.electricityKwh, required this.waterLiters,
    required this.gasKg, required this.from, required this.to,
  });

  double get electricityCost => electricityKwh * Rates.electricity;
  double get waterCost        => waterLiters    * Rates.water;
  double get gasCost          => gasKg          * Rates.gas;
  double get totalCost        => electricityCost + waterCost + gasCost;

  factory ConsumptionSummary.demo() {
    final now = DateTime.now();
    return ConsumptionSummary(
      electricityKwh: 87.3, waterLiters: 3120.0, gasKg: 4.8,
      from: DateTime(now.year, now.month, 1), to: now,
    );
  }

  factory ConsumptionSummary.empty() {
    final now = DateTime.now();
    return ConsumptionSummary(
      electricityKwh: 0, waterLiters: 0, gasKg: 0,
      from: DateTime(now.year, now.month, 1), to: now,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BUDGET ANALYSIS  (análisis para cumplir meta del usuario)
// ═══════════════════════════════════════════════════════════

class BudgetAnalysis {
  final double budget;
  final double currentSpend;
  final List<BudgetRecommendation> recommendations;

  const BudgetAnalysis({
    required this.budget,
    required this.currentSpend,
    required this.recommendations,
  });

  double get remaining    => budget - currentSpend;
  double get progressPct  => (currentSpend / budget.clamp(1, double.infinity)).clamp(0.0, 1.5);
  bool   get isOverBudget => currentSpend > budget;
  double get totalPotentialSaving =>
      recommendations.fold(0.0, (sum, r) => sum + r.potentialSaving);
}

class BudgetRecommendation {
  final String applianceName, zoneName, action;
  final ServiceType service;
  final double currentMonthlyCost, potentialSaving;
  final int priority; // 1=alta 2=media 3=baja

  const BudgetRecommendation({
    required this.applianceName, required this.zoneName,
    required this.service,       required this.currentMonthlyCost,
    required this.potentialSaving, required this.action,
    required this.priority,
  });
}

// ═══════════════════════════════════════════════════════════
// DEMO DATA
// ═══════════════════════════════════════════════════════════

class DemoData {
  // Zonas de la vivienda piloto Achocalla
  static const List<IoTZone> zones = [
    IoTZone(id:'cocina',      name:'Cocina',      icon:'🍳',
        currentKw:1.20, currentLpm:0.0,  currentPpm:45,
        monthlyKwh:28.4, monthlyLiters:620, monthlyGasKg:2.1),
    IoTZone(id:'salon',       name:'Sala',         icon:'🛋️',
        currentKw:0.42, monthlyKwh:12.1),
    IoTZone(id:'dormitorio1', name:'Dormitorio 1', icon:'🛏️',
        currentKw:0.18, monthlyKwh:6.2),
    IoTZone(id:'dormitorio2', name:'Dormitorio 2', icon:'🛏️',
        currentKw:0.22, monthlyKwh:7.8, alertLevel:AlertLevel.low),
    IoTZone(id:'dormitorio3', name:'Dormitorio 3', icon:'🛏️',
        currentKw:0.10, monthlyKwh:3.5),
    IoTZone(id:'bano',        name:'Baño',          icon:'🚿',
        currentLpm:0.8, monthlyLiters:2500, alertLevel:AlertLevel.medium),
    IoTZone(id:'garaje',      name:'Garaje',        icon:'🚗',
        currentKw:0.0,  currentPpm:12),
    IoTZone(id:'deposito',    name:'Depósito',      icon:'📦',
        currentKw:0.05),
  ];

  // Electrodomésticos por zona
  static const List<Appliance> appliances = [
    // ── ELECTRICIDAD ──────────────────────────────────────────────────────────
    Appliance(id:'e1', zoneId:'cocina',      zoneName:'Cocina',
        name:'Microondas',     icon:'📡', service:ServiceType.electricity,
        currentUsage:1.20, normalMax:1.20, alertThreshold:1.50,
        isOn:true,  dailyAvg:0.80, monthlyAccum:24.0),
    Appliance(id:'e2', zoneId:'cocina',      zoneName:'Cocina',
        name:'Refrigerador',   icon:'❄️', service:ServiceType.electricity,
        currentUsage:0.18, normalMax:0.25, alertThreshold:0.32,
        isOn:true,  dailyAvg:0.20, monthlyAccum:5.8),
    Appliance(id:'e3', zoneId:'salon',       zoneName:'Sala',
        name:'Televisor 55"',  icon:'📺', service:ServiceType.electricity,
        currentUsage:0.12, normalMax:0.15, alertThreshold:0.22,
        isOn:true,  dailyAvg:0.10, monthlyAccum:3.2),
    Appliance(id:'e4', zoneId:'salon',       zoneName:'Sala',
        name:'Router WiFi',    icon:'📶', service:ServiceType.electricity,
        currentUsage:0.03, normalMax:0.05, alertThreshold:0.08,
        isOn:true,  dailyAvg:0.03, monthlyAccum:0.9),
    Appliance(id:'e5', zoneId:'dormitorio2', zoneName:'Dormitorio 2',
        name:'PC + Cargadores', icon:'💻', service:ServiceType.electricity,
        currentUsage:0.22, normalMax:0.20, alertThreshold:0.35,
        isOn:true,  dailyAvg:0.15, monthlyAccum:4.5, isAnomaly:true),
    Appliance(id:'e6', zoneId:'dormitorio1', zoneName:'Dormitorio 1',
        name:'Ventilador',     icon:'🌀', service:ServiceType.electricity,
        currentUsage:0.06, normalMax:0.08, alertThreshold:0.12,
        isOn:false, dailyAvg:0.04, monthlyAccum:1.2),
    Appliance(id:'e7', zoneId:'cocina',      zoneName:'Cocina',
        name:'Licuadora',      icon:'🔌', service:ServiceType.electricity,
        currentUsage:0.0,  normalMax:0.40, alertThreshold:0.60,
        isOn:false, dailyAvg:0.02, monthlyAccum:0.6),
    Appliance(id:'e8', zoneId:'bano',        zoneName:'Baño',
        name:'Calefón Eléctrico',icon:'🔌',service:ServiceType.electricity,
        currentUsage:0.0,  normalMax:1.50, alertThreshold:2.00,
        isOn:false, dailyAvg:0.30, monthlyAccum:9.0),
    Appliance(id:'e9', zoneId:'garaje',      zoneName:'Garaje',
        name:'Foco LED x3',    icon:'💡', service:ServiceType.electricity,
        currentUsage:0.01, normalMax:0.03, alertThreshold:0.05,
        isOn:false, dailyAvg:0.01, monthlyAccum:0.3),

    // ── AGUA ──────────────────────────────────────────────────────────────────
    Appliance(id:'w1', zoneId:'bano',   zoneName:'Baño',
        name:'Ducha',            icon:'🚿', service:ServiceType.water,
        currentUsage:0.0,  normalMax:9.0,  alertThreshold:14.0,
        isOn:false, dailyAvg:45.0, monthlyAccum:1350.0),
    Appliance(id:'w2', zoneId:'bano',   zoneName:'Baño',
        name:'Fuga detectada',   icon:'💧', service:ServiceType.water,
        currentUsage:0.8,  normalMax:0.05, alertThreshold:0.2,
        isOn:true,  dailyAvg:19.2, monthlyAccum:576.0, isAnomaly:true),
    Appliance(id:'w3', zoneId:'bano',   zoneName:'Baño',
        name:'Lavamanos',        icon:'🚰', service:ServiceType.water,
        currentUsage:0.0,  normalMax:5.0,  alertThreshold:8.0,
        isOn:false, dailyAvg:8.0,  monthlyAccum:240.0),
    Appliance(id:'w4', zoneId:'cocina', zoneName:'Cocina',
        name:'Grifo cocina',     icon:'🚰', service:ServiceType.water,
        currentUsage:0.0,  normalMax:5.0,  alertThreshold:8.0,
        isOn:false, dailyAvg:12.0, monthlyAccum:360.0),
    Appliance(id:'w5', zoneId:'cocina', zoneName:'Cocina',
        name:'Lavaplatos',       icon:'🍽️', service:ServiceType.water,
        currentUsage:0.0,  normalMax:6.0,  alertThreshold:10.0,
        isOn:false, dailyAvg:5.0,  monthlyAccum:150.0),

    // ── GAS ───────────────────────────────────────────────────────────────────
    Appliance(id:'g1', zoneId:'cocina', zoneName:'Cocina',
        name:'Hornillas (4)',    icon:'🔥', service:ServiceType.gas,
        currentUsage:45.0, normalMax:80.0, alertThreshold:150.0,
        isOn:false, dailyAvg:12.0, monthlyAccum:0.0),
    Appliance(id:'g2', zoneId:'cocina', zoneName:'Cocina',
        name:'Horno a gas',      icon:'♨️', service:ServiceType.gas,
        currentUsage:0.0,  normalMax:60.0, alertThreshold:120.0,
        isOn:false, dailyAvg:4.0,  monthlyAccum:0.0),
    Appliance(id:'g3', zoneId:'bano',   zoneName:'Baño',
        name:'Calefón a gas',    icon:'🌡️', service:ServiceType.gas,
        currentUsage:0.0,  normalMax:80.0, alertThreshold:150.0,
        isOn:false, dailyAvg:18.0, monthlyAccum:0.0),
  ];

  static List<IoTAlert> get alerts => [
    IoTAlert(
      id:'al1', type:AlertType.waterLeak, level:AlertLevel.medium,
      zoneId:'bano', zoneName:'Baño', applianceName:'Fuga detectada',
      message:'Flujo continuo detectado 02:00–06:00 (0.8 L/min × 4h = 19.2 L)',
      triggerValue:0.8,
      timestamp:DateTime.now().subtract(const Duration(hours:2))),
    IoTAlert(
      id:'al2', type:AlertType.electricalOverload, level:AlertLevel.low,
      zoneId:'dormitorio2', zoneName:'Dormitorio 2', applianceName:'PC + Cargadores',
      message:'Consumo 10% sobre el promedio histórico: 0.22 kW (máx normal: 0.20 kW)',
      triggerValue:0.22,
      timestamp:DateTime.now().subtract(const Duration(hours:5))),
    IoTAlert(
      id:'al3', type:AlertType.waterLeak, level:AlertLevel.medium,
      zoneId:'bano', zoneName:'Baño', applianceName:'Fuga detectada',
      message:'Fuga anterior resuelta. Consumo anómalo 576 L adicionales este mes.',
      triggerValue:1.2,
      timestamp:DateTime.now().subtract(const Duration(days:3)),
      isResolved:true,
      resolvedAt:DateTime.now().subtract(const Duration(days:3, hours:-2))),
  ];

  // Análisis de presupuesto según meta del usuario
  static BudgetAnalysis budgetFor(double budget) {
    final summary = ConsumptionSummary.demo();
    return BudgetAnalysis(
      budget: budget,
      currentSpend: summary.totalCost,
      recommendations: [
        const BudgetRecommendation(
          applianceName: 'Fuga en Baño',
          zoneName: 'Baño',
          service: ServiceType.water,
          currentMonthlyCost: 6.91,
          potentialSaving: 6.91,
          action: 'Reparar la fuga (0.8 L/min continuo = 576 L/mes). '
              'Ahorro garantizado al corregirla.',
          priority: 1,
        ),
        const BudgetRecommendation(
          applianceName: 'Microondas',
          zoneName: 'Cocina',
          service: ServiceType.electricity,
          currentMonthlyCost: 13.20,
          potentialSaving: 4.10,
          action: 'Reducir uso nocturno. Concentrar uso en 12:00–13:00 y '
              '18:00–19:00. Evitar standby prolongado.',
          priority: 2,
        ),
        const BudgetRecommendation(
          applianceName: 'PC + Cargadores',
          zoneName: 'Dormitorio 2',
          service: ServiceType.electricity,
          currentMonthlyCost: 2.48,
          potentialSaving: 1.20,
          action: 'Desconectar cuando no está en uso. '
              'Consumo fantasma detectado 01:00–06:00.',
          priority: 2,
        ),
        const BudgetRecommendation(
          applianceName: 'Calefón eléctrico',
          zoneName: 'Baño',
          service: ServiceType.electricity,
          currentMonthlyCost: 4.95,
          potentialSaving: 2.20,
          action: 'Programar uso 06:30–07:00 y 19:00–19:30. '
              'Actualmente opera 40 min/día fuera de horario.',
          priority: 3,
        ),
      ],
    );
  }
}
