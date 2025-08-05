import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/pairing.dart';
import '../services/storage_service.dart';
import '../services/totp_service.dart';

class ScanPairScreen extends StatefulWidget {
  const ScanPairScreen({super.key});

  @override
  State<ScanPairScreen> createState() => _ScanPairScreenState();
}

class _ScanPairScreenState extends State<ScanPairScreen> {
  bool _isProcessing = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.qrCode],
        returnImage: false,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String rawValue) async {
    if (_isProcessing) return;

    print('DEBUG: QR Code detected: $rawValue'); // Debug log

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simple parsing - just extract secret from otpauth:// format
      String? secret;
      String? partnerName;
      
      if (rawValue.startsWith('otpauth://totp/')) {
        print('DEBUG: Parsing otpauth format'); // Debug log
        
        // Simple extraction of secret from otpauth:// format
        final secretMatch = RegExp(r'secret=([A-Z2-7]+)').firstMatch(rawValue);
        if (secretMatch != null) {
          secret = secretMatch.group(1);
          print('DEBUG: Secret extracted: $secret'); // Debug log
        }
        
        // Extract name from the URI
        final nameMatch = RegExp(r'otpauth://totp/[^:]+:([^?]+)').firstMatch(rawValue);
        if (nameMatch != null) {
          partnerName = nameMatch.group(1);
          print('DEBUG: Partner name extracted: $partnerName'); // Debug log
        }
      }
      
      if (secret == null) {
        print('DEBUG: No valid secret found'); // Debug log
        _showError('Invalid QR code: No valid secret found');
        return;
      }

      if (!TOTPService.isValidSecret(secret)) {
        print('DEBUG: Invalid secret format: $secret'); // Debug log
        _showError('Invalid QR code: Invalid secret format');
        return;
      }

      print('DEBUG: Secret is valid, proceeding with pairing'); // Debug log

      // Stop the scanner while we collect information
      if (!kIsWeb) {
        _controller?.stop();
      }

      // Get or prompt for user name
      String? myName = await StorageService.getUserName();
      if (myName == null || myName.isEmpty) {
        myName = await _showSimpleNameDialog('Enter Your Name');
        if (myName == null || myName.isEmpty) {
          _showError('Name is required');
          if (!kIsWeb) {
            _controller?.start();
          }
          return;
        }
        await StorageService.saveUserName(myName);
      }

      // Use partner name from QR or prompt for it
      if (partnerName == null || partnerName.isEmpty) {
        partnerName = await _showSimpleNameDialog('Enter Partner Name');
        if (partnerName == null || partnerName.isEmpty) {
          _showError('Partner name is required');
          if (!kIsWeb) {
            _controller?.start();
          }
          return;
        }
      }

      print('DEBUG: Creating pairing with myName: $myName, partnerName: $partnerName'); // Debug log

      // Create and save the pairing
      final pairing = Pairing.create(
        secret: secret,
        myName: myName,
        partnerName: partnerName,
      );

      await StorageService.savePairing(pairing);
      
      print('DEBUG: Pairing saved successfully'); // Debug log

      if (!mounted) return;

      // Show success message before closing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pairing added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a moment for the user to see the success message
      await Future.delayed(const Duration(seconds: 1));

      // Return success and close the screen
      Navigator.of(context).pop(true);
    } catch (e) {
      print('DEBUG: Error processing QR code: $e'); // Debug log
      if (!mounted) return;
      _showError('Failed to process QR code: $e');
      if (!kIsWeb) {
        _controller?.start();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Mobile scanner detection handler
  Future<void> _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    await _processQRCode(rawValue);
  }

  Future<String?> _showSimpleNameDialog(String title) async {
    final TextEditingController nameController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(dialogContext).pop(name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version - show a message that QR scanning is not available on web
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'QR Code Scanning',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'QR code scanning is not available on web browsers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Please use the mobile app to scan QR codes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing QR Code...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 