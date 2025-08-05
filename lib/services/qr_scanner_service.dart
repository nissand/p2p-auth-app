import 'dart:io';
import 'package:flutter/foundation.dart';

class QRScannerService {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  static String get platformName {
    if (isWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }
  
  static bool get supportsQRScanning {
    return isMobile; // QR scanning only works on mobile platforms
  }
} 