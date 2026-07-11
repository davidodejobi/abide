import 'package:flutter/material.dart';

/// Extension methods for Widget to reduce boilerplate
extension WidgetExtensions on Widget {
  // ============================================================================
  // PADDING HELPERS
  // ============================================================================

  /// Add padding to all sides
  /// Usage: Text('Hello').padding(16)
  Widget padAll(double value) {
    return Padding(
      padding: EdgeInsets.all(value),
      child: this,
    );
  }

  /// Add symmetric padding
  /// Usage: Text('Hello').paddingSymmetric(horizontal: 16, vertical: 8)
  Widget padSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  /// Add only padding
  /// Usage: Text('Hello').paddingOnly(left: 16, top: 8)
  Widget padOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: this,
    );
  }

  // ============================================================================
  // TOOLTIP
  // ============================================================================

  /// Add tooltip
  /// Usage: Icon(PhosphorIcons.info()).tooltip('Information')
  Widget tooltip(String message) {
    return Tooltip(
      message: message,
      child: this,
    );
  }
}
