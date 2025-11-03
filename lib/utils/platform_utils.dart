import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static String getLocalHostUrl(String port, {String path = '', String? fallback}) {
    if (kIsWeb) {
      return fallback ?? 'http://localhost:$port$path';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port$path';
    }

    if (Platform.isIOS) {
      return 'http://localhost:$port$path';
    }

    return 'http://localhost:$port$path';
  }

  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web';
    }

    if (Platform.isAndroid) {
      return 'Android ${Platform.operatingSystemVersion}';
    }

    if (Platform.isIOS) {
      return 'iOS ${Platform.operatingSystemVersion}';
    }

    if (Platform.isMacOS) {
      return 'macOS ${Platform.operatingSystemVersion}';
    }

    if (Platform.isWindows) {
      return 'Windows ${Platform.operatingSystemVersion}';
    }

    if (Platform.isLinux) {
      return 'Linux ${Platform.operatingSystemVersion}';
    }

    return 'Unknown ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  static String transformLocalHostUrl(String url) {
    if (url.contains('localhost')) {
      if (Platform.isAndroid) {
        return url.replaceAll('localhost', '10.0.2.2');
      }
      if (Platform.isIOS && url.contains('10.0.2.2')) {
        return url.replaceAll('10.0.2.2', 'localhost');
      }
    }

    if (url.contains('ngrok.io')) {
      if (!url.startsWith('https://') && !url.startsWith('http://')) {
        return 'https://$url';
      }
      if (url.startsWith('http://')) {
        return url.replaceFirst('http://', 'https://');
      }
    }

    return url;
  }

  static bool get isEmulator {
    if (kIsWeb) return false;

    if (Platform.isAndroid || Platform.isIOS) {
      final deviceModel = Platform.isIOS ? 'Simulator' : 'emulator';
      return Platform.environment.containsKey(deviceModel) ||
             Platform.environment.toString().toLowerCase().contains('emulator');
    }

    return false;
  }
}
