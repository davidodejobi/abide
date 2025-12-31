// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

/// Extension methods for String to reduce boilerplate
extension StringExtensions on String {
  // ============================================================================
  // ASSET PATH HELPERS
  // ============================================================================

  /// Get image asset path - automatically adds assets/images/ prefix and extension
  /// Usage: 'onboard1'.image => 'assets/images/onboard1.png'
  String get png => 'assets/images/$this.png';

  /// Get webp image asset path
  /// Usage: 'onboard1'.webp => 'assets/images/onboard1.webp'
  String get webp => 'assets/images/$this.webp';

  /// Get jpg image asset path
  /// Usage: 'photo'.jpg => 'assets/images/photo.jpg'
  String get jpg => 'assets/images/$this.jpg';

  /// Get SVG asset path
  /// Usage: 'logo'.svg => 'assets/images/logo.svg'
  String get svg => 'assets/images/$this.svg';

  /// Get icon asset path
  /// Usage: 'home'.icon => 'assets/images/icons/home.png'
  String get icon => 'assets/images/icons/$this.png';

  /// Get SVG icon asset path
  /// Usage: 'home'.iconSvg => 'assets/images/icons/home.svg'
  String get iconSvg => 'assets/images/icons/$this.svg';

  /// Get onboarding image asset path
  /// Usage: 'onboard1'.onboarding => 'assets/images/onboarding/onboard1.webp'
  String get onboarding => 'assets/images/onboarding/$this.webp';

  /// Get auth image asset path
  /// Usage: 'login_bg'.auth => 'assets/images/auth/login_bg.png'
  String get auth => 'assets/images/auth/$this.png';

  /// Get JSON asset path
  /// Usage: 'config'.json => 'assets/json/config.json'
  String get json => 'assets/json/$this.json';

  /// Get Lottie animation asset path
  /// Usage: 'loading'.lottie => 'assets/lottie/loading.json'
  String get lottie => 'assets/images/lottie/$this.json';

  // ============================================================================
  // STRING MANIPULATION
  // ============================================================================

  /// Capitalize first letter of the string
  /// Usage: 'hello'.capitalize => 'Hello'
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// Capitalize first letter of each word
  /// Usage: 'hello world'.capitalizeWords => 'Hello World'
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize)
        .join(' ');
  }

  /// Convert to title case
  /// Usage: 'hello_world'.toTitleCase => 'Hello World'
  String get toTitleCase => capitalizeWords;

  /// Convert snake_case to camelCase
  /// Usage: 'user_name'.toCamelCase => 'userName'
  String get toCamelCase {
    if (isEmpty) return this;
    final words = split('_');
    if (words.length == 1) return this;
    return words.first + words.skip(1).map((word) => word.capitalize).join();
  }

  /// Convert camelCase to snake_case
  /// Usage: 'userName'.toSnakeCase => 'user_name'
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  // ============================================================================
  // HTML & FORMATTING
  // ============================================================================

  /// Strip HTML tags from string
  /// Usage: '<p>Hello</p>'.stripHtml => 'Hello'
  String get stripHtml {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Strip HTML tags and extra whitespace
  /// Usage: '<p>Hello  \n  World</p>'.stripHtmlAndWhitespace => 'Hello World'
  String get stripHtmlAndWhitespace {
    return stripHtml.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Remove extra whitespace
  /// Usage: 'Hello    World'.removeExtraSpaces => 'Hello World'
  String get removeExtraSpaces {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Check if string is a valid email
  /// Usage: 'test@example.com'.isValidEmail => true
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number (basic check)
  /// Usage: '+1234567890'.isValidPhone => true
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^\+?[\d\s\-()]+$');
    return phoneRegex.hasMatch(this) && length >= 10;
  }

  /// Check if string is a valid URL
  /// Usage: 'https://example.com'.isValidUrl => true
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(this);
  }

  /// Check if string contains only numbers
  /// Usage: '123'.isNumeric => true
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Check if string contains only letters
  /// Usage: 'abc'.isAlpha => true
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Check if string contains only alphanumeric characters
  /// Usage: 'abc123'.isAlphanumeric => true
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  // ============================================================================
  // FORMATTING
  // ============================================================================

  /// Format as currency (Nigerian Naira)
  /// Usage: '1000'.toNaira => '₦1,000.00'
  String get toNaira {
    final number = double.tryParse(replaceAll(',', '')) ?? 0;
    final formatter = NumberFormat.currency(
      symbol: '₦',
      decimalDigits: 2,
    );
    return formatter.format(number);
  }

  /// Format as currency (US Dollar)
  /// Usage: '1000'.toDollar => '\$1,000.00'
  String get toDollar {
    final number = double.tryParse(replaceAll(',', '')) ?? 0;
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(number);
  }

  /// Format number with commas
  /// Usage: '1000000'.withCommas => '1,000,000'
  String get withCommas {
    final number = double.tryParse(replaceAll(',', '')) ?? 0;
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  /// Truncate string with ellipsis
  /// Usage: 'Hello World'.truncate(8) => 'Hello...'
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  // ============================================================================
  // PARSING
  // ============================================================================

  /// Parse string to int safely
  /// Usage: '123'.toIntOrNull => 123
  int? get toIntOrNull => int.tryParse(this);

  /// Parse string to double safely
  /// Usage: '123.45'.toDoubleOrNull => 123.45
  double? get toDoubleOrNull => double.tryParse(this);

  /// Parse string to DateTime safely
  /// Usage: '2024-01-01'.toDateTimeOrNull => DateTime(2024, 1, 1)
  DateTime? get toDateTimeOrNull => DateTime.tryParse(this);

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Reverse the string
  /// Usage: 'hello'.reversed => 'olleh'
  String get reversed => split('').reversed.join('');

  /// Check if string is empty or only whitespace
  /// Usage: '  '.isBlank => true
  bool get isBlank => trim().isEmpty;

  /// Check if string is not empty and not only whitespace
  /// Usage: 'hello'.isNotBlank => true
  bool get isNotBlank => !isBlank;

  /// Get initials from name (first letters of first and last name)
  /// Usage: 'John Doe'.initials => 'JD'
  String get initials {
    final words = trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return words.first.substring(0, 1).toUpperCase() +
        words.last.substring(0, 1).toUpperCase();
  }

  /// Mask string (useful for passwords, credit cards, etc.)
  /// Usage: 'password123'.mask(start: 4) => 'pass*******'
  String mask({
    int start = 0,
    int? end,
    String maskChar = '*',
  }) {
    if (start >= length) return this;
    final endIndex = end ?? length;
    final maskedPart = maskChar * (endIndex - start);
    return substring(0, start) + maskedPart + substring(endIndex);
  }

  /// Extract numbers from string
  /// Usage: 'abc123def456'.extractNumbers => '123456'
  String get extractNumbers {
    return replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Extract letters from string
  /// Usage: 'abc123def456'.extractLetters => 'abcdef'
  String get extractLetters {
    return replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }
}
