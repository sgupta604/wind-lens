import 'package:flutter/material.dart';

import 'package:wind_lens/core/models/scene_state.dart';

/// A status bar widget that shows loading progress while data resolves.
///
/// Shows contextual messages based on the current data availability:
/// - "Waiting for GPS..." when no position fix is available
/// - "Loading wind data..." when position is available but SceneState
///   hasn't composed yet (wind data still loading)
/// - Hidden (empty SizedBox) when SceneState is fully composed
///
/// Designed to overlay on top of the camera feed with a semi-transparent
/// background for readability. The widget accepts its data as constructor
/// parameters (not from providers) following the same pattern as [DebugPanel].
///
/// The parent [ARViewScreen] reads providers and passes the values here.
class DataStatusBar extends StatelessWidget {
  /// The current composed scene state, or null if still loading.
  final SceneState? sceneState;

  /// Whether a GPS position fix has been acquired.
  final bool hasPosition;

  const DataStatusBar({
    super.key,
    required this.sceneState,
    required this.hasPosition,
  });

  @override
  Widget build(BuildContext context) {
    // If scene state is fully composed, show nothing
    if (sceneState != null) {
      return const SizedBox.shrink();
    }

    // Determine the status message
    final String message;
    if (!hasPosition) {
      message = 'Waiting for GPS...';
    } else {
      message = 'Loading wind data...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
