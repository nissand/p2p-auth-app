import 'dart:math';
import 'dart:typed_data';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';

class TOTPService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    _initialized = true;
  }

  // Generate a random secret key for TOTP
  static String generateSecret() {
    if (!_initialized) {
      throw Exception('TOTPService not initialized');
    }

    // Generate 20 random bytes (160 bits) for the secret
    final random = Random.secure();
    final bytes = Uint8List.fromList(List<int>.generate(20, (i) => random.nextInt(256)));
    
    // Encode as base32 (standard for TOTP secrets)
    return base32.encode(bytes);
  }

  // Generate TOTP code from secret
  static String generateTOTP(String secret) {
    if (!_initialized) {
      throw Exception('TOTPService not initialized');
    }

    try {
      // Generate TOTP with 30-second interval and 6 digits
      final code = OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      
      return code;
    } catch (e) {
      throw Exception('Failed to generate TOTP: $e');
    }
  }

  // Get remaining seconds until next code
  static int getRemainingSeconds() {
    final now = DateTime.now();
    final seconds = now.second;
    return 30 - (seconds % 30);
  }

  // Validate if a secret is properly formatted
  static bool isValidSecret(String secret) {
    try {
      // Remove any whitespace and convert to uppercase
      final cleanSecret = secret.trim().toUpperCase();
      
      // Check if it's empty
      if (cleanSecret.isEmpty) {
        return false;
      }
      
      // Check if it contains only valid base32 characters (A-Z, 2-7)
      if (!RegExp(r'^[A-Z2-7]+$').hasMatch(cleanSecret)) {
        return false;
      }
      
      // Check if it's exactly 32 characters long
      if (cleanSecret.length != 32) {
        return false;
      }
      
      // Check if it's a valid base32 string
      base32.decode(cleanSecret);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get validation error message for a secret
  static String? getSecretValidationError(String secret) {
    final cleanSecret = secret.trim().toUpperCase();
    
    if (cleanSecret.isEmpty) {
      return 'Secret key cannot be empty';
    }
    
    if (!RegExp(r'^[A-Z2-7]+$').hasMatch(cleanSecret)) {
      return 'Secret key must contain only letters A-Z and numbers 2-7';
    }
    
    if (cleanSecret.length != 32) {
      return 'Secret key must be exactly 32 characters long';
    }
    
    try {
      base32.decode(cleanSecret);
    } catch (e) {
      return 'Invalid base32 format';
    }
    
    return null; // No error
  }

  // Generate QR code data in otpauth:// format
  static String generateQRData(String secret, {String? label}) {
    final issuer = 'P2PAuth';
    final account = label ?? 'Partner';
    
    return 'otpauth://totp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=SHA1&digits=6&period=30';
  }

  // Parse QR code data to extract secret and name
  static Map<String, String>? parseQRData(String qrData) {
    try {
      if (qrData.startsWith('otpauth://totp/')) {
        final uri = Uri.parse(qrData);
        final secret = uri.queryParameters['secret'];
        if (secret != null && isValidSecret(secret)) {
          // Extract name from the URI path (format: otpauth://totp/Issuer:Name)
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final lastSegment = pathSegments.last;
            final nameParts = lastSegment.split(':');
            final name = nameParts.length > 1 ? nameParts[1] : null;
            
            return {
              'secret': secret,
              'name': name ?? '',
            };
          }
          return {
            'secret': secret,
            'name': '',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
} 