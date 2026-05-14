import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../widgets/web_3d_viewer.dart'; // Importa el visor web

class Appliance3DScreen extends StatelessWidget {
  const Appliance3DScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista 3D del Dispositivo'),
      ),
      body: kIsWeb
          ? const Web3DViewer() // ✅ Para web
          : const Center(
              child: Text('WebView no disponible en web'),
            ),
    );
  }
}