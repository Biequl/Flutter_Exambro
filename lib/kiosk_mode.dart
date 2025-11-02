import 'package:flutter/services.dart';

class KioskMode {
  static const MethodChannel _channel = MethodChannel('kioskModeLocked');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startKioskMode');
    } on PlatformException catch (e) {
      print('Failed to start kiosk mode: ${e.message}');
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopKioskMode');
    } on PlatformException catch (e) {
      print('Failed to stop kiosk mode: ${e.message}');
    }
  }
}
