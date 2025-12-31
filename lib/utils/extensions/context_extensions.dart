import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // ============================================================================
  // MEDIA QUERY ACCESS
  // ============================================================================

  /// Access media query data
  /// Usage: context.mediaQuery
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  /// Usage: context.screenSize
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  /// Usage: context.width
  double get width => MediaQuery.of(this).size.width;

  /// Get screen height
  /// Usage: context.height
  double get height => MediaQuery.of(this).size.height;

  /// Get screen padding (safe area insets)
  /// Usage: context.padding
  EdgeInsets get padding => MediaQuery.of(this).padding;

  /// Get view insets (keyboard height, etc.)
  /// Usage: context.viewInsets
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Get status bar height
  /// Usage: context.statusBarHeight
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  /// Get bottom safe area height (for iPhone notch, etc.)
  /// Usage: context.bottomSafeHeight
  double get bottomSafeHeight => MediaQuery.of(this).padding.bottom;

  /// Check if keyboard is visible
  /// Usage: context.isKeyboardVisible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Get keyboard height
  /// Usage: context.keyboardHeight
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  // ============================================================================
  // DEVICE ORIENTATION
  // ============================================================================

  /// Check if device is in portrait mode
  /// Usage: context.isPortrait
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Check if device is in landscape mode
  /// Usage: context.isLandscape
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  // ============================================================================
  // DEVICE SIZE BREAKPOINTS
  // ============================================================================

  /// Check if device is mobile (width < 600)
  /// Usage: context.isMobile
  bool get isMobile => width < 600;

  /// Check if device is tablet (600 <= width < 1024)
  /// Usage: context.isTablet
  bool get isTablet => width >= 600 && width < 1024;

  /// Check if device is desktop (width >= 1024)
  /// Usage: context.isDesktop
  bool get isDesktop => width >= 1024;

  /// Check if device is small mobile (width < 375)
  /// Usage: context.isSmallMobile
  bool get isSmallMobile => width < 375;

  // ============================================================================
  // FOCUS HELPERS
  // ============================================================================

  /// Unfocus current focus (dismiss keyboard)
  /// Usage: context.unfocus()
  void unfocus() {
    FocusScope.of(this).unfocus();
  }

  /// Request focus for a specific node
  /// Usage: context.requestFocus(myFocusNode)
  void requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }

  /// Check if any widget has focus
  /// Usage: context.hasFocus
  bool get hasFocus => FocusScope.of(this).hasFocus;

  // ============================================================================
  // RESPONSIVE HELPERS
  // ============================================================================

  /// Get responsive value based on screen size
  /// Usage: context.responsive(mobile: 16, tablet: 20, desktop: 24)
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get font size scaled for screen size
  /// Usage: context.scaledFontSize(16)
  double scaledFontSize(double size) {
    final scale = width / 375; // Base width is 375 (iPhone SE)
    return size * scale;
  }

  // ============================================================================
  // LOCALE HELPERS
  // ============================================================================

  /// Get current locale
  /// Usage: context.locale
  Locale get locale => Localizations.localeOf(this);

  /// Get language code
  /// Usage: context.languageCode
  String get languageCode => locale.languageCode;

  // ============================================================================
  // MOUNTED CHECK (useful in async operations)
  // ============================================================================

  /// Check if context is still mounted (for async operations)
  /// Usage: if (!context.mounted) return;
  bool get mounted {
    try {
      // Try to access a property that would throw if context is unmounted
      findRenderObject();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================================
  // DEVICE TYPE CHECK
  // ============================================================================

  /// Check if device is an android device
  bool get isAndroid => Theme.of(this).platform == TargetPlatform.android;

  // ============================================================================
  // TEXT STYLES HELPER
  // ============================================================================

  /// Access text styles helper
  /// Usage: context.textStyles.caption
  _TextStylesHelper get textStyles => _TextStylesHelper(this);
}

/// Helper class for convenient text style access
class _TextStylesHelper {
  final BuildContext context;

  _TextStylesHelper(this.context);

  TextTheme get _textTheme => Theme.of(context).textTheme;

  /// Extra small text (10px)
  TextStyle get small => _textTheme.labelSmall ?? const TextStyle(fontSize: 10);

  /// Caption text (12px)
  TextStyle get caption =>
      _textTheme.bodySmall ?? const TextStyle(fontSize: 12);

  /// Body text (14px)
  TextStyle get body => _textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

  /// Subtitle text (16px)
  TextStyle get subtitle =>
      _textTheme.titleSmall ?? const TextStyle(fontSize: 16);

  /// Title text (18px)
  TextStyle get title =>
      _textTheme.titleMedium ?? const TextStyle(fontSize: 18);

  /// Headline text (24px)
  TextStyle get headline =>
      _textTheme.headlineSmall ?? const TextStyle(fontSize: 24);
}
