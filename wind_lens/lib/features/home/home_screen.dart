import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wind_lens/core/providers/sensor_providers.dart';
import 'package:wind_lens/features/ar_view/ar_view_screen.dart';

import 'widgets/home_layer_toggles.dart';
import 'widgets/home_terrain_section.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/home_wind_row.dart';

/// The main home screen that serves as the app's entry point.
///
/// Presents a calm dashboard view of wind data with a decorative terrain
/// panorama. The user explicitly taps "Live AR" to enter the camera view.
///
/// A [ConsumerStatefulWidget] because it needs:
/// - [TickerProviderStateMixin] for the particle animation controller
/// - Riverpod [ref] for accessing providers
///
/// Layout (top to bottom):
/// 1. [HomeTopBar] - Logo + Live AR button
/// 2. Divider
/// 3. [HomeWindRow] - Speed, Direction, Altitude data
/// 4. [HomeTerrainSection] - Terrain, particles, altitude rail, compass
/// 5. [HomeLayerToggles] - Layer toggle buttons
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  void _navigateToAR() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ARViewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensorNotifiers = ref.watch(sensorNotifiersProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            HomeTopBar(onLiveArTap: _navigateToAR),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Divider(
                thickness: 1,
                color: const Color(0xFF111111),
                height: 1,
              ),
            ),
            const HomeWindRow(),
            Expanded(
              child: HomeTerrainSection(
                particleController: _particleController,
                sensorNotifiers: sensorNotifiers,
              ),
            ),
            const HomeLayerToggles(),
          ],
        ),
      ),
    );
  }
}
