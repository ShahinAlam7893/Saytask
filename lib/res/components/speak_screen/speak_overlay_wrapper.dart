import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saytask/repository/speak_overlay_provider.dart';
import 'speak_overlay_content.dart';

/// Wrapper widget that adds the speak overlay capability to any screen
class SpeakOverlayWrapper extends StatelessWidget {
  final Widget child;

  const SpeakOverlayWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SpeakOverlayProvider>(
      builder: (context, overlayProvider, _) {
        return Stack(
          children: [
            // Original page content
            child,

            // Speak overlay (shown when active)
            if (overlayProvider.isOverlayVisible)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: overlayProvider.isOverlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.white,
                    child: const SpeakOverlayContent(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}