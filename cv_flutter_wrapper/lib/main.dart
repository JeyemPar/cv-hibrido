import 'package:flutter/material.dart';
import 'screens/cv_web_screen.dart';

void main() => runApp(const CvWrapperApp());

/// La app guarda el tema (claro/oscuro) y lo comparte con la pantalla
/// del WebView, que a su vez se lo comunica a la página web.
class CvWrapperApp extends StatefulWidget {
  const CvWrapperApp({super.key});

  @override
  State<CvWrapperApp> createState() => _CvWrapperAppState();
}

class _CvWrapperAppState extends State<CvWrapperApp> {
  ThemeMode _modo = ThemeMode.light;

  void _alternarTema() {
    setState(() {
      _modo = _modo == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const semilla = Color(0xFF3F4A5A);
    return MaterialApp(
      title: 'CV Híbrido',
      debugShowCheckedModeBanner: false,
      themeMode: _modo,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: semilla),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: semilla,
          brightness: Brightness.dark,
        ),
      ),
      home: CvWebScreen(
        oscuro: _modo == ThemeMode.dark,
        onAlternarTema: _alternarTema,
      ),
    );
  }
}
