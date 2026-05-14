// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';  // ✅ AGREGADO: Para NumberFormat
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override ConsumerState<SettingsScreen> createState() => _SS();
}

class _SS extends ConsumerState<SettingsScreen> {
  bool _notif   = true;
  bool _gasA    = true;
  bool _elecA   = true;
  bool _waterA  = true;
  bool _motionA = false;
  double _gasT  = 200;
  double _elecT = 2.5;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [

          // Perfil
          userAsync.when(
            data: (u) => u != null ? _ProfileCard(user: u) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          // Meta mensual
          userAsync.when(
            data: (u) => u != null && u.isOwner
                ? _BudgetTile(user: u, ref: ref)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ).animate().fadeIn(delay: 60.ms),

          const SizedBox(height: 20),

          _SecLabel('NOTIFICACIONES'),
          _SwTile(label:'Activar notificaciones', sub:'Recibe alertas en tiempo real',
              icon:Icons.notifications_rounded, val:_notif,
              onChanged:(v)=>setState(()=>_notif=v)).animate().fadeIn(delay:80.ms),
          _SwTile(label:'Alertas de Gas', sub:'Fugas y concentración elevada',
              icon:Icons.local_fire_department_rounded, color:AppTheme.gasColor,
              val:_gasA, onChanged:(v)=>setState(()=>_gasA=v)).animate().fadeIn(delay:110.ms),
          _SwTile(label:'Alertas Eléctricas', sub:'Sobrecargas y consumo alto',
              icon:Icons.bolt_rounded, color:AppTheme.electricColor,
              val:_elecA, onChanged:(v)=>setState(()=>_elecA=v)).animate().fadeIn(delay:140.ms),
          _SwTile(label:'Alertas de Agua', sub:'Fugas y consumo excesivo',
              icon:Icons.water_drop_rounded, color:AppTheme.waterColor,
              val:_waterA, onChanged:(v)=>setState(()=>_waterA=v)).animate().fadeIn(delay:170.ms),
          _SwTile(label:'Detección de movimiento', sub:'Alertas de seguridad del hogar',
              icon:Icons.motion_photos_on_rounded,
              val:_motionA, onChanged:(v)=>setState(()=>_motionA=v)).animate().fadeIn(delay:200.ms),

          const SizedBox(height: 20),

          _SecLabel('UMBRALES DE ALERTA'),
          _SlTile(label:'Umbral Gas (ppm)', val:_gasT, min:50, max:500,
              color:AppTheme.gasColor, onChanged:(v)=>setState(()=>_gasT=v))
              .animate().fadeIn(delay:220.ms),
          _SlTile(label:'Umbral Electricidad (kW)', val:_elecT, min:.5, max:6,
              color:AppTheme.electricColor, onChanged:(v)=>setState(()=>_elecT=v))
              .animate().fadeIn(delay:250.ms),

          const SizedBox(height: 20),

          _SecLabel('SISTEMA'),
          _ActionTile(label:'Conexión MQTT', sub:'Estado: Conectado ✓',
              icon:Icons.wifi_rounded, statusColor:AppTheme.primaryGreen,
              onTap:()=>_mqttDialog(context)).animate().fadeIn(delay:270.ms),
          _ActionTile(label:'Exportar datos', sub:'CSV/JSON del historial',
              icon:Icons.download_rounded, onTap:(){}).animate().fadeIn(delay:300.ms),
          _ActionTile(label:'Zonas del hogar', sub:'Gestionar sensores por zona',
              icon:Icons.grid_view_rounded, onTap:(){}).animate().fadeIn(delay:320.ms),
          _ActionTile(label:'Acerca del sistema', sub:'v2.0 · IoT Achocalla · UNIFRANZ 2026',
              icon:Icons.info_outline_rounded,
              onTap:()=>showAboutDialog(context:context,
                  applicationName:'IoT Achocalla', applicationVersion:'2.0.0',
                  applicationLegalese:'© 2026 Villegas Apaza Salomon Richard\n'
                      'Universidad Privada Franz Tamayo\nIngeniería de Sistemas'))
              .animate().fadeIn(delay:340.ms),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/auth/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed.withOpacity(.12),
              foregroundColor: AppTheme.dangerRed,
              side: BorderSide(color: AppTheme.dangerRed.withOpacity(.3)),
            ),
          ).animate().fadeIn(delay:380.ms),
        ],
      ),
    );
  }

  void _mqttDialog(BuildContext ctx) => showDialog(context:ctx, builder:(_)=>AlertDialog(
    backgroundColor:AppTheme.bgCard,
    title:const Text('Configuración MQTT'),
    content:const Text('Broker: mqtt.iotachocalla.bo\nPuerto: 8883 (TLS 1.3)\n'
        'QoS: 1 · Keep-alive: 60s\nCifrado: x.509\n\nEstado: Conectado ✓',
        style:TextStyle(color:AppTheme.textSecondary,fontSize:13,height:1.6)),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cerrar'))],
  ));
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final UserProfile user;
  @override
  Widget build(BuildContext _) => GlassCard(child:Row(children:[
    CircleAvatar(radius:28, backgroundColor:AppTheme.primaryBlue.withOpacity(.18),
      child:Text(user.name.isNotEmpty?user.name[0].toUpperCase():'U',
          style:const TextStyle(color:AppTheme.primaryBlue, fontSize:22, fontWeight:FontWeight.bold))),
    const SizedBox(width:14),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(user.name, style:const TextStyle(fontWeight:FontWeight.bold, color:AppTheme.textPrimary)),
      Text(user.email, style:const TextStyle(color:AppTheme.textSecondary, fontSize:12)),
      const SizedBox(height:4),
      BadgeLabel(user.isOwner?'Propietario':'Inquilino', color:AppTheme.primaryBlue),
    ])),
  ]));
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({required this.user, required this.ref});
  final UserProfile user; final WidgetRef ref;
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol:'Bs. ', decimalDigits:2);  // ✅ Ahora funciona con el import
    return GlassCard(child:Row(children:[
      const Icon(Icons.savings_rounded, color:AppTheme.primaryGreen, size:22),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Meta mensual de gasto',
            style:TextStyle(color:AppTheme.textPrimary, fontWeight:FontWeight.w500)),
        Text(fmt.format(user.monthlyBudget),
            style:const TextStyle(color:AppTheme.primaryGreen, fontWeight:FontWeight.bold, fontSize:16)),
      ])),
      TextButton(
        onPressed:()=>_edit(context, user, ref),
        child:const Text('Editar', style:TextStyle(color:AppTheme.primaryBlue, fontSize:12))),
    ]));
  }

  void _edit(BuildContext ctx, UserProfile u, WidgetRef r) {
    double tmp = u.monthlyBudget;
    showDialog(context:ctx, builder:(_)=>AlertDialog(
      backgroundColor:AppTheme.bgCard,
      title:const Text('Cambiar meta mensual (Bs.)'),
      content:TextFormField(
        initialValue:u.monthlyBudget.toStringAsFixed(0),
        keyboardType:TextInputType.number,
        decoration:const InputDecoration(labelText:'Presupuesto en Bolivianos',
            prefixIcon:Icon(Icons.savings_outlined)),
        onChanged:(v)=>tmp=double.tryParse(v)??tmp),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
        ElevatedButton(onPressed:() async {
          await r.read(authNotifierProvider.notifier).updateBudget(u.uid, tmp);
          if(ctx.mounted)Navigator.pop(ctx);
        }, child:const Text('Guardar')),
      ],
    ));
  }
}

