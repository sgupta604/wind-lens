import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Top bar containing the ShyftLens logo/subtitle and the Live AR button.
///
/// Owns its own [AnimationController] via [SingleTickerProviderStateMixin]
/// for the pulsing red dot on the Live AR button.
class HomeTopBar extends StatefulWidget {
  /// Callback invoked when the Live AR button is tapped.
  final VoidCallback onLiveArTap;

  const HomeTopBar({super.key, required this.onLiveArTap});

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ShyftLens',
                style: GoogleFonts.bebasNeue(
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'ATMOSPHERIC AR',
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  color: const Color(0xFF444444),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),

          // Live AR button
          Semantics(
            label: 'Open live AR camera view',
            button: true,
            child: GestureDetector(
              onTap: widget.onLiveArTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing red dot
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _pulseAnimation.value,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE AR',
                      style: GoogleFonts.dmMono(
                        fontSize: 12,
                        color: Colors.black,
                        letterSpacing: 0.15 * 12, // 0.15em
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
