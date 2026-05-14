// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LS();
}
class _LS extends ConsumerState<LoginScreen> {
  final _form  = GlobalKey<FormState>();
  final _email = TextEditingController(text:'');
  final _pass  = TextEditingController(text:'');
  bool _obs = true, _loading = false; String? _error;
  @override void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading=true; _error=null; });
    final e = await ref.read(authNotifierProvider.notifier).signIn(_email.text.trim(), _pass.text);
    if (!mounted) return;
    if (e == null) context.go('/home');
    else setState(() { _error=e; _loading=false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal:28),
      child: Column(children:[
        const SizedBox(height:32),
        Container(width:78, height:78,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors:[AppTheme.primaryBlue, AppTheme.primaryGreen]),
            borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.home_work_rounded, size:40, color:Colors.white),
        ).animate().scale(duration:500.ms, curve:Curves.elasticOut),
        const SizedBox(height:24),
        Text('Bienvenido', style: Theme.of(context).textTheme.displayMedium)
            .animate().fadeIn(delay:200.ms),
        const SizedBox(height:6),
        const Text('Gestiona tu hogar inteligente',
            style:TextStyle(color:AppTheme.textSecondary))
            .animate().fadeIn(delay:300.ms),
        const SizedBox(height:32),
        Form(key:_form, child:Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
          TextFormField(controller:_email, keyboardType:TextInputType.emailAddress,
            decoration:const InputDecoration(labelText:'Correo electrónico',
                prefixIcon:Icon(Icons.email_outlined)),
            validator:(v)=>v==null||v.isEmpty?'Requerido':!v.contains('@')?'Email inválido':null,
          ).animate().fadeIn(delay:400.ms).slideX(begin:-.08),
          const SizedBox(height:14),
          TextFormField(controller:_pass, obscureText:_obs,
            decoration:InputDecoration(labelText:'Contraseña',
              prefixIcon:const Icon(Icons.lock_outline),
              suffixIcon:IconButton(
                icon:Icon(_obs?Icons.visibility_outlined:Icons.visibility_off_outlined),
                onPressed:()=>setState(()=>_obs=!_obs))),
            validator:(v)=>v==null||v.length<6?'Mínimo 6 caracteres':null,
          ).animate().fadeIn(delay:500.ms).slideX(begin:-.08),
          if (_error!=null)...[
            const SizedBox(height:12),
            Container(padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:AppTheme.dangerRed.withOpacity(.1),
                borderRadius:BorderRadius.circular(10),
                border:Border.all(color:AppTheme.dangerRed.withOpacity(.4))),
              child:Row(children:[
                const Icon(Icons.error_outline, color:AppTheme.dangerRed, size:18),
                const SizedBox(width:8),
                Expanded(child:Text(_error!, style:const TextStyle(color:AppTheme.dangerRed, fontSize:13))),
              ]),
            ).animate().fadeIn().shake(),
          ],
          const SizedBox(height:22),
          LoadingButton(onPressed:_login, isLoading:_loading, label:'Iniciar Sesión',
              icon:Icons.login_rounded).animate().fadeIn(delay:600.ms),
          const SizedBox(height:14),
          TextButton(
            onPressed:()=>context.go('/auth/register'),
            child:RichText(text:TextSpan(
              text:'¿No tienes cuenta? ',
              style:const TextStyle(color:AppTheme.textSecondary),
              children:[TextSpan(text:'Regístrate',
                  style:TextStyle(color:Theme.of(context).colorScheme.primary,
                      fontWeight:FontWeight.w600))],
            )),
          ),
          const SizedBox(height:16),
          Container(padding:const EdgeInsets.all(12),
            decoration:BoxDecoration(color:AppTheme.primaryBlue.withOpacity(.08),
              borderRadius:BorderRadius.circular(10),
              border:Border.all(color:AppTheme.primaryBlue.withOpacity(.2))),
            child:const Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text('🎓 Cuentas de demostración',
                  style:TextStyle(color:AppTheme.primaryBlue, fontWeight:FontWeight.w600, fontSize:12)),
              SizedBox(height:5),
              Text('👑 Propietario:  owner@achocalla.bo  /  demo123\n'
                   '🏠 Inquilino:   tenant@achocalla.bo  /  demo123',
                  style:TextStyle(color:AppTheme.textSecondary, fontSize:11, height:1.6)),
            ]),
          ).animate().fadeIn(delay:800.ms),
        ])),
        const SizedBox(height:40),
      ]),
    ))),
  );
}
