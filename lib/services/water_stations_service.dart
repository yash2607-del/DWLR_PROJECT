import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class WaterStation {
  final String stationCode;
  final String stationName;
  final double lat;
  final double long;

  WaterStation({
    required this.stationCode,
    required this.stationName,
    required this.lat,
    required this.long,
  });

  factory WaterStation.fromJson(Map<String, dynamic> json) {
    return WaterStation(
      stationCode: json['station_code'] ?? '',
      stationName: json['station_name'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      long: (json['long'] ?? 0.0).toDouble(),
    );
  }

  LatLng get position => LatLng(lat, long);
}

class WaterStationsService {
  static Future<List<WaterStation>> loadWaterStations() async {
    try {
      // Load the JSON file from assets
      final String response = await rootBundle.loadString(
        'lib/mapData/water_stations.json',
      );
      final Map<String, dynamic> data = json.decode(response);

      final List<dynamic> stationsJson = data['stations'] ?? [];

      List<WaterStation> stations = stationsJson
          .map((stationJson) => WaterStation.fromJson(stationJson))
          .where(
            (station) =>
                station.lat != 0.0 &&
                station.long != 0.0 &&
                station.stationCode.isNotEmpty &&
                station.stationName.isNotEmpty,
          )
          .toList();

      print('Loaded ${stations.length} water stations');
      return stations;
    } catch (e) {
      print('Error loading water stations: $e');
      return [];
    }
  }

  // Helper method to filter stations by region for performance
  static List<WaterStation> filterStationsByBounds(
    List<WaterStation> stations,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    return stations
        .where(
          (station) =>
              station.lat >= minLat &&
              station.lat <= maxLat &&
              station.long >= minLng &&
              station.long <= maxLng,
        )
        .toList();
  }
}
