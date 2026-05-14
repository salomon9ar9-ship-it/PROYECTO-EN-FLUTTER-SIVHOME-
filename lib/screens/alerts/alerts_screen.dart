// lib/screens/alerts/alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});
  @override ConsumerState<AlertsScreen> createState() => _AS();
}

class _AS extends ConsumerState<AlertsScreen> {
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final allAlerts = ref.watch(alertHistoryProvider).valueOrNull ?? DemoData.alerts;
    final filtered  = _showResolved
        ? allAlerts
        : allAlerts.where((a) => !a.isResolved).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Historial de Alertas'),
        actions: [
          TextButton.icon(
            icon: Icon(_showResolved ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 16, color: AppTheme.primaryBlue),
            label: Text(_showResolved ? 'Ocultar resueltas' : 'Ver resueltas',
                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
            onPressed: () => setState(() => _showResolved = !_showResolved),
          ),
        ],
      ),
      body: filtered.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              Text(_showResolved ? 'Sin alertas registradas' : 'Sin alertas activas',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _AlertCard(alert: filtered[i])
                  .animate().fadeIn(delay: Duration(milliseconds: i * 30)).slideX(begin: .04, end: 0),
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final IoTAlert alert;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    final c   = alert.isResolved ? AppTheme.textSecondary : alert.levelColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.isResolved ? AppTheme.bgCard : c.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: alert.isResolved ? Colors.white.withOpacity(.06) : c.withOpacity(.3)),
      ),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: c.withOpacity(.12), shape: BoxShape.circle),
          child: Icon(alert.typeIcon, color: c, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alert.message,
              style: TextStyle(
                  color: alert.isResolved ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 3),
          Text(
            '${alert.zoneName}'
            '${alert.applianceName.isNotEmpty ? ' · ${alert.applianceName}' : ''}'
            ' · ${fmt.format(alert.timestamp)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          BadgeLabel(alert.levelLabel, color: c),
          const SizedBox(height: 4),
          if (alert.isResolved)
            const Icon(Icons.check_circle_outline_rounded,
                size: 16, color: AppTheme.primaryGreen)
          else
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: c.withOpacity(.5), blurRadius: 4)])),
        ]),
      ]),
    );
  }
}
