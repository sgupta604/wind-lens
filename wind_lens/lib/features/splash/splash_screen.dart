import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../core/providers/location_override_provider.dart';
import '../home/home_screen.dart';

/// Lightweight splash screen shown at app launch.
///
/// Watches three providers to compute loading progress (0-100%):
/// - [effectivePositionProvider]: GPS fix (0% -> 33%)
/// - [windDataProvider]: wind data loaded (33% -> 66%)
/// - [horizonProfileProvider]: horizon loaded (66% -> 100%)
///
/// Transitions to [HomeScreen] ONLY when all three providers have real
/// values AND a 2-second minimum display time has elapsed. If data has
/// not loaded within 60 seconds, an error message with a Retry button
/// is shown instead of silently entering the app.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _minTimeElapsed = false;
  bool _hasError = false;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _startErrorTimer();
    // Ensure splash is visible for at least 2 seconds, even with cached data.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _minTimeElapsed = true; });
    });
  }

  void _startErrorTimer() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && !_navigated) {
        setState(() { _hasError = true; });
      }
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _errorTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _retry() {
    setState(() { _hasError = false; });
    _startErrorTimer();
  }

  @override
  Widget build(BuildContext context) {
    // Watch all three providers to compute progress.
    final position = ref.watch(effectivePositionProvider);
    final wind = ref.watch(windDataProvider);
    final horizon = ref.watch(horizonProfileProvider);

    final hasGps = position != null;
    final hasWind = wind.hasValue;
    final hasHorizon = horizon.hasValue;

    int steps = 0;
    if (hasGps) steps++;
    if (hasWind) steps++;
    if (hasHorizon) steps++;

    final progress = steps / 3.0;

    // Determine status text.
    final String statusText;
    if (steps == 3) {
      statusText = 'Ready';
    } else if (hasWind) {
      statusText = 'Loading terrain...';
    } else if (hasGps) {
      statusText = 'Loading wind data...';
    } else {
      statusText = 'Acquiring GPS...';
    }

    // Navigate when all data is loaded AND minimum time elapsed.
    if (steps == 3 && !_navigated && _minTimeElapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToHome();
      });
    }

    // Clear error state if all data loaded (e.g. data arrived after error shown).
    if (steps == 3 && _hasError) {
      _hasError = false;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            const Text(
              'ShyftLens',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 48,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 32),
            if (_hasError) ...[
              // Error state: message + retry button
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 64),
                child: Text(
                  'Unable to load data — check your connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 11,
                    color: Color(0xFF888888),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _retry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Normal state: progress bar + status text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: const Color(0xFF333333),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                statusText,
                style: const TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 11,
                  color: Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
