import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pairing.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _pairingsKey = 'pairings';
  static const String _userNameKey = 'user_name';

  static Future<void> initialize() async {
    // Initialize secure storage
    await _storage.write(key: 'initialized', value: 'true');
  }

  // Save a pairing to secure storage
  static Future<void> savePairing(Pairing pairing) async {
    try {
      final List<Pairing> pairings = await getPairings();
      
      // Check if pairing with this ID already exists
      final existingIndex = pairings.indexWhere((p) => p.id == pairing.id);
      if (existingIndex != -1) {
        pairings[existingIndex] = pairing;
      } else {
        pairings.add(pairing);
      }

      final String pairingsJson = jsonEncode(
        pairings.map((p) => p.toJson()).toList(),
      );
      
      await _storage.write(key: _pairingsKey, value: pairingsJson);
    } catch (e) {
      throw Exception('Failed to save pairing: $e');
    }
  }

  // Get all pairings from secure storage
  static Future<List<Pairing>> getPairings() async {
    try {
      final String? pairingsJson = await _storage.read(key: _pairingsKey);
      
      if (pairingsJson == null || pairingsJson.isEmpty) {
        return [];
      }

      final List<dynamic> pairingsList = jsonDecode(pairingsJson);
      return pairingsList
          .map((json) => Pairing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load pairings: $e');
    }
  }

  // Delete a pairing by ID
  static Future<void> deletePairing(String id) async {
    try {
      final List<Pairing> pairings = await getPairings();
      pairings.removeWhere((p) => p.id == id);
      
      final String pairingsJson = jsonEncode(
        pairings.map((p) => p.toJson()).toList(),
      );
      
      await _storage.write(key: _pairingsKey, value: pairingsJson);
    } catch (e) {
      throw Exception('Failed to delete pairing: $e');
    }
  }

  // Clear all pairings
  static Future<void> clearAllPairings() async {
    try {
      await _storage.delete(key: _pairingsKey);
    } catch (e) {
      throw Exception('Failed to clear pairings: $e');
    }
  }

  // Save user's name
  static Future<void> saveUserName(String name) async {
    try {
      await _storage.write(key: _userNameKey, value: name);
    } catch (e) {
      throw Exception('Failed to save user name: $e');
    }
  }

  // Get user's name
  static Future<String?> getUserName() async {
    try {
      return await _storage.read(key: _userNameKey);
    } catch (e) {
      throw Exception('Failed to get user name: $e');
    }
  }
} 