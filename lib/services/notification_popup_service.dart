import 'package:flutter/material.dart';
import '../widgets/common/center_notification_popup.dart';

class NotificationPopupService {
  static final NotificationPopupService _instance =
      NotificationPopupService._internal();
  factory NotificationPopupService() => _instance;
  NotificationPopupService._internal();

  /// Show success notification popup
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onClose,
  }) {
    CenterNotificationPopup.show(
      context,
      message: message,
      style: NotificationStyle.success,
      duration: duration,
      onClose: onClose,
    );
  }

  /// Show error notification popup
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onClose,
  }) {
    CenterNotificationPopup.show(
      context,
      message: message,
      style: NotificationStyle.error,
      duration: duration,
      onClose: onClose,
    );
  }

  /// Show warning notification popup
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onClose,
  }) {
    CenterNotificationPopup.show(
      context,
      message: message,
      style: NotificationStyle.warning,
      duration: duration,
      onClose: onClose,
    );
  }

  /// Show info notification popup
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onClose,
  }) {
    CenterNotificationPopup.show(
      context,
      message: message,
      style: NotificationStyle.info,
      duration: duration,
      onClose: onClose,
    );
  }

  /// Show custom notification popup
  static void showCustom(
    BuildContext context,
    String message, {
    NotificationStyle style = NotificationStyle.info,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onClose,
    IconData? customIcon,
  }) {
    CenterNotificationPopup.show(
      context,
      message: message,
      style: style,
      duration: duration,
      onClose: onClose,
      customIcon: customIcon,
    );
  }

  /// Convenience method to replace SnackBar calls
  /// Automatically determines style based on backgroundColor
  static void showFromSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onClose,
  }) {
    NotificationStyle style = NotificationStyle.info;

    // Determine style based on common SnackBar background colors
    if (backgroundColor != null) {
      if (backgroundColor == Colors.green ||
          backgroundColor.toString().contains('success') ||
          backgroundColor.toString().contains('4CAF50')) {
        style = NotificationStyle.success;
      } else if (backgroundColor == Colors.red ||
          backgroundColor.toString().contains('error') ||
          backgroundColor.toString().contains('F44336')) {
        style = NotificationStyle.error;
      } else if (backgroundColor == Colors.orange ||
          backgroundColor.toString().contains('warning') ||
          backgroundColor.toString().contains('FF9800')) {
        style = NotificationStyle.warning;
      }
    }

    CenterNotificationPopup.show(
      context,
      message: message,
      style: style,
      duration: duration,
      onClose: onClose,
    );
  }
}
