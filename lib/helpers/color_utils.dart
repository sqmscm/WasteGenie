import 'package:flutter/material.dart';

class ColorUtils {
  static Color transparentOverlay = Color.fromARGB(66, 153, 153, 153);
  static Color transparentOverlayDark = Color.fromARGB(119, 38, 46, 42);

  static Color getColorTransparent(String? identifier) {
    if (identifier == null) {
      return Color.fromARGB(119, 153, 153, 153);
    }
    switch (identifier.toLowerCase()) {
      case 'recycle':
        return Color.fromARGB(119, 17, 78, 184);
      case 'landfill':
        return Color.fromARGB(119, 38, 46, 42);
      case 'compost':
        return Color.fromARGB(119, 17, 191, 84);
      default:
        return Color.fromARGB(119, 153, 153, 153);
    }
  }

  static Color getColor(String identifier) {
    switch (identifier.toLowerCase()) {
      case 'recycle':
        return Color.fromARGB(255, 132, 175, 248);
      case 'landfill':
        return Color.fromARGB(255, 144, 155, 149);
      case 'compost':
        return Color.fromARGB(255, 150, 243, 186);
      default:
        return Color.fromARGB(255, 153, 153, 153);
    }
  }
}
