// lib/screens/security/security_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});
  @override ConsumerState<SecurityScreen> createState() => _SeS();
}

class _SeS extends ConsumerState<SecurityScreen> {
  bool _presence = false;
  TimeOfDay _from = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _to   = const TimeOfDay(hour: 6,  minute: 0);

  @override
  Widget build(BuildContext context) {
    final alerts    = ref.watch(activeAlertsProvider).valueOrNull ?? [];
    final actuators = ref.watch(actuatorProvider);
    final hasCrit   = alerts.any((a) => a.level == AlertLevel.critical);
    final statusColor = alerts.isEmpty ? AppTheme.primaryGreen
        : hasCrit ? AppTheme.dangerRed : AppTheme.warningAmber;
    final statusText  = alerts.isEmpty ? 'Sistema Seguro'
        : hasCrit ? '¡ALERTA CRÍTICA!'  : 'Atención requerida';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('Seguridad')),
      // ✅ CORREGIDO: SingleChildScrollView con child + Column
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(  // ← Envuelve todo en Column
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado general
            GlassCard(
              borderColor: statusColor.withOpacity(.4),
              color: statusColor.withOpacity(.08),
              child: Row(children: [
                Container(width:52, height:52,
                  decoration:BoxDecoration(color:statusColor.withOpacity(.15), shape:BoxShape.circle),
                  child:Icon(alerts.isEmpty?Icons.verified_rounded:Icons.warning_rounded,
                      color:statusColor, size:28)),
                const SizedBox(width:14),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                  Text(statusText, style:TextStyle(color:statusColor, fontWeight:FontWeight.bold, fontSize:15)),
                  Text(alerts.isEmpty?'Todos los sensores operando normalmente'
                      :'${alerts.length} alerta(s) activa(s) requieren atención',
                      style:const TextStyle(color:AppTheme.textSecondary, fontSize:12)),
                ])),
                if(hasCrit) Container(width:12,height:12,
                  decoration:BoxDecoration(color:AppTheme.dangerRed, shape:BoxShape.circle))
                    .animate(onPlay:(c)=>c.repeat()).scaleXY(end:1.4,duration:800.ms).then().scaleXY(end:1.0,duration:800.ms),
              ]),
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            // Paro de emergencia
            GestureDetector(
              onLongPress: () => _confirmEmergency(context),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.dangerRed.withOpacity(.4), width: 1.5)),
                child: Row(children: [
                  Container(width:58, height:58,
                    decoration:const BoxDecoration(color:AppTheme.dangerRed, shape:BoxShape.circle),
                    child:const Icon(Icons.emergency_rounded, color:Colors.white, size:30))
                      .animate(onPlay:(c)=>c.repeat()).scaleXY(end:1.04,duration:1.seconds).then().scaleXY(end:1.0,duration:1.seconds),
                  const SizedBox(width:14),
                  const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                    Text('PARO DE EMERGENCIA', style:TextStyle(color:AppTheme.dangerRed,
                        fontWeight:FontWeight.bold, fontSize:14, letterSpacing:.5)),
                    SizedBox(height:3),
                    Text('Mantén presionado 2s\nCorta gas + agua + electricidad simultáneamente',
                        style:TextStyle(color:AppTheme.textSecondary, fontSize:12)),
                  ])),
                ]),
              ),
            ).animate().fadeIn(delay:80.ms),

            const SizedBox(height: 22),

            const SectionHeader('Control de Actuadores'),
            const SizedBox(height: 10),

            ...[
              ('cocina/gas_valve',   '🔥 Válvula Gas',       'Corte automático ante fugas', AppTheme.gasColor),
              ('cocina/water_valve', '💧 Válvula Agua',       'Control de suministro hídrico', AppTheme.waterColor),
              ('tablero/main_relay', '⚡ Relé Principal',     'Protección contra sobrecargas', AppTheme.electricColor),
              ('garaje/ventilation', '🌬️ Ventilación Garaje', 'Control CO₂ automático', AppTheme.primaryGreen),
              ('salon/light',        '💡 Luces Sala',         'Control iluminación', AppTheme.electricColor),
            ].asMap().entries.map((entry) {
              final (id, label, sub, color) = entry.value;
              final isOn = actuators[id] ?? true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isOn ? color.withOpacity(.25) : Colors.white.withOpacity(.06))),
                child: Row(children: [
                  Container(width:42, height:42,
                    decoration:BoxDecoration(color:(isOn?color:AppTheme.textSecondary).withOpacity(.12), shape:BoxShape.circle),
                    child:Center(child:Text(label.split(' ').first, style:const TextStyle(fontSize:18)))),
                  const SizedBox(width:12),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                    Text(label.substring(label.indexOf(' ')+1),
                        style:const TextStyle(color:AppTheme.textPrimary, fontWeight:FontWeight.w500)),
                    Text(sub, style:const TextStyle(color:AppTheme.textSecondary, fontSize:11)),
                  ])),
                  Switch.adaptive(value:isOn, activeColor:color,
                      onChanged:(v)=>ref.read(actuatorProvider.notifier).toggle(id, v)),
                ]),
              ).animate().fadeIn(delay:Duration(milliseconds:100+entry.key*40));
            }).toList(),

            const SizedBox(height: 22),

            const SectionHeader('Simulación de Presencia'),
            const SizedBox(height: 10),

            GlassCard(
              borderColor: _presence ? AppTheme.primaryGreen.withOpacity(.3) : Colors.white.withOpacity(.06),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.home_outlined, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Simulación de presencia', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                    Text('Activa luces aleatoriamente para disuadir intrusiones',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ])),
                  Switch.adaptive(value: _presence, activeColor: AppTheme.primaryGreen,
                      onChanged: (v) => setState(() => _presence = v)),
                ]),
                if (_presence) ...[
                  const Divider(color: Colors.white12, height: 20),
                  Row(children: [
                    Expanded(child: _TimePicker(label:'Inicio', time:_from,
                        onTap:() async {
                          final t = await showTimePicker(context:context, initialTime:_from);
                          if(t!=null) setState(()=>_from=t);
                        })),
                    const SizedBox(width:10),
                    Expanded(child: _TimePicker(label:'Fin', time:_to,
                        onTap:() async {
                          final t = await showTimePicker(context:context, initialTime:_to);
                          if(t!=null) setState(()=>_to=t);
                        })),
                  ]),
                ],
              ]),
            ).animate().fadeIn(delay:200.ms),

            const SizedBox(height: 22),

            const SectionHeader('Alertas activas'),
            const SizedBox(height: 10),

            if (alerts.isEmpty)
              GlassCard(child: const Row(children: [
                Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryGreen),
                SizedBox(width:10),
                Text('Sin alertas activas.', style: TextStyle(color: AppTheme.primaryGreen)),
              ]))
            else
              ...alerts.map((a) => Padding(padding: const EdgeInsets.only(bottom:8),
                  child: _AlertTile(alert:a))).toList(),
          ], // ← Cierra children de Column
        ), // ← Cierra Column
      ), // ← Cierra SingleChildScrollView
    );
  }

  void _confirmEmergency(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: const Row(children:[
        Icon(Icons.warning_rounded, color:AppTheme.dangerRed),
        SizedBox(width:8),
        Text('Confirmar Emergencia', style:TextStyle(color:AppTheme.dangerRed)),
      ]),
      content: const Text('¿Cortar todos los servicios?\n\n'
          '✓ Válvula de gas (< 1.5s)\n✓ Suministro de agua\n✓ Relé principal eléctrico',
          style:TextStyle(color:AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed:()=>Navigator.pop(ctx), child:const Text('Cancelar')),
        ElevatedButton(
          onPressed:() async {
            Navigator.pop(ctx);
            await ref.read(actuatorProvider.notifier).emergencyShutdown();
            if(ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content:Text('⚡ Paro de emergencia ejecutado'),
                backgroundColor:AppTheme.dangerRed));
          },
          style:ElevatedButton.styleFrom(backgroundColor:AppTheme.dangerRed),
          child:const Text('EJECUTAR PARO')),
      ],
    ),
  );
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.label, required this.time, required this.onTap});
  final String label; final TimeOfDay time; final VoidCallback onTap;
  @override
  Widget build(BuildContext ctx) => GestureDetector(onTap:onTap, child:Container(
    padding:const EdgeInsets.symmetric(horizontal:12, vertical:10),
    decoration:BoxDecoration(color:AppTheme.bgCardLight, borderRadius:BorderRadius.circular(10)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(label, style:const TextStyle(color:AppTheme.textSecondary, fontSize:11)),
      Text(time.format(ctx), style:const TextStyle(color:AppTheme.primaryGreen, fontWeight:FontWeight.bold)),
    ]),
  ));
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final IoTAlert alert;
  @override
  Widget build(BuildContext _) => Container(
    padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:alert.levelColor.withOpacity(.08), borderRadius:BorderRadius.circular(12),
        border:Border.all(color:alert.levelColor.withOpacity(.3))),
    child:Row(children:[
      Icon(alert.typeIcon, color:alert.levelColor, size:22),
      const SizedBox(width:10),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(alert.message, style:const TextStyle(color:AppTheme.textPrimary, fontWeight:FontWeight.w500, fontSize:13)),
        Text('${alert.zoneName}${alert.applianceName.isNotEmpty?' · ${alert.applianceName}':''} · hace ${_ago(alert.timestamp)}',
            style:const TextStyle(color:AppTheme.textSecondary, fontSize:11)),
      ])),
      BadgeLabel(alert.levelLabel, color:alert.levelColor),
    ]),
  );

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if(d.inMinutes<60) return '${d.inMinutes}m';
    if(d.inHours<24)   return '${d.inHours}h';
    return '${d.inDays}d';
  }
}