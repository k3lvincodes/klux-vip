import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CustomToast {
  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
      title: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      alignment: Alignment.topCenter,
      animationDuration: const Duration(milliseconds: 300),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: lowModeShadow,
      showProgressBar: false,
    );
  }

  static void showError(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
      title: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      alignment: Alignment.topCenter,
      animationDuration: const Duration(milliseconds: 300),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: lowModeShadow,
      showProgressBar: false,
    );
  }

  static void showInfo(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
      title: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      alignment: Alignment.topCenter,
      animationDuration: const Duration(milliseconds: 300),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: lowModeShadow,
      showProgressBar: false,
    );
  }
}
