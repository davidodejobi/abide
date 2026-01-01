import 'package:flutter/material.dart';
import 'package:open_baptist_hymnal/utils/extensions/context_extensions.dart';
import 'package:toastification/toastification.dart';

enum ToastType { success, error, warning, info }

class ToastHelper {
  ToastHelper._();

  // Track active toast to prevent duplicates
  static ToastificationItem? _activeToast;

  static void show({
    required BuildContext context,
    required String message,
    required ToastType type,
    Duration? duration,
    bool dismissPrevious = true,
  }) {
    // Dismiss previous toast if requested
    if (dismissPrevious && _activeToast != null) {
      toastification.dismiss(_activeToast!);
      _activeToast = null;
    }

    _activeToast = toastification.show(
      context: context,
      type: _getToastificationType(type),
      style: ToastificationStyle.flat,
      title: Text(
        message,
        style: context.textStyles.body,
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(20.0),
      applyBlurEffect: true,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      callbacks: ToastificationCallbacks(
        onDismissed: (item) => _activeToast = null,
      ),
    );
  }

  static void success(BuildContext context, String message,
      {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  static void error(BuildContext context, String message,
      {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.error,
      duration: duration,
    );
  }

  static void warning(BuildContext context, String message,
      {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  static void info(BuildContext context, String message, {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.info,
      duration: duration,
    );
  }

  static ToastificationType _getToastificationType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return ToastificationType.success;
      case ToastType.error:
        return ToastificationType.error;
      case ToastType.warning:
        return ToastificationType.warning;
      case ToastType.info:
        return ToastificationType.info;
    }
  }
}
