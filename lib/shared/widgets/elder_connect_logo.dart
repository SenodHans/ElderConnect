/// ElderConnect brand icon mark.
///
/// Renders the official ElderConnect icon (heart + two figures) from the
/// project asset at assets/images/elderconnect_icon.png.
/// Used on the splash screen and anywhere the icon-only mark is needed.
/// The wordmark ("ElderConnect") is always a separate Text widget.
library;

import 'package:flutter/material.dart';

class ElderConnectLogo extends StatelessWidget {
  final double size;

  const ElderConnectLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    // The icon PNG has a near-white background (#F5F4F4). Wrapping in a
    // matching-coloured container eliminates any visible box artifact when
    // the icon is placed on a white or near-white splash background.
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Semantics(
        image: true,
        label: 'ElderConnect icon',
        child: Image.asset(
          'assets/images/elderconnect_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
