import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pairing.dart';
import '../services/storage_service.dart';
import '../widgets/pairing_card.dart';
import '../widgets/empty_state.dart';
import 'new_pair_screen.dart';
import 'scan_pair_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Pairing> _pairings = [];
  List<Pairing> _filteredPairings = [];
  bool _isLoading = true;
  bool _isEditing = false;
  Timer? _timer;
  Timer? _editDebounceTimer;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPairings();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh the list when the app becomes active (user returns to the app)
    if (state == AppLifecycleState.resumed && mounted && !_isLoading) {
      _loadPairings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _editDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startTimer() {
    // Update every second to refresh countdown timers
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isLoading && !_isEditing) {
        // Use a more defensive approach
        try {
          setState(() {
            // Trigger rebuild to update countdown timers
          });
        } catch (e) {
          // If setState fails, cancel the timer
          timer.cancel();
        }
      }
    });
  }

  Future<void> _loadPairings() async {
    print('DEBUG: Loading pairings...'); // Debug log
    try {
      final pairings = await StorageService.getPairings();
      print('DEBUG: Loaded ${pairings.length} pairings'); // Debug log
      
      if (mounted) {
        setState(() {
          _pairings = pairings;
          _filteredPairings = pairings;
          _isLoading = false;
        });
        _filterPairings();
        print('DEBUG: Pairings loaded successfully'); // Debug log
      } else {
        print('DEBUG: Widget not mounted, skipping setState'); // Debug log
      }
    } catch (e) {
      print('DEBUG: Error loading pairings: $e'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load pairings: $e');
      }
    }
  }

  void _filterPairings() {
    if (!mounted) return;
    
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredPairings = _pairings;
      });
    } else {
      setState(() {
        _filteredPairings = _pairings.where((pairing) {
          return pairing.partnerName.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  Future<void> _refreshPairings() async {
    await _loadPairings();
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

  Future<void> _deletePairing(Pairing pairing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pairing'),
        content: Text('Are you sure you want to delete pairing with "${pairing.partnerName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageService.deletePairing(pairing.id);
        if (mounted) {
          await _loadPairings();
          if (mounted) {
            _showSuccessSnackBar('Pairing deleted successfully');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to delete pairing: $e');
        }
      }
    }
  }

  Future<void> _editPairing(Pairing pairing, String newPartnerName) async {
    if (!mounted || _isEditing) return;
    
    // Cancel any pending edit operation
    _editDebounceTimer?.cancel();
    
    // Set editing flag first
    if (mounted) {
      setState(() {
        _isEditing = true;
      });
    }
    
    // Add a small delay to prevent rapid successive calls
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    
    try {
      // Create a new pairing with the updated partner name using copyWith
      final updatedPairing = pairing.copyWith(
        partnerName: newPartnerName,
      );
      
      // Save the pairing
      await StorageService.savePairing(updatedPairing);
      
      // Only proceed if still mounted
      if (!mounted) return;
      
      // Reload pairings
      await _loadPairings();
      
      // Show success message only if still mounted
      if (mounted) {
        _showSuccessSnackBar('Partner name updated successfully');
      }
    } catch (e) {
      // Show error message only if still mounted
      if (mounted) {
        _showErrorSnackBar('Failed to update partner name: $e');
      }
    } finally {
      // Reset editing flag only if still mounted
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  void _navigateToNewPair() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NewPairScreen()),
    );

    // Always refresh the list when returning, regardless of result
    if (mounted) {
      await _loadPairings();
      if (result == true && mounted) {
        _showSuccessSnackBar('New pairing created successfully');
      }
    }
  }

  void _navigateToScanPair() async {
    print('DEBUG: Navigating to scan pair screen'); // Debug log
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ScanPairScreen()),
    );

    print('DEBUG: Scan pair screen returned: $result'); // Debug log

    // Always refresh the list when returning, regardless of result
    if (mounted) {
      print('DEBUG: Reloading pairings after scan'); // Debug log
      await _loadPairings();
      if (result == true && mounted) {
        _showSuccessSnackBar('Pairing scanned successfully');
      }
    } else {
      print('DEBUG: Widget not mounted after scan'); // Debug log
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building home screen, isLoading: $_isLoading, pairings: ${_pairings.length}, filtered: ${_filteredPairings.length}'); // Debug log
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPairings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pairings.isEmpty
              ? EmptyState(
                  onNewPair: _navigateToNewPair,
                  onScanPair: _navigateToScanPair,
                )
              : Column(
                  children: [
                    // Search Box
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by partner name...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterPairings();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        onChanged: (value) {
                          _filterPairings();
                        },
                      ),
                    ),
                    // Pairings List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshPairings,
                        child: _filteredPairings.isEmpty && _searchController.text.isNotEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pairings found',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try a different search term',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredPairings.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.qr_code_scanner,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No pairings yet',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Scan a QR code or create a new pairing to get started',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _navigateToNewPair,
                                              icon: const Icon(Icons.add),
                                              label: const Text('Create QR Code'),
                                            ),
                                            const SizedBox(width: 16),
                                            ElevatedButton.icon(
                                              onPressed: _navigateToScanPair,
                                              icon: const Icon(Icons.qr_code_scanner),
                                              label: const Text('Scan QR'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    key: ValueKey('pairings_${_filteredPairings.length}'),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _filteredPairings.length,
                                    itemBuilder: (context, index) {
                                      final pairing = _filteredPairings[index];
                                      print('DEBUG: Building pairing card for: ${pairing.partnerName}'); // Debug log
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: PairingCard(
                                          pairing: pairing,
                                          onDelete: () => _deletePairing(pairing),
                                          onEdit: (newPartnerName) => _editPairing(pairing, newPartnerName),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _pairings.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToNewPair,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Create QR Code'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToScanPair,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
} 