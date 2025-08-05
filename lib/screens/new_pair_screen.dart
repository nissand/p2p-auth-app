import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/pairing.dart';
import '../services/storage_service.dart';
import '../services/totp_service.dart';

class NewPairScreen extends StatefulWidget {
  const NewPairScreen({super.key});

  @override
  State<NewPairScreen> createState() => _NewPairScreenState();
}

class _NewPairScreenState extends State<NewPairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _partnerNameFocusNode = FocusNode();
  
  String? _secret;
  String? _qrData;
  bool _isGenerating = false;
  bool _showQRCode = false;
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    _partnerNameController.dispose();
    _userNameController.dispose();
    _partnerNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final savedName = await StorageService.getUserName();
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _userNameController.text = savedName;
        });
        // Focus on partner name field if user name is already filled
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Add a small delay to prevent keyboard snapshot warnings
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _partnerNameFocusNode.requestFocus();
              }
            });
          }
        });
      }
    } catch (e) {
      // Ignore errors when loading user name
    } finally {
      setState(() {
        _isLoadingName = false;
      });
    }
  }

  Future<void> _generateNewPairing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final secret = TOTPService.generateSecret();
      final userName = _userNameController.text.trim();
      final partnerName = _partnerNameController.text.trim();
      
      // Save the user's name for future use
      await StorageService.saveUserName(userName);
      
      // Create and save the pairing immediately
      final pairing = Pairing.create(
        secret: secret,
        myName: userName,
        partnerName: partnerName,
      );
      
      await StorageService.savePairing(pairing);
      
      final qrData = TOTPService.generateQRData(secret, label: userName);
      
      setState(() {
        _secret = secret;
        _qrData = qrData;
        _isGenerating = false;
        _showQRCode = true;
      });
      
      _showSuccessSnackBar('QR Code generated and saved successfully');
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showErrorSnackBar('Failed to generate pairing: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Create QR Code'),
        actions: [
          if (_showQRCode && _secret != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Done'),
            ),
        ],
      ),
      body: _isGenerating || _isLoadingName
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showQRCode) ...[
                      // Step 1: User Details Form
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Information',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _userNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Your Name *',
                                  hintText: 'e.g., Alice',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _partnerNameController,
                                focusNode: _partnerNameFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Partner Name *',
                                  hintText: 'e.g., Bob',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter partner name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _generateNewPairing,
                                  child: const Text('Generate QR Code'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Step 2: QR Code Display
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'QR Code for ${_partnerNameController.text.trim()}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _showQRCode = false;
                                      });
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: _qrData != null
                                      ? QrImageView(
                                          data: _qrData!,
                                          version: QrVersions.auto,
                                          size: 200,
                                          backgroundColor: Colors.white,
                                        )
                                      : const SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: Center(
                                            child: Text('No QR data'),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Instructions',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Have your partner click scan QR code button\n'
                              '2. Have them scan the QR above\n'
                              '3. Both devices will show the same code\n'
                              '4. Use this code to verify each other\n'
                              '5. Click Done',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32), // Add extra bottom padding for keyboard
                  ],
                ),
              ),
            ),
    );
  }
} 