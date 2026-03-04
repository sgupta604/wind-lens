import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/position_data.dart';
import '../../core/providers/location_override_provider.dart';
import '../../core/providers/sensor_providers.dart';

/// Full-screen map view for selecting a custom location override.
///
/// Opens centered on the user's current GPS position (or (0,0) fallback).
/// User taps to place a pin, then taps "Confirm" to write the override
/// to [locationOverrideProvider], which causes all position-dependent
/// data providers (wind, horizon, scene, dome) to refetch.
///
/// "Cancel" pops without modifying the provider. "Reset to GPS" snaps
/// the pin back to the current GPS coordinates.
///
/// Session-only: the override persists until the app restarts.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late LatLng _selectedPosition;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final position = ref.read(effectivePositionProvider);
    if (position != null) {
      _selectedPosition = LatLng(position.latitude, position.longitude);
    } else {
      _selectedPosition = const LatLng(0, 0);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPosition = point;
    });
  }

  void _onConfirm() {
    final position = PositionData(
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
      altitude: 0.0,
      accuracy: 0.0,
      timestamp: DateTime.now(),
    );
    ref.read(locationOverrideProvider.notifier).set(position);
    if (mounted) Navigator.of(context).pop();
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  void _onCoordinateTap() {
    final initialText =
        '${_selectedPosition.latitude.toStringAsFixed(4)}, '
        '${_selectedPosition.longitude.toStringAsFixed(4)}';
    final controller = TextEditingController(text: initialText);
    // Select all text so the user can immediately type over it.
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: initialText.length);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: Text(
                'Enter Coordinates',
                style: GoogleFonts.dmMono(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                style: GoogleFonts.dmMono(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'lat, lng  e.g. 41.2678, -96.0490',
                  hintStyle: GoogleFonts.dmMono(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                  errorText: errorText,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.redAccent),
                  ),
                ),
                onSubmitted: (_) {
                  final result = _parseCoordinates(controller.text);
                  if (result != null) {
                    _applyCoordinates(result);
                    Navigator.of(dialogContext).pop();
                  } else {
                    setDialogState(() {
                      errorText = 'Invalid coordinates';
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmMono(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final result = _parseCoordinates(controller.text);
                    if (result != null) {
                      _applyCoordinates(result);
                      Navigator.of(dialogContext).pop();
                    } else {
                      setDialogState(() {
                        errorText = 'Invalid coordinates';
                      });
                    }
                  },
                  child: Text(
                    'Go',
                    style: GoogleFonts.dmMono(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Parse a coordinate string like "41.2678, -96.0490" or "41.2678 -96.0490".
  /// Returns a [LatLng] if valid, or null if not.
  LatLng? _parseCoordinates(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Split on comma, or whitespace if no comma
    final parts = trimmed.contains(',')
        ? trimmed.split(',').map((s) => s.trim()).toList()
        : trimmed.split(RegExp(r'\s+')).toList();

    if (parts.length != 2) return null;

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);

    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90) return null;
    if (lng < -180 || lng > 180) return null;

    return LatLng(lat, lng);
  }

  void _applyCoordinates(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _mapController.move(_selectedPosition, _mapController.camera.zoom);
  }

  void _onResetToGps() {
    final gps = ref.read(stablePositionProvider);
    if (gps != null) {
      // GPS is available — clear override and snap map to GPS
      ref.read(locationOverrideProvider.notifier).clear();
      setState(() {
        _selectedPosition = LatLng(gps.latitude, gps.longitude);
      });
      _mapController.move(_selectedPosition, _mapController.camera.zoom);
    } else {
      // GPS not available — keep override intact so app stays functional
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS not available — keeping current location'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 12,
              onTap: _onMapTap,
              backgroundColor: const Color(0xFF1A1A2E),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.shyftlens.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Cancel / back button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Semantics(
              label: 'Cancel and go back',
              button: true,
              child: GestureDetector(
                onTap: _onCancel,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // Coordinate display (top-center) — tap to enter coordinates
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 70,
            right: 70,
            child: Semantics(
              label: 'Coordinates. Tap to enter manually.',
              button: true,
              child: GestureDetector(
                onTap: _onCoordinateTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedPosition.latitude.toStringAsFixed(4)}, '
                    '${_selectedPosition.longitude.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom button bar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  // Reset to GPS button
                  Expanded(
                    child: Semantics(
                      label: 'Reset to GPS location',
                      button: true,
                      child: GestureDetector(
                        onTap: _onResetToGps,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'RESET TO GPS',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmMono(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm button
                  Expanded(
                    child: Semantics(
                      label: 'Confirm selected location',
                      button: true,
                      child: GestureDetector(
                        onTap: _onConfirm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'CONFIRM',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmMono(
                              fontSize: 12,
                              color: Colors.black,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
