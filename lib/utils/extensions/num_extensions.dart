import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

/// Extension methods for num (int and double) to reduce boilerplate
extension NumExtensions on num {
  // ============================================================================
  // SIZED BOX HELPERS
  // ============================================================================

  /// Create horizontal spacing (SizedBox with width)
  /// Usage: 16.w => SizedBox(width: 16)
  SizedBox get w => SizedBox(width: toDouble());

  /// Create vertical spacing (SizedBox with height)
  /// Usage: 16.h => SizedBox(height: 16)
  SizedBox get h => SizedBox(height: toDouble());

  /// Create square spacing (SizedBox with width and height)
  /// Usage: 16.wh => SizedBox(width: 16, height: 16)
  SizedBox get wh => SizedBox(width: toDouble(), height: toDouble());

  // ============================================================================
  // DURATION HELPERS
  // ============================================================================

  /// Convert to Duration in milliseconds
  /// Usage: 500.milliseconds => Duration(milliseconds: 500)
  Duration get milliseconds => Duration(milliseconds: toInt());

  /// Convert to Duration in seconds
  /// Usage: 2.seconds => Duration(seconds: 2)
  Duration get seconds => Duration(seconds: toInt());

  /// Convert to Duration in minutes
  /// Usage: 5.minutes => Duration(minutes: 5)
  Duration get minutes => Duration(minutes: toInt());

  /// Convert to Duration in hours
  /// Usage: 1.hours => Duration(hours: 1)
  Duration get hours => Duration(hours: toInt());

  /// Convert to Duration in days
  /// Usage: 7.days => Duration(days: 7)
  Duration get days => Duration(days: toInt());

  // ============================================================================
  // EDGE INSETS HELPERS
  // ============================================================================

  /// Create EdgeInsets with all sides equal
  /// Usage: 16.padding => EdgeInsets.all(16)
  EdgeInsets get padding => EdgeInsets.all(toDouble());

  /// Create horizontal EdgeInsets
  /// Usage: 16.paddingH => EdgeInsets.symmetric(horizontal: 16)
  EdgeInsets get paddingH => EdgeInsets.symmetric(horizontal: toDouble());

  /// Create vertical EdgeInsets
  /// Usage: 16.paddingV => EdgeInsets.symmetric(vertical: 16)
  EdgeInsets get paddingV => EdgeInsets.symmetric(vertical: toDouble());

  /// Create EdgeInsets for left only
  /// Usage: 16.paddingLeft => EdgeInsets.only(left: 16)
  EdgeInsets get paddingLeft => EdgeInsets.only(left: toDouble());

  /// Create EdgeInsets for right only
  /// Usage: 16.paddingRight => EdgeInsets.only(right: 16)
  EdgeInsets get paddingRight => EdgeInsets.only(right: toDouble());

  /// Create EdgeInsets for top only
  /// Usage: 16.paddingTop => EdgeInsets.only(top: 16)
  EdgeInsets get paddingTop => EdgeInsets.only(top: toDouble());

  /// Create EdgeInsets for bottom only
  /// Usage: 16.paddingBottom => EdgeInsets.only(bottom: 16)
  EdgeInsets get paddingBottom => EdgeInsets.only(bottom: toDouble());

  // ============================================================================
  // BORDER RADIUS HELPERS
  // ============================================================================

  /// Create circular BorderRadius
  /// Usage: 12.radius => BorderRadius.circular(12)
  BorderRadius get radius => BorderRadius.circular(toDouble());

  /// Create Radius.circular
  /// Usage: 12.circular => Radius.circular(12)
  Radius get circular => Radius.circular(toDouble());

  // ============================================================================
  // PERCENTAGE CALCULATIONS
  // ============================================================================

  /// Calculate percentage of a number
  /// Usage: 100.percent(50) => 50.0 (50% of 100)
  double percent(num percentage) => this * (percentage / 100);

  /// Get percentage value
  /// Usage: 50.percentOf(100) => 50.0 (50 is 50% of 100)
  double percentOf(num total) => (this / total) * 100;

  // ============================================================================
  // CURRENCY FORMATTING
  // ============================================================================

  /// Format as Nigerian Naira
  /// Usage: 1000.toNaira => '₦1,000.00'
  String get toNaira {
    final formatter = NumberFormat.currency(
      symbol: '₦',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }

  /// Format as US Dollar
  /// Usage: 1000.toDollar => '\$1,000.00'
  String get toDollar {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }

  /// Format with commas (no currency symbol)
  /// Usage: 1000000.withCommas => '1,000,000'
  String get withCommas {
    final formatter = NumberFormat('#,###');
    return formatter.format(this);
  }

  /// Format with commas and decimals
  /// Usage: 1000.5.withDecimals => '1,000.50'
  String get withDecimals {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(this);
  }

  // ============================================================================
  // NUMBER UTILITIES
  // ============================================================================

  /// Check if number is between two values (inclusive)
  /// Usage: 5.isBetween(1, 10) => true
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Clamp number between min and max
  /// Usage: 15.clampTo(0, 10) => 10
  num clampTo(num min, num max) => clamp(min, max);

  /// Check if the integer part of this number is even.
  /// Works on both int and double (uses toInt() for conversion).
  /// For integers, prefer using the built-in `isEven` property directly.
  /// Usage: 4.5.hasEvenIntValue => true (4 is even)
  bool get hasEvenIntValue => toInt() % 2 == 0;

  /// Check if the integer part of this number is odd.
  /// Works on both int and double (uses toInt() for conversion).
  /// For integers, prefer using the built-in `isOdd` property directly.
  /// Usage: 5.5.hasOddIntValue => true (5 is odd)
  bool get hasOddIntValue => toInt() % 2 != 0;

  /// Check if number is positive
  /// Usage: 5.isPositive => true
  bool get isPositive => this > 0;

  /// Check if number is negative
  /// Usage: -5.isNegative => true
  bool get isNegative => this < 0;

  /// Check if number is zero
  /// Usage: 0.isZero => true
  bool get isZero => this == 0;

  // ============================================================================
  // OPACITY HELPERS
  // ============================================================================

  /// Convert to opacity value (0.0 to 1.0)
  /// Usage: 50.opacity => 0.5 (50%)
  double get opacity => (this / 100).clamp(0.0, 1.0);

  // ============================================================================
  // TIME FORMATTING
  // ============================================================================

  /// Format seconds as MM:SS
  /// Usage: 125.toMMSS => '02:05'
  String get toMMSS {
    final minutes = (this / 60).floor();
    final seconds = (this % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format seconds as HH:MM:SS
  /// Usage: 3665.toHHMMSS => '01:01:05'
  String get toHHMMSS {
    final hours = (this / 3600).floor();
    final minutes = ((this % 3600) / 60).floor();
    final seconds = (this % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // SIZE HELPERS
  // ============================================================================

  /// Convert bytes to KB
  /// Usage: 1024.toKB => 1.0
  double get toKB => this / 1024;

  /// Convert bytes to MB
  /// Usage: 1048576.toMB => 1.0
  double get toMB => this / (1024 * 1024);

  /// Convert bytes to GB
  /// Usage: 1073741824.toGB => 1.0
  double get toGB => this / (1024 * 1024 * 1024);

  /// Format bytes to human readable string
  /// Usage: 1536.toHumanReadableSize => '1.5 KB'
  String get toHumanReadableSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
