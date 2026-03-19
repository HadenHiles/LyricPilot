import 'package:flutter/material.dart';

/// Displays the LyricPilot logo image.
///
/// Use [AppLogo.wide] for the horizontal text+logo (1500×486 aspect ratio)
/// in app bars and headers. Use [AppLogo.icon] for the square icon variant.
class AppLogo extends StatelessWidget {
  final double height;
  final BoxFit fit;

  const AppLogo.wide({super.key, this.height = 32, this.fit = BoxFit.contain});

  const AppLogo.icon({super.key, this.height = 40, this.fit = BoxFit.contain});

  // Both named constructors share the same asset for now.
  // If a separate icon-only asset is added, store a bool field and switch here.

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/lyric-pilot-large-transparent.png',
      height: height,
      fit: fit,
      // Colour-filter the logo to match the current theme's onSurface colour
      // so it looks correct in both dark and light modes.
      color: Theme.of(context).colorScheme.onSurface,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}
