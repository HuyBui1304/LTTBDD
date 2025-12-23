import 'package:flutter/material.dart';

class AccessibilityHelper {
  // Minimum touch target size (Material Design recommends 48x48)
  static const double minTouchTarget = 48.0;

  // Text scale factor limits
  static const double minTextScale = 0.8;
  static const double maxTextScale = 2.0;

  // Ensure widget meets accessibility standards
  static Widget ensureTouchTarget({
    required Widget child,
    double minSize = minTouchTarget,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }

  // Add semantic label for screen readers
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    bool button = false,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      enabled: enabled,
      child: child,
    );
  }

  // Ensure readable text contrast
  static TextStyle ensureContrast(TextStyle style, BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return style.copyWith(
        color: style.color ?? Colors.white,
      );
    } else {
      return style.copyWith(
        color: style.color ?? Colors.black,
      );
    }
  }

  // Limit text scaling for better readability
  static double constrainTextScale(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    return textScale.clamp(minTextScale, maxTextScale);
  }

  // Wrap with MediaQuery to control text scaling
  static Widget withTextScale({
    required Widget child,
    required BuildContext context,
  }) {
    final textScale = constrainTextScale(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child,
    );
  }

  // Create accessible button
  static Widget accessibleButton({
    required VoidCallback? onPressed,
    required Widget child,
    required String semanticLabel,
    String? tooltip,
    ButtonStyle? style,
  }) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
      ),
    );
  }

  // Create accessible icon button
  static Widget accessibleIconButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String semanticLabel,
    String? tooltip,
    Color? color,
  }) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color,
          constraints: const BoxConstraints(
            minWidth: minTouchTarget,
            minHeight: minTouchTarget,
          ),
        ),
      ),
    );
  }

  // Announce to screen readers
  static void announce(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Text(message),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

