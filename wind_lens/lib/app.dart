import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/splash/splash_screen.dart';

/// The main Wind Lens application widget, wrapped in a ProviderScope
/// for Riverpod dependency injection.
///
/// Wind Lens is an AR app that visualizes wind patterns by overlaying
/// flowing particles on a live camera feed, showing wind direction and
/// speed at different altitude levels.
class WindLensApp extends StatelessWidget {
  const WindLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Shyft Lens',
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
