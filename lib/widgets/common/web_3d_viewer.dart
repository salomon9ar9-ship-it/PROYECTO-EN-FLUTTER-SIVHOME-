import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html; // Solo para web

class Platform3DViewer extends StatelessWidget {
  final String webUrl;
  final String mobileUrl;
  
  const Platform3DViewer({
    super.key,
    this.webUrl = 'assets/3d/viewer.html',
    this.mobileUrl = 'assets/3d/viewer.html',
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebViewer();
    } else {
      return _buildMobileViewer();
    }
  }

  Widget _buildWebViewer() {
    // Registrar iframe para web
    final iframe = html.IFrameElement()
      ..src = webUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none';

    html.platformViewRegistry.registerViewFactory(
      '3d-viewer-iframe',
      (int viewId) => iframe,
    );

    return HtmlElementView(viewType: '3d-viewer-iframe');
  }

  Widget _buildMobileViewer() {
    // Para móvil: mostrar mensaje o usar WebView si lo configuras
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('Vista 3D disponible en dispositivo móvil'),
        ],
      ),
    );
  }
}