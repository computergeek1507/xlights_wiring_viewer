import 'package:flutter/material.dart';

import 'ui/home_page.dart';

void main() {
  runApp(const WiringViewerApp());
}

class WiringViewerApp extends StatelessWidget {
  const WiringViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'xLights Wiring Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF18181D),
      ),
      home: const HomePage(),
    );
  }
}
