import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CustomToast {
  static void _show({
    required BuildContext context,
    required ToastificationType type,
    required String message,
    String? description,
    Duration duration = const Duration(seconds: 3),
    Alignment alignment = Alignment.topCenter,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: duration,
      title: Text(
        message,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      description: description != null
          ? Text(
              description,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      alignment: alignment,
      animationDuration: const Duration(milliseconds: 250),
      borderRadius: BorderRadius.circular(12),
      boxShadow: lowModeShadow,
      showProgressBar: false,
      closeOnClick: true,
      pauseOnHover: false,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
  }) {
    _show(
      context: context,
      type: ToastificationType.success,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
  }) {
    _show(
      context: context,
      type: ToastificationType.error,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
  }) {
    _show(
      context: context,
      type: ToastificationType.info,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? description,
    Duration? duration,
  }) {
    _show(
      context: context,
      type: ToastificationType.warning,
      message: message,
      description: description,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
}
