import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/sensor_providers.dart';
import '../../services/performance_manager.dart';
import 'models/dome_constants.dart';
import 'models/dome_particle.dart';
import 'providers/dome_providers.dart';
import 'widgets/dome_forecast_slider.dart';
import 'widgets/dome_info_bar.dart';
import 'widgets/dome_painter.dart';

/// Full-screen 3D wind dome visualization on a black background.
///
/// Owns:
/// - [_particles]: mutable particle list (CustomPainter State Survival Pattern)
/// - [_ticker]: animation loop driving particle simulation
/// - [_perfManager]: adaptive FPS-based particle count
/// - [_frameCounter]: triggers DomePainter repaint via ValueListenableBuilder
/// - [_theta], [_phi], [_camR]: camera orbit angles and zoom
/// - [_activePointers]: raw pointer tracking for multi-touch gestures
///
/// Gesture mapping (via [Listener] for raw pointer events):
/// - 1-finger drag: orbit azimuth (theta) AND tilt (phi)
/// - 2-finger pinch: zoom (camR)
/// - 2-finger vertical drag: perspective tilt (phi)
///
/// Data flow:
/// 1. [domeWindProfileProvider] loads 72-hour forecast (auto on GPS)
/// 2. [currentDomeWindFieldProvider] selects the hour (from slider)
/// 3. Ticker reads the selected field, ticks each particle, increments frame counter
/// 4. [DomePainter] projects 3D -> 2D and draws trails
class WindDomeScreen extends ConsumerStatefulWidget {
  const WindDomeScreen({super.key});

  @override
  ConsumerState<WindDomeScreen> createState() => _WindDomeScreenState();
}

