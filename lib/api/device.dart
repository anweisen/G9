import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

String formatBrowserName(BrowserName browserName) {
  switch (browserName) {
    case BrowserName.chrome: return "Chrome";
    case BrowserName.edge: return "Edge";
    case BrowserName.firefox: return "Firefox";
    case BrowserName.safari: return "Safari";
    case BrowserName.opera: return "Opera";
    case BrowserName.msie: return "Internet Explorer";
    case BrowserName.samsungInternet: return "Samsung Internet";
    default: return "Unknown Browser";
  }
}

Future<String> getDeviceName() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (kIsWeb) {
    WebBrowserInfo web = await deviceInfo.webBrowserInfo;
    // Result: "Chrome 122 (Windows)"
    return "${formatBrowserName(web.browserName)} (${web.platform})";
  }

  if (Platform.isAndroid) {
    AndroidDeviceInfo android = await deviceInfo.androidInfo;
    // Result: "Samsung SM-S911B (Android 14)"
    return "${android.manufacturer} ${android.model} (Android ${android.version.release})";
  }

  if (Platform.isIOS) {
    IosDeviceInfo ios = await deviceInfo.iosInfo;
    // Result: "iPhone 15 Pro (iOS 17.2)"
    return "${ios.name} (${ios.systemName} ${ios.systemVersion})";
  }

  if (Platform.isMacOS) {
    MacOsDeviceInfo mac = await deviceInfo.macOsInfo;
    // Result: "MacBook Pro - macOS 14.1"
    return "${mac.computerName} (${mac.osRelease})";
  }

  if (Platform.isWindows) {
    WindowsDeviceInfo win = await deviceInfo.windowsInfo;
    // Result: "OFFICE-PC (Windows 10.0.19045)"
    return "${win.computerName} (Windows)";
  }

  if (Platform.isLinux) {
    LinuxDeviceInfo linux = await deviceInfo.linuxInfo;
    // Result: "Ubuntu 22.04 (jammy)"
    return "${linux.name} ${linux.version ?? ''}";
  }

  return "Unknown Device";
}
