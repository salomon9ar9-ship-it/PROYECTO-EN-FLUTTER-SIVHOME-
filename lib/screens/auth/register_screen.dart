// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override ConsumerState<RegisterScreen> createState() => _RS();
}
class _RS extends ConsumerState<RegisterScreen> {
  final _form  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  UserRole _role = UserRole.tenant;
  bool _obs=true, _loading=false; String? _error;
  @override void dispose() { _name.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _go() async {
    if (!_form.currentState!.validate()) return;
    setState(()=>_loading=true);
    final e = await ref.read(authNotifierProvider.notifier).register(
        name:_name.text.trim(), email:_email.text.trim(), password:_pass.text, role:_role);
    if (!mounted) return;
    if (e==null) context.go('/home');
    else setState(()=>_error=e);
    setState(()=>_loading=false);
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed:()=>context.go('/auth/login')),
      title:const Text('Crear cuenta')),
    body: SingleChildScrollView(
      padding:const EdgeInsets.all(24),
      child: Form(key:_form, child:Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
        const SizedBox(height:8),
        TextFormField(controller:_name,
          decoration:const InputDecoration(labelText:'Nombre completo', prefixIcon:Icon(Icons.person_outline)),
          validator:(v)=>v==null||v.isEmpty?'Requerido':null),
        const SizedBox(height:14),
        TextFormField(controller:_email, keyboardType:TextInputType.emailAddress,
          decoration:const InputDecoration(labelText:'Correo electrónico', prefixIcon:Icon(Icons.email_outlined)),
          validator:(v)=>v==null||!v.contains('@')?'Email inválido':null),
        const SizedBox(height:14),
        TextFormField(controller:_pass, obscureText:_obs,
          decoration:InputDecoration(labelText:'Contraseña', prefixIcon:const Icon(Icons.lock_outline),
            suffixIcon:IconButton(icon:Icon(_obs?Icons.visibility_outlined:Icons.visibility_off_outlined),
                onPressed:()=>setState(()=>_obs=!_obs))),
          validator:(v)=>v==null||v.length<6?'Mínimo 6 caracteres':null),
        const SizedBox(height:22),
        const Text('Tipo de usuario',
            style:TextStyle(color:AppTheme.textSecondary, fontSize:13, fontWeight:FontWeight.w500)),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:_RT(label:'Propietario', desc:'Acceso completo\nControles y alertas',
              icon:Icons.home_rounded, sel:_role==UserRole.owner,
              onTap:()=>setState(()=>_role=UserRole.owner))),
          const SizedBox(width:12),
          Expanded(child:_RT(label:'Inquilino', desc:'Solo monitoreo\ny lecturas',
              icon:Icons.person_rounded, sel:_role==UserRole.tenant,
              onTap:()=>setState(()=>_role=UserRole.tenant))),
        ]),
        if (_error!=null)...[
          const SizedBox(height:14),
          Container(padding:const EdgeInsets.all(12),
            decoration:BoxDecoration(color:AppTheme.dangerRed.withOpacity(.1),
                borderRadius:BorderRadius.circular(10)),
            child:Text(_error!, style:const TextStyle(color:AppTheme.dangerRed, fontSize:13))),
        ],
        const SizedBox(height:26),
        LoadingButton(onPressed:_go, isLoading:_loading, label:'Crear cuenta',
            icon:Icons.person_add_rounded),
      ])),
    ),
  );
}
class _RT extends StatelessWidget {
  const _RT({required this.label, required this.desc, required this.icon,
      required this.sel, required this.onTap});
  final String label, desc; final IconData icon; final bool sel; final VoidCallback onTap;
  @override
  Widget build(BuildContext _) {
    final c = sel ? AppTheme.primaryBlue : AppTheme.textSecondary;
    return GestureDetector(onTap:onTap, child:AnimatedContainer(
      duration:const Duration(milliseconds:200),
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        color:sel?AppTheme.primaryBlue.withOpacity(.1):AppTheme.bgCard,
        borderRadius:BorderRadius.circular(14),
        border:Border.all(color:sel?AppTheme.primaryBlue:Colors.white.withOpacity(.08), width:1.5)),
      child:Column(children:[
        Icon(icon, color:c, size:28), const SizedBox(height:8),
        Text(label, style:TextStyle(color:c, fontWeight:FontWeight.w600, fontSize:14)),
        const SizedBox(height:4),
        Text(desc, style:const TextStyle(color:AppTheme.textSecondary, fontSize:11),
            textAlign:TextAlign.center),
      ]),
    ));
  }
}
