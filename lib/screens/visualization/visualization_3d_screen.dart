// lib/screens/visualization/visualization_3d_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/iot_providers.dart';
import '../../theme/app_theme.dart';

class Visualization3DScreen extends ConsumerStatefulWidget {
  const Visualization3DScreen({super.key});
  
  @override
  ConsumerState<Visualization3DScreen> createState() => _V3S();
}

class _V3S extends ConsumerState<Visualization3DScreen> {
  String _zone = 'all';

  static const _zones = [
    ('all', 'Todo'),
    ('cocina', 'Cocina'),
    ('salon', 'Sala'),
    ('dormitorio1', 'Dorm. 1'),
    ('dormitorio2', 'Dorm. 2'),
    ('bano', 'Baño'),
    ('garaje', 'Garaje'),
  ];

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(activeAlertsProvider);
    
    return alertsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      ),
      error: (err, stack) {
        debugPrint('❌ Error en Visualization3DScreen: $err');
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: $err', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      },
      data: (alerts) {
        final alertCount = alerts.length;
        final hasAlert = alertCount > 0;
        debugPrint('✅ Alerts cargadas: $alertCount');

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: const Text('Gemelo Digital 3D', style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.bgCard,
            actions: [
              if (hasAlert)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dangerRed),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_rounded, color: AppTheme.dangerRed, size: 16),
                    const SizedBox(width: 4),
                    Text('$alertCount alerta(s)',
                        style: const TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        )),
                  ]),
                ),
            ],
          ),
          body: Column(children: [
            // ✅ Selector de zona (sin ScrollController personalizado)
            Container(
              height: 50,
              color: AppTheme.bgCard,
              child: ListView.separated(
                // ✅ Sin controller personalizado para evitar conflicto
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _zones.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final (id, label) = _zones[i];
                  final on = _zone == id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _zone = id);
                      debugPrint('🎯 Zona seleccionada: $id');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: on ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: on ? AppTheme.primaryBlue : Colors.white.withOpacity(.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: on ? Colors.white : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ✅ Área principal 3D (con contenido visible)
            Expanded(
              child: Container(
                color: AppTheme.bgDark,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.view_in_ar_rounded,
                        size: 90,
                        color: AppTheme.primaryBlue.withOpacity(0.7),
                      ).animate().fadeIn(duration: 500.ms).scale(),
                      const SizedBox(height: 24),
                      const Text(
                        'Gemelo Digital 3D',
                        style: TextStyle(
                          color: Colors.white, // ✅ Texto blanco para contraste
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      Text(
                        kIsWeb ? 'Visualizador web en desarrollo' : 'Disponible en app móvil',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.8), // ✅ Color visible
                          fontSize: 15,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 32),
                      // Botón de prueba para verificar interacción
                      ElevatedButton.icon(
                        onPressed: () {
                          debugPrint('🔘 Botón presionado - App funcionando ✅');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ App funcionando correctamente'),
                              backgroundColor: AppTheme.primaryBlue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Verificar conexión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Leyenda inferior (con colores visibles)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.bgCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _Leg(color: AppTheme.primaryGreen, label: 'Sensor OK'),
                  _Leg(color: AppTheme.dangerRed, label: 'Alerta'),
                  _Leg(color: AppTheme.primaryBlue, label: 'Gateway'),
                  _Leg(color: AppTheme.electricColor, label: 'ESP32'),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _Leg extends StatelessWidget {
  const _Leg({required this.color, required this.label});
  final Color color;
  final String label;
  
  @override
  Widget build(BuildContext _) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9), // ✅ Color más visible
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.9), // ✅ Texto visible
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}