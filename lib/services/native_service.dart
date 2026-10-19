import 'package:flutter/services.dart';

import '../config.dart';

/// Kleine native Helfer (E-Mail, Links) über den vorhandenen Kanal.
class NativeService {
  NativeService._();
  static const _ch = MethodChannel('zitatecke/whatsapp');

  static Future<bool> email({required String subject, String body = ''}) async {
    try {
      return await _ch.invokeMethod<bool>('email', {'to': kSupportEmail, 'subject': subject, 'body': body}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> open(String url) async {
    try {
      return await _ch.invokeMethod<bool>('open', {'url': url}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> deviceInfo() async {
    try {
      return await _ch.invokeMethod<String>('deviceInfo') ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> rateApp() => open('market://details?id=de.zitatecke.app');
}
