import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/pairing.dart';
import '../services/totp_service.dart';

class PairingCard extends StatefulWidget {
  final Pairing pairing;
  final VoidCallback onDelete;
  final Function(String newPartnerName) onEdit;

  const PairingCard({
    super.key,
    required this.pairing,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<PairingCard> createState() => _PairingCardState();
}

class _PairingCardState extends State<PairingCard> {
  String _currentCode = '';
  int _remainingSeconds = 60;
  bool _isEditing = false;
  bool _disposed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateCode();
    _startTimer();
  }

  @override
  void didUpdateWidget(PairingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_disposed || _isEditing) return;
    
    if (oldWidget.pairing.secret != widget.pairing.secret) {
      _updateCode();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_disposed && !_isEditing) {
        _updateCode();
      }
    });
  }

  void _updateCode() {
    if (_disposed || _isEditing) return;
    
    try {
      final code = TOTPService.generateTOTP(widget.pairing.secret);
      final remaining = TOTPService.getRemainingSeconds();
      
      if (!_disposed && !_isEditing) {
        setState(() {
          _currentCode = code;
          _remainingSeconds = remaining;
        });
      }
    } catch (e) {
      if (!_disposed && !_isEditing) {
        setState(() {
          _currentCode = 'ERROR';
          _remainingSeconds = 0;
        });
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _currentCode));
    if (!_disposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _showEditDialog() async {
    if (_disposed) return;

    final TextEditingController partnerNameController = TextEditingController(
      text: widget.pairing.partnerName,
    );

    try {
      setState(() {
        _isEditing = true;
      });

      final String? result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async {
              // Ensure keyboard is dismissed before popping
              FocusManager.instance.primaryFocus?.unfocus();
              return false;
            },
            child: AlertDialog(
              title: const Text('Edit Partner Name'),
              content: TextFormField(
                controller: partnerNameController,
                decoration: const InputDecoration(
                  labelText: 'Partner Name',
                  hintText: 'Enter partner name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                // Handle keyboard submission
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.of(dialogContext).pop(value.trim());
                  }
                },
                // Handle focus changes
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ensure keyboard is dismissed before popping
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newName = partnerNameController.text.trim();
                    if (newName.isNotEmpty) {
                      // Ensure keyboard is dismissed before popping
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(dialogContext).pop(newName);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      );

      // Handle the result
      if (!_disposed && result != null && result.trim().isNotEmpty) {
        widget.onEdit(result.trim());
      }
    } finally {
      // Ensure keyboard is dismissed and controller is disposed
      FocusManager.instance.primaryFocus?.unfocus();
      partnerNameController.dispose();
      if (!_disposed) {
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building PairingCard for: ${widget.pairing.partnerName}'); // Debug log
    final theme = Theme.of(context);
    final isError = _currentCode == 'ERROR';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pairing.partnerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _showEditDialog,
                  tooltip: 'Edit partner name',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete pairing',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _copyCode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _currentCode,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: isError ? Colors.red : null,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      'Expires in',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingSeconds <= 5
                            ? Colors.red.withOpacity(0.1)
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _remainingSeconds <= 5
                              ? Colors.red.withOpacity(0.3)
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '${_remainingSeconds}s',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds <= 5 ? Colors.red : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _remainingSeconds / 30,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingSeconds <= 5 ? Colors.red : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 