class _SecLabel extends StatelessWidget {
  const _SecLabel(this.t);
  final String t;
  @override
  Widget build(BuildContext _) => Padding(
    padding:const EdgeInsets.only(bottom:10),
    child:Text(t, style:const TextStyle(color:AppTheme.textSecondary,
        fontSize:11, fontWeight:FontWeight.w700, letterSpacing:1.2)));
}

class _SwTile extends StatelessWidget {
  const _SwTile({required this.label, required this.sub, required this.icon,
      required this.val, required this.onChanged, this.color});
  final String label, sub; final IconData icon; final bool val;
  final ValueChanged<bool> onChanged; final Color? color;
  @override
  Widget build(BuildContext _) {
    final c = color ?? AppTheme.primaryBlue;
    return Container(
      margin:const EdgeInsets.only(bottom:8),
      padding:const EdgeInsets.symmetric(horizontal:14, vertical:10),
      decoration:BoxDecoration(color:AppTheme.bgCard, borderRadius:BorderRadius.circular(12),
          border:Border.all(color:Colors.white.withOpacity(.06))),
      child:Row(children:[
        Icon(icon, color:val?c:AppTheme.textSecondary, size:20),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label,style:const TextStyle(color:AppTheme.textPrimary,fontSize:13)),
          Text(sub,  style:const TextStyle(color:AppTheme.textSecondary,fontSize:11)),
        ])),
        Switch.adaptive(value:val, onChanged:onChanged, activeColor:c),
      ]),
    );
  }
}

class _SlTile extends StatelessWidget {
  const _SlTile({required this.label, required this.val, required this.min,
      required this.max, required this.color, required this.onChanged});
  final String label; final double val, min, max;
  final Color color; final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext _) => Container(
    margin:const EdgeInsets.only(bottom:8),
    padding:const EdgeInsets.fromLTRB(14,12,14,4),
    decoration:BoxDecoration(color:AppTheme.bgCard, borderRadius:BorderRadius.circular(12),
        border:Border.all(color:Colors.white.withOpacity(.06))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text(label,style:const TextStyle(color:AppTheme.textPrimary,fontSize:13)),
        Text(val.toStringAsFixed(0),style:TextStyle(color:color,fontWeight:FontWeight.bold)),
      ]),
      Slider(value:val, min:min, max:max, onChanged:onChanged,
          activeColor:color, inactiveColor:color.withOpacity(.2)),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.label, required this.sub, required this.icon,
      required this.onTap, this.statusColor});
  final String label, sub; final IconData icon;
  final VoidCallback onTap; final Color? statusColor;
  @override
  Widget build(BuildContext _) => GestureDetector(
    onTap:onTap,
    child:Container(
      margin:const EdgeInsets.only(bottom:8),
      padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
      decoration:BoxDecoration(color:AppTheme.bgCard,borderRadius:BorderRadius.circular(12),
          border:Border.all(color:Colors.white.withOpacity(.06))),
      child:Row(children:[
        Icon(icon,color:AppTheme.textSecondary,size:20),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label,style:const TextStyle(color:AppTheme.textPrimary,fontSize:13)),
          Text(sub,  style:TextStyle(color:statusColor??AppTheme.textSecondary,fontSize:11)),
        ])),
        const Icon(Icons.chevron_right_rounded,color:AppTheme.textSecondary,size:18),
      ]),
    ),
  );
}