class _WindDomeScreenState extends ConsumerState<WindDomeScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────

  late List<DomeParticle> _particles;
  late final PerformanceManager _perfManager;
  late final ValueNotifier<int> _frameCounter;

  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _rng = Random();

  double _theta = DomeConstants.defaultTheta;
  double _phi = DomeConstants.defaultPhi;
  double _camR = DomeConstants.camR;

  /// Elapsed time in seconds for marker pulsing animation.
  double _elapsedSeconds = 0.0;

  // ─── Pointer Tracking (multi-touch gestures) ──────────────────
  final Map<int, Offset> _activePointers = {};
  double _lastPinchDistance = 0;

  bool _particlesInitialized = false;

  /// Cached dome render radius computed from domeSizeProvider.
  /// Updated in build() via ref.watch and on dome size change via ref.listen.
  double _currentDomeR = DomeConstants.domeR;
  double _currentDomeH = DomeConstants.domeH;

  // ─── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _perfManager = PerformanceManager();
    _frameCounter = ValueNotifier(0);
    _particles = [];

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameCounter.dispose();
    super.dispose();
  }

  // ─── Tick Loop ──────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Skip very large dt (e.g. first frame or app resume)
    if (dt > 0.1) return;

    // Track elapsed time for marker pulsing animation
    _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;

    _perfManager.recordFrame(elapsed, elapsed - Duration(microseconds: (dt * 1000000).round()));

    final field = ref.read(currentDomeWindFieldProvider);
    if (field == null) return;

    // Initialize particles on first wind data
    if (!_particlesInitialized) {
      _initializeParticles(_currentDomeR, _currentDomeH);
      _particlesInitialized = true;
    }

    // Adjust particle count from PerformanceManager
    _adjustParticleCount();

    // Tick each particle using current reactive dome radius
    for (final p in _particles) {
      p.tick(
        field,
        dt,
        _currentDomeR,
        _currentDomeH,
        rng: _rng,
      );
    }

    _frameCounter.value++;
  }

  void _initializeParticles(double domeR, double domeH) {
    _particles = List.generate(
      DomeConstants.particleCount,
      (_) => DomeParticle.random(_rng, domeR, domeH),
    );
  }

  void _adjustParticleCount() {
    final target = _perfManager.particleCount;
    if (_particles.length > target) {
      _particles = _particles.sublist(0, target);
    } else {
      while (_particles.length < target) {
        _particles.add(DomeParticle.random(
            _rng, _currentDomeR, _currentDomeH));
      }
    }
  }

  /// Re-initialize all particles when dome size changes.
  void _reinitializeParticles(double newDomeR, double newDomeH) {
    _currentDomeR = newDomeR;
    _currentDomeH = newDomeH;
    for (final p in _particles) {
      p.respawn(_rng, newDomeR, newDomeH);
    }
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(stablePositionProvider);
    final profileAsync = ref.watch(domeWindProfileProvider);

    // Reactive dome radius: compute from domeSizeProvider
    final domeSizeMeters = ref.watch(domeSizeProvider);
    final computedDomeR = domeSizeMeters / DomeConstants.metersPerRenderUnit;
    final computedDomeH =
        computedDomeR * (DomeConstants.domeH / DomeConstants.domeR);

    // Update cached values (used by tick loop and particle init)
    _currentDomeR = computedDomeR;
    _currentDomeH = computedDomeH;

    // Listen for dome size changes to reinitialize particles
    ref.listen(domeSizeProvider, (prev, next) {
      if (prev == next) return;
      final newDomeR = next / DomeConstants.metersPerRenderUnit;
      final newDomeH =
          newDomeR * (DomeConstants.domeH / DomeConstants.domeR);
      _reinitializeParticles(newDomeR, newDomeH);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dome overlay + multi-touch gesture handler
          Positioned.fill(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: ValueListenableBuilder<int>(
                valueListenable: _frameCounter,
                builder: (context, _, child) {
                  return CustomPaint(
                    painter: DomePainter(
                      particles: _particles,
                      theta: _theta,
                      phi: _phi,
                      camR: _camR,
                      domeR: _currentDomeR,
                      domeH: _currentDomeH,
                      time: _elapsedSeconds,
                    ),
                  );
                },
              ),
            ),
          ),

          // Info bar (top)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: DomeInfoBar(
              onBack: () => Navigator.of(context).pop(),
            ),
          ),

          // Forecast slider (bottom)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: const DomeForecastSlider(),
          ),

          // Loading indicator
          if (profileAsync.isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Loading wind data...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // GPS waiting message
          if (position == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Waiting for GPS...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Multi-Touch Gesture Handlers ──────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length == 2) {
      // Record initial pinch distance when second finger lands
      final pointers = _activePointers.values.toList();
      _lastPinchDistance = (pointers[0] - pointers[1]).distance;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final prev = _activePointers[event.pointer];
    _activePointers[event.pointer] = event.localPosition;
    if (prev == null) return;

    if (_activePointers.length == 1) {
      // ── Single finger: orbit azimuth (theta) + tilt (phi) ──
      // Sensitivity: 0.007 rad/px horizontal, 0.005 rad/px vertical
      final dx = event.localPosition.dx - prev.dx;
      final dy = event.localPosition.dy - prev.dy;
      setState(() {
        _theta -= dx * 0.007;
        _phi = (_phi - dy * 0.005).clamp(
          DomeConstants.phiMin, DomeConstants.phiMax);
      });
    } else if (_activePointers.length == 2) {
      // ── Two fingers: pinch zoom + vertical tilt ──
      final pointers = _activePointers.values.toList();
      final currentDist = (pointers[0] - pointers[1]).distance;

      // Pinch zoom: change camR proportional to pinch delta
      // Clamp bounds scale with current dome size so larger domes
      // can zoom out further.
      if (_lastPinchDistance > 0) {
        final pinchDelta = currentDist - _lastPinchDistance;
        final scale = _currentDomeR / DomeConstants.domeR;
        setState(() {
          _camR = (_camR - pinchDelta * 0.5).clamp(
            DomeConstants.camRMin * scale,
            DomeConstants.camRMax * scale,
          );
        });
      }
      _lastPinchDistance = currentDist;

      // Vertical tilt: average vertical delta of both pointers
      final dy = event.localPosition.dy - prev.dy;
      setState(() {
        _phi = (_phi - dy * 0.005).clamp(
          DomeConstants.phiMin, DomeConstants.phiMax);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _lastPinchDistance = 0;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _lastPinchDistance = 0;
    }
  }
}
