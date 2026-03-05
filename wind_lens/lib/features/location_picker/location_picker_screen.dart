import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final TileProvider? tileProvider;

  const LocationPickerScreen({super.key, this.tileProvider});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late LatLng _selectedPosition;
  final _mapController = MapController();
  late final TileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider =
        widget.tileProvider ?? CancellableNetworkTileProvider();
    final position = ref.read(effectivePositionProvider);
    if (position != null) {
      _selectedPosition = LatLng(position.latitude, position.longitude);
    } else {
      _selectedPosition = const LatLng(39.8283, -98.5795);
    }
  }

  @override
  void dispose() {
    _tileProvider.dispose();
    _mapController.dispose();
    super.dispose();
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        final latController = TextEditingController(
          text: _selectedPosition.latitude.toStringAsFixed(4),
        );
        final lngController = TextEditingController(
          text: _selectedPosition.longitude.toStringAsFixed(4),
        );
        String? latError;
        String? lngError;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool validate() {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              bool valid = true;

              if (lat == null || lat < -90 || lat > 90) {
                latError = 'Must be between -90 and 90';
                valid = false;
              } else {
                latError = null;
              }

              if (lng == null || lng < -180 || lng > 180) {
                lngError = 'Must be between -180 and 180';
                valid = false;
              } else {
                lngError = null;
              }

              setSheetState(() {});
              return valid;
            }

            void onGo() {
              if (!validate()) return;
              final lat = double.parse(latController.text.trim());
              final lng = double.parse(lngController.text.trim());
              _applyCoordinates(LatLng(lat, lng));
              Navigator.of(sheetContext).pop();
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'Enter Coordinates',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Latitude field
                  TextField(
                    controller: latController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      labelStyle: const TextStyle(
                        fontFamily: 'DM Mono',
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      errorText: latError,
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
                    onSubmitted: (_) => onGo(),
                  ),
                  const SizedBox(height: 12),
                  // Longitude field
                  TextField(
                    controller: lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      labelStyle: const TextStyle(
                        fontFamily: 'DM Mono',
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      errorText: lngError,
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
                    onSubmitted: (_) => onGo(),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'DM Mono',
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: onGo,
                        child: const Text(
                          'Go',
                          style: TextStyle(
                            fontFamily: 'DM Mono',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                tileProvider: _tileProvider,
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
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
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
                            style: TextStyle(
                              fontFamily: 'DM Mono',
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
                            style: const TextStyle(
                              fontFamily: 'DM Mono',
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
