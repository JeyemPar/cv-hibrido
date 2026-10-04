import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opción A: la web se carga desde assets/web (funciona sin internet).
const String rutaWeb = 'assets/web/index.html';

/// Opción B: si publicas la web (GitHub Pages, Netlify...), pon aquí la URL
/// y cambia [usarRemoto] a true.
const bool usarRemoto = false;
const String urlRemota = 'https://jeyempar.github.io/cv-hibrido/';

class CvWebScreen extends StatefulWidget {
  final bool oscuro;
  final VoidCallback onAlternarTema;

  const CvWebScreen({
    super.key,
    required this.oscuro,
    required this.onAlternarTema,
  });

  @override
  State<CvWebScreen> createState() => _CvWebScreenState();
}

class _CvWebScreenState extends State<CvWebScreen> {
  late final WebViewController _controller;
  int _progreso = 0;
  bool _hayError = false;
  int _seccionActual = 0;

  /// Botones de la barra inferior → id de la sección en el HTML.
  static const _secciones = [
    (icono: Icons.person, texto: 'Perfil', id: 'perfil'),
    (icono: Icons.work, texto: 'Experiencia', id: 'experiencia'),
    (icono: Icons.build, texto: 'Habilidades', id: 'habilidades'),
    (icono: Icons.mail, texto: 'Contacto', id: 'contacto'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progreso = p),
          onPageStarted: (_) => setState(() => _hayError = false),
          onPageFinished: (_) => _enviarTema(),
          onWebResourceError: (error) {
            // Solo nos interesa si falla la página principal
            if (error.isForMainFrame ?? true) {
              setState(() => _hayError = true);
            }
          },
          onNavigationRequest: _manejarEnlace,
        ),
      );
    _cargar();
  }

  void _cargar() {
    if (usarRemoto) {
      _controller.loadRequest(Uri.parse(urlRemota));
    } else {
      _controller.loadFlutterAsset(rutaWeb);
    }
  }

  /// tel:, mailto: y enlaces externos se abren con apps nativas del teléfono;
  /// el WebView solo navega dentro del propio CV.
  NavigationDecision _manejarEnlace(NavigationRequest request) {
    final uri = Uri.parse(request.url);
    final esInterno = uri.scheme == 'file' ||
        uri.scheme == 'about' ||
        (usarRemoto && request.url.startsWith(urlRemota));
    if (esInterno) return NavigationDecision.navigate;

    launchUrl(uri, mode: LaunchMode.externalApplication).then((ok) {
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación')),
        );
      }
    });
    return NavigationDecision.prevent;
  }

  /// Puente Flutter → JavaScript: aplica el tema en la página.
  void _enviarTema() {
    final modo = widget.oscuro ? 'dark' : 'light';
    _controller.runJavaScript("window.setTheme && window.setTheme('$modo');");
  }

  void _irASeccion(int i) {
    setState(() => _seccionActual = i);
    _controller.runJavaScript("window.irA && window.irA('${_secciones[i].id}');");
  }

  void _compartir() {
    SharePlus.instance.share(
      ShareParams(
        subject: 'CV de John Michael Paredes López',
        text: 'Conoce el perfil de John Michael Paredes López, '
            'Desarrollador / Gestor Técnico.\n'
            'GitHub: https://github.com/JeyemPar\n'
            'Correo: Michaelparedes1994@hotmail.com',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CvWebScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.oscuro != widget.oscuro) _enviarTema();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // Botón "atrás" de Android: primero retrocede en la web, luego sale
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi CV'),
          actions: [
            IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              tooltip: widget.oscuro ? 'Tema claro' : 'Tema oscuro',
              icon: Icon(widget.oscuro ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onAlternarTema,
            ),
            IconButton(
              tooltip: 'Compartir perfil',
              icon: const Icon(Icons.share),
              onPressed: _compartir,
            ),
          ],
          bottom: _progreso < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(value: _progreso / 100),
                )
              : null,
        ),
        body: _hayError ? _vistaError() : WebViewWidget(controller: _controller),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _seccionActual,
          onDestinationSelected: _irASeccion,
          destinations: [
            for (final s in _secciones)
              NavigationDestination(icon: Icon(s.icono), label: s.texto),
          ],
        ),
      ),
    );
  }

  Widget _vistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 56),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el CV', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() => _hayError = false);
                _cargar();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
