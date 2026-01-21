import 'package:flutter/material.dart';
import 'screens/ar_view_screen.dart';

void main() {
  runApp(const WindLensApp());
}

/// The main Wind Lens application widget.
///
/// Wind Lens is an AR app that visualizes wind patterns by overlaying
/// flowing particles on a live camera feed, showing wind direction and
/// speed at different altitude levels.
class WindLensApp extends StatelessWidget {
  const WindLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wind Lens',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const ARViewScreen(),
    );
  }
}
