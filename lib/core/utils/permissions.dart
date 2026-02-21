import 'package:permission_handler/permission_handler.dart';

/// Centralized permission handling for the app.
/// Handles microphone, location, and other runtime permissions.
class AppPermissions {
  AppPermissions._();

  /// Check if microphone permission is granted.
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission.
  /// Returns true if granted, false otherwise.
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check microphone permission and request if denied.
  /// Returns true if we have permission (either already or after request).
  static Future<bool> ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    if (status.isPermanentlyDenied) {
      await openSettings();
      return false;
    }
    return false;
  }

  /// Check if speech recognition permission is granted (iOS).
  static Future<bool> hasSpeechRecognitionPermission() async {
    final status = await Permission.speech.status;
    return status.isGranted;
  }

  /// Request speech recognition permission (iOS).
  static Future<bool> requestSpeechRecognitionPermission() async {
    final status = await Permission.speech.request();
    return status.isGranted;
  }

  /// Open app settings for user to manually grant permissions.
  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}
