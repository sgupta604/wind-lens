import 'package:flutter/material.dart';
import '../widgets/camera_view.dart';

/// The main AR view screen that displays the camera feed.
///
/// This screen provides a fullscreen camera preview with a black background,
/// designed for augmented reality wind visualization. Future features will
/// add particle overlays and wind direction indicators on top of this camera view.
class ARViewScreen extends StatelessWidget {
  const ARViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: CameraView(),
    );
  }
}
