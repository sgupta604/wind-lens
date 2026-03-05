import 'package:flutter/material.dart';

import 'location_picker_screen.dart';

/// Lightweight loading screen shown while flutter_map cold-loads.
///
/// Displays a dark scaffold with a centered spinner, then replaces itself
/// with [LocationPickerScreen] after one frame. This prevents the UI from
/// freezing during flutter_map's first-use package initialization.
class LocationPickerLoadingScreen extends StatefulWidget {
  const LocationPickerLoadingScreen({super.key});

  @override
  State<LocationPickerLoadingScreen> createState() =>
      _LocationPickerLoadingScreenState();
}

class _LocationPickerLoadingScreenState
    extends State<LocationPickerLoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LocationPickerScreen(),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}
