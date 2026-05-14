// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override ConsumerState<SplashScreen> createState() => _S();
}
class _S extends ConsumerState<SplashScreen> {
  @override void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go(ref.read(authStateProvider).valueOrNull != null ? '/home' : '/auth/login');
    });
  }
  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width:96, height:96,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors:[AppTheme.primaryBlue, AppTheme.primaryGreen]),
          borderRadius: BorderRadius.circular(26),
          boxShadow:[BoxShadow(color:AppTheme.primaryBlue.withOpacity(.4), blurRadius:30, spreadRadius:5)]),
        child: const Icon(Icons.home_work_rounded, size:50, color:Colors.white),
      ).animate().scale(duration:600.ms, curve:Curves.elasticOut),
      const SizedBox(height:26),
      const Text('IoT Achocalla',
          style:TextStyle(fontSize:26, fontWeight:FontWeight.bold,
              color:AppTheme.textPrimary, letterSpacing:1.2))
          .animate().fadeIn(delay:400.ms).slideY(begin:.3, end:0),
      const SizedBox(height:6),
      const Text('Sistema Inteligente de Gestión del Hogar',
          style:TextStyle(color:AppTheme.textSecondary, fontSize:13), textAlign:TextAlign.center)
          .animate().fadeIn(delay:600.ms),
      const SizedBox(height:36),
      Row(mainAxisAlignment:MainAxisAlignment.center, children:[
        _C(icon:Icons.bolt,             label:'Energía', color:AppTheme.electricColor, d:700),
        const SizedBox(width:10),
        _C(icon:Icons.water_drop,       label:'Agua',    color:AppTheme.waterColor,    d:850),
        const SizedBox(width:10),
        _C(icon:Icons.local_fire_department, label:'Gas',color:AppTheme.gasColor,      d:1000),
      ]),
      const SizedBox(height:48),
      const CircularProgressIndicator(color:AppTheme.primaryBlue, strokeWidth:2)
          .animate().fadeIn(delay:1400.ms),
      const SizedBox(height:12),
      const Text('UNIFRANZ · Ingeniería de Sistemas · 2026',
          style:TextStyle(color:AppTheme.textSecondary, fontSize:10, letterSpacing:.5))
          .animate().fadeIn(delay:1600.ms),
    ])),
  );
}
class _C extends StatelessWidget {
  const _C({required this.icon, required this.label, required this.color, required this.d});
  final IconData icon; final String label; final Color color; final int d;
  @override
  Widget build(BuildContext _) => Container(
    padding:const EdgeInsets.symmetric(horizontal:12, vertical:7),
    decoration:BoxDecoration(color:color.withOpacity(.1),
        borderRadius:BorderRadius.circular(20), border:Border.all(color:color.withOpacity(.3))),
    child:Row(mainAxisSize:MainAxisSize.min, children:[
      Icon(icon, color:color, size:14), const SizedBox(width:5),
      Text(label, style:TextStyle(color:color, fontSize:12, fontWeight:FontWeight.w600)),
    ]),
  ).animate().fadeIn(delay:Duration(milliseconds:d)).slideY(begin:.4, end:0);
}
