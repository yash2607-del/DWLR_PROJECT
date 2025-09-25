import 'dart:convert';
import 'package:flutter/services.dart';

/// Service to get coordinates for stations from the existing JSON file
/// This bridges the gap between the IndiaWRIS API (which doesn't provide coordinates)
/// and our need to display stations on the map
class StationCoordinatesService {
  static Map<String, Map<String, double>>? _coordinatesCache;

  /// Load station coordinates from the existing JSON file
  static Future<Map<String, Map<String, double>>> _loadCoordinates() async {
    if (_coordinatesCache != null) {
      return _coordinatesCache!;
    }

    try {
      final String response = await rootBundle.loadString(
        'lib/mapData/water_stations.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> stationsJson = data['stations'] ?? [];

      _coordinatesCache = <String, Map<String, double>>{};

      for (final stationData in stationsJson) {
        final String stationCode =
            stationData['station_code']?.toString() ?? '';
        final double lat = (stationData['lat'] ?? 0.0).toDouble();
        final double long = (stationData['long'] ?? 0.0).toDouble();

        if (stationCode.isNotEmpty && lat != 0.0 && long != 0.0) {
          _coordinatesCache![stationCode] = {'lat': lat, 'long': long};
        }
      }

      print('Loaded coordinates for ${_coordinatesCache!.length} stations');
      return _coordinatesCache!;
    } catch (e) {
      print('Error loading station coordinates: $e');
      return {};
    }
  }

  /// Get coordinates for a specific station code
  static Future<Map<String, double>?> getCoordinates(String stationCode) async {
    final coordinates = await _loadCoordinates();
    return coordinates[stationCode];
  }

  /// Get coordinates for multiple station codes
  static Future<Map<String, Map<String, double>>> getMultipleCoordinates(
    List<String> stationCodes,
  ) async {
    final allCoordinates = await _loadCoordinates();
    final result = <String, Map<String, double>>{};

    for (final stationCode in stationCodes) {
      if (allCoordinates.containsKey(stationCode)) {
        result[stationCode] = allCoordinates[stationCode]!;
      }
    }

    return result;
  }

  /// Check if coordinates are available for a station
  static Future<bool> hasCoordinates(String stationCode) async {
    final coordinates = await _loadCoordinates();
    return coordinates.containsKey(stationCode);
  }
}
