import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// A widget that displays the device camera preview.
///
/// Handles camera initialization, lifecycle management, and error states.
/// Designed to be used as the background layer in an AR experience.
class CameraView extends StatefulWidget {
  /// Optional callback for processing camera frames.
  /// Used by sky detection in future features.
  final void Function(CameraImage image)? onFrame;

  const CameraView({super.key, this.onFrame});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isStreamingImages = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    _stopImageStream();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for proper camera resource management
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // App is being paused - stop streaming and dispose camera
      _stopImageStream();
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // App is resuming - reinitialize camera
      _initCamera();
    }
  }

  /// Initialize the camera controller.
  ///
  /// Finds the back camera (preferred for AR/sky viewing) or falls back to
  /// the first available camera. Handles various error conditions including
  /// no camera available and permission denied.
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No camera available');
        return;
      }

      // Find back camera or use first available
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      final size = _controller!.value.previewSize;
      debugPrint(
          'Camera initialized, resolution: ${size?.width.toInt()}x${size?.height.toInt()}');

      // Start image streaming if callback is provided
      if (widget.onFrame != null) {
        _startImageStream();
      }

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } on CameraException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize camera: $e');
    }
  }

  /// Starts the camera image stream for frame processing.
  ///
  /// The stream provides raw camera frames to the [onFrame] callback.
  /// Used by sky detection for color-based analysis.
  void _startImageStream() {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isStreamingImages ||
        widget.onFrame == null) {
      return;
    }

    try {
      _controller!.startImageStream((CameraImage image) {
        // Call the onFrame callback with the camera image
        widget.onFrame!(image);
      });
      _isStreamingImages = true;
      debugPrint('Camera image stream started');
    } catch (e) {
      debugPrint('Failed to start image stream: $e');
    }
  }

  /// Stops the camera image stream.
  void _stopImageStream() {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isStreamingImages) {
      return;
    }

    try {
      _controller!.stopImageStream();
      _isStreamingImages = false;
      debugPrint('Camera image stream stopped');
    } catch (e) {
      debugPrint('Failed to stop image stream: $e');
    }
  }

  /// Maps camera error codes to user-friendly messages.
  String _getErrorMessage(String code) {
    switch (code) {
      case 'CameraAccessDenied':
        return 'Camera permission denied. Please enable in Settings.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera permission denied. Please enable in Settings.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted.';
      default:
        return 'Camera error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state - show error message with icon
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    // Loading state - show progress indicator
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ready state - show camera preview
    return CameraPreview(_controller!);
  }
}
