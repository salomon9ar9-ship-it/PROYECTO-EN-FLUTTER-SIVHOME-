// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.child});
  final Widget child;
  @override ConsumerState<HomeScreen> createState() => _HS();
}

class _HS extends ConsumerState<HomeScreen> {
  int _idx = 0;

  static const _tabs = [
    _T('/home',          Icons.dashboard_rounded,     Icons.dashboard_outlined,   'Panel'),
    _T('/security',      Icons.security_rounded,       Icons.security_outlined,     'Seguridad'),
    _T('/intelligence',  Icons.psychology_rounded,     Icons.psychology_outlined,   'IA'),
    _T('/visualization', Icons.view_in_ar_rounded,     Icons.view_in_ar_outlined,   '3D'),
    _T('/settings',      Icons.settings_rounded,       Icons.settings_outlined,     'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(activeAlertsProvider).valueOrNull?.length ?? 0;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final t  = _tabs[i];
                final on = _idx == i;
                return GestureDetector(
                  onTap: () { setState(() => _idx = i); context.go(t.path); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: on ? AppTheme.primaryBlue.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(on ? t.activeIcon : t.icon,
                            color: on ? AppTheme.primaryBlue : AppTheme.textSecondary, size: 22),
                        if (i == 0 && alerts > 0)
                          Positioned(right: -6, top: -4, child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(color: AppTheme.dangerRed, shape: BoxShape.circle),
                            child: Center(child: Text('$alerts',
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
                          )),
                      ]),
                      const SizedBox(height: 3),
                      Text(t.label, style: TextStyle(
                          fontSize: 10,
                          fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                          color: on ? AppTheme.primaryBlue : AppTheme.textSecondary)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _T {
  const _T(this.path, this.activeIcon, this.icon, this.label);
  final String path, label;
  final IconData activeIcon, icon;
}
