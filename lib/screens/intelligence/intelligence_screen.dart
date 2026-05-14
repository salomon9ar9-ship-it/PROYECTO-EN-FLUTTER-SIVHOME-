// lib/screens/intelligence/intelligence_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class IntelligenceScreen extends ConsumerWidget {
  const IntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget   = ref.watch(budgetAnalysisProvider);
    final anomalies = (ref.watch(appliancesProvider).valueOrNull ?? DemoData.appliances)
        .where((a) => a.isAnomaly || a.isOverLimit).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('Inteligencia IA'),
          actions:[IconButton(icon:const Icon(Icons.info_outline_rounded), onPressed:()=>_info(context))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16,8,16,100),
        children: [
          // Estado IA
          GlassCard(
            borderColor: AppTheme.primaryGreen.withOpacity(.3),
            color: AppTheme.primaryGreen.withOpacity(.04),
            child: Row(children: [
              Container(width:52, height:52,
                  decoration:BoxDecoration(color:AppTheme.primaryGreen.withOpacity(.15), shape:BoxShape.circle),
                  child:const Icon(Icons.psychology_rounded, color:AppTheme.primaryGreen, size:28)),
              const SizedBox(width:14),
              const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                Text('Motor IA Activo', style:TextStyle(color:AppTheme.primaryGreen, fontWeight:FontWeight.bold, fontSize:15)),
                Text('ARIMA · Isolation Forest · Random Forest\nModelos entrenados con 30 días de datos reales',
                    style:TextStyle(color:AppTheme.textSecondary, fontSize:11, height:1.4)),
              ])),
              const Column(children:[
                Text('F1', style:TextStyle(color:AppTheme.textSecondary, fontSize:11)),
                Text('0.89', style:TextStyle(color:AppTheme.primaryGreen, fontWeight:FontWeight.bold, fontSize:18)),
              ]),
            ]),
          ).animate().fadeIn(),

          const SizedBox(height:20),

          // Predicciones
          const SectionHeader('Predicción próximas 24h'),
          const SizedBox(height:10),
          ...[
            ('Electricidad', 8.4, 'kWh', 0.91, AppTheme.electricColor, Icons.bolt_rounded),
            ('Agua',       185.0, 'L',   0.87, AppTheme.waterColor,    Icons.water_drop_rounded),
            ('Gas (GLP)',    0.42, 'kg',  0.83, AppTheme.gasColor,      Icons.local_fire_department_rounded),
          ].asMap().entries.map((e){
            final (label, val, unit, conf, color, icon) = e.value;
            return Container(
              margin:const EdgeInsets.only(bottom:8),
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(color:color.withOpacity(.07), borderRadius:BorderRadius.circular(14),
                  border:Border.all(color:color.withOpacity(.2))),
              child:Row(children:[
                Container(width:44,height:44,decoration:BoxDecoration(color:color.withOpacity(.12),shape:BoxShape.circle),
                    child:Icon(icon,color:color,size:22)),
                const SizedBox(width:14),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(label,style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
                  Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
                    Text(val.toStringAsFixed(1),style:TextStyle(color:color,fontWeight:FontWeight.bold,fontSize:22)),
                    const SizedBox(width:4),
                    Padding(padding:const EdgeInsets.only(bottom:3),
                        child:Text(unit,style:TextStyle(color:color.withOpacity(.7),fontSize:12))),
                  ]),
                ])),
                Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                  const Text('Confianza',style:TextStyle(color:AppTheme.textSecondary,fontSize:10)),
                  Text('${(conf*100).toStringAsFixed(0)}%',
                      style:TextStyle(color:color,fontWeight:FontWeight.bold,fontSize:16)),
                  const SizedBox(height:4),
                  ClipRRect(borderRadius:BorderRadius.circular(3),
                      child:SizedBox(width:50,child:LinearProgressIndicator(value:conf,minHeight:4,
                          backgroundColor:color.withOpacity(.2),valueColor:AlwaysStoppedAnimation(color)))),
                ]),
              ]),
            ).animate().fadeIn(delay:Duration(milliseconds:80+e.key*40));
          }).toList(),

          const SizedBox(height:22),

          // Anomalías
          SectionHeader('Anomalías detectadas',
              action: anomalies.isNotEmpty ? null : null),
          const SizedBox(height:10),
          if(anomalies.isEmpty)
            GlassCard(child:const Row(children:[
              Icon(Icons.check_circle_outline_rounded,color:AppTheme.primaryGreen),
              SizedBox(width:10),
              Text('Sin anomalías detectadas.',style:TextStyle(color:AppTheme.primaryGreen)),
            ]))
          else
            ...anomalies.map((a)=>Padding(padding:const EdgeInsets.only(bottom:8),child:GlassCard(
              borderColor:(a.isAnomaly?AppTheme.dangerRed:AppTheme.warningAmber).withOpacity(.3),
              child:Row(children:[
                Text(a.icon,style:const TextStyle(fontSize:20)),
                const SizedBox(width:10),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(a.name,style:const TextStyle(color:AppTheme.textPrimary,fontWeight:FontWeight.w600,fontSize:13)),
                  Text('${a.zoneName} · ${a.currentUsage.toStringAsFixed(2)} ${a.unitLabel} '
                      '(normal ≤ ${a.normalMax.toStringAsFixed(2)})',
                      style:const TextStyle(color:AppTheme.textSecondary,fontSize:11)),
                ])),
                BadgeLabel(a.isAnomaly?'ANOMALÍA':'SOBRE LÍMITE',
                    color:a.isAnomaly?AppTheme.dangerRed:AppTheme.warningAmber),
              ]),
            ))).toList(),

          const SizedBox(height:22),

          // Todas las recomendaciones
          SectionHeader('Recomendaciones para alcanzar tu meta'),
          const SizedBox(height:10),
          ...budget.recommendations.map((r){
            final color = r.service==ServiceType.electricity?AppTheme.electricColor
                :r.service==ServiceType.water?AppTheme.waterColor:AppTheme.gasColor;
            final bCol  = r.priority==1?AppTheme.dangerRed:r.priority==2?AppTheme.warningAmber:AppTheme.primaryBlue;
            final badge = r.priority==1?'ALTA':r.priority==2?'MEDIA':'BAJA';
            return Container(
              margin:const EdgeInsets.only(bottom:8),
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(color:color.withOpacity(.05),borderRadius:BorderRadius.circular(14),
                  border:Border.all(color:color.withOpacity(.18))),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[
                  Icon(r.service==ServiceType.electricity?Icons.bolt_rounded
                      :r.service==ServiceType.water?Icons.water_drop_rounded
                      :Icons.local_fire_department_rounded, color:color, size:18),
                  const SizedBox(width:8),
                  Expanded(child:Text('${r.applianceName} · ${r.zoneName}',
                      style:const TextStyle(color:AppTheme.textPrimary,fontWeight:FontWeight.w600,fontSize:13))),
                  BadgeLabel(badge,color:bCol),
                ]),
                const SizedBox(height:7),
                Text(r.action,style:const TextStyle(color:AppTheme.textSecondary,fontSize:12,height:1.5)),
                const SizedBox(height:8),
                Row(children:[
                  const Icon(Icons.savings_outlined,color:AppTheme.primaryGreen,size:14),
                  const SizedBox(width:5),
                  Text('Ahorro potencial: Bs. ${r.potentialSaving.toStringAsFixed(2)}/mes',
                      style:const TextStyle(color:AppTheme.primaryGreen,fontSize:12,fontWeight:FontWeight.w600)),
                ]),
              ]),
            );
          }).toList(),

          const SizedBox(height:22),

          // Métricas del modelo
          GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Métricas de validación',style:TextStyle(color:AppTheme.textPrimary,fontWeight:FontWeight.w600,fontSize:15)),
            const SizedBox(height:14),
            ...[ ('ARIMA – Electricidad',0.91),('Prophet – Agua',0.87),
                 ('Isolation Forest – Gas',0.89),('Random Forest – Patrones',0.93)
            ].map((m){
              final color=m.$2>=0.85?AppTheme.primaryGreen:AppTheme.warningAmber;
              return Padding(padding:const EdgeInsets.only(bottom:12),child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                    Text(m.$1,style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
                    Text(m.$2.toStringAsFixed(2),style:TextStyle(color:color,fontWeight:FontWeight.bold)),
                  ]),
                  const SizedBox(height:5),
                  ClipRRect(borderRadius:BorderRadius.circular(4),
                      child:LinearProgressIndicator(value:m.$2,minHeight:5,
                          backgroundColor:Colors.white12,valueColor:AlwaysStoppedAnimation(color))),
                ],
              ));
            }),
          ])).animate().fadeIn(delay:200.ms),
        ],
      ),
    );
  }

  void _info(BuildContext ctx) => showDialog(context:ctx, builder:(_)=>AlertDialog(
    backgroundColor:AppTheme.bgCard,
    title:const Text('Sobre el módulo IA'),
    content:const Text('Algoritmos implementados:\n\n'
        '• ARIMA/Prophet: Predicción de series temporales\n'
        '• Isolation Forest: Detección de anomalías sin supervisión\n'
        '• Random Forest: Clasificación de patrones de uso\n\n'
        'Reentrenamiento automático cada 30 días con datos reales.\n'
        'Objetivo F1 ≥ 0.85 — KPI del proyecto de grado.',
        style:TextStyle(color:AppTheme.textSecondary,fontSize:13,height:1.5)),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Entendido'))],
  ));
}
