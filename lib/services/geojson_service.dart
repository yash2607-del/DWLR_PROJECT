import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class GeoJsonService {
  static Future<List<List<LatLng>>> loadIndiaBoundary() async {
    try {
      // Load the GeoJSON file from assets
      final String response = await rootBundle.loadString(
        'lib/mapData/indiaborder.geojson',
      );
      final Map<String, dynamic> data = json.decode(response);

      List<List<LatLng>> polygons = [];

      // Parse the FeatureCollection
      if (data['type'] == 'FeatureCollection' && data['features'] != null) {
        for (var feature in data['features']) {
          if (feature['geometry'] != null &&
              feature['geometry']['type'] == 'MultiPolygon') {
            // Handle MultiPolygon geometry
            var coordinates = feature['geometry']['coordinates'] as List;

            for (var polygon in coordinates) {
              for (var ring in polygon) {
                List<LatLng> points = [];
                for (var coordinate in ring) {
                  if (coordinate is List && coordinate.length >= 2) {
                    // GeoJSON format is [longitude, latitude]
                    double longitude = coordinate[0].toDouble();
                    double latitude = coordinate[1].toDouble();
                    points.add(LatLng(latitude, longitude));
                  }
                }
                if (points.isNotEmpty) {
                  polygons.add(points);
                }
              }
            }
          } else if (feature['geometry'] != null &&
              feature['geometry']['type'] == 'Polygon') {
            // Handle Polygon geometry
            var coordinates = feature['geometry']['coordinates'] as List;

            for (var ring in coordinates) {
              List<LatLng> points = [];
              for (var coordinate in ring) {
                if (coordinate is List && coordinate.length >= 2) {
                  // GeoJSON format is [longitude, latitude]
                  double longitude = coordinate[0].toDouble();
                  double latitude = coordinate[1].toDouble();
                  points.add(LatLng(latitude, longitude));
                }
              }
              if (points.isNotEmpty) {
                polygons.add(points);
              }
            }
          }
        }
      }

      return polygons;
    } catch (e) {
      print('Error loading GeoJSON: $e');
      // Return fallback simplified boundary if loading fails
      return [
        [
          const LatLng(35.5, 68.0), // Northwest (Kashmir)
          const LatLng(37.0, 78.0), // Northeast Kashmir
          const LatLng(36.0, 87.0), // Northeast (Arunachal)
          const LatLng(28.0, 97.0), // Far Northeast
          const LatLng(21.0, 92.0), // East (Mizoram)
          const LatLng(8.0, 77.0), // South (Kerala)
          const LatLng(8.5, 68.0), // Southwest coast
          const LatLng(23.0, 68.0), // West (Gujarat)
          const LatLng(24.0, 69.0), // Rajasthan border
          const LatLng(30.0, 75.0), // Punjab
          const LatLng(35.5, 68.0), // Back to start
        ],
      ];
    }
  }

  // Helper method to get the main boundary (usually the largest polygon)
  static List<LatLng> getMainBoundary(List<List<LatLng>> allPolygons) {
    if (allPolygons.isEmpty) return [];

    // Find the polygon with the most points (likely the main boundary)
    List<LatLng> mainBoundary = allPolygons[0];
    for (var polygon in allPolygons) {
      if (polygon.length > mainBoundary.length) {
        mainBoundary = polygon;
      }
    }

    return mainBoundary;
  }

  // Helper method to get all polygons for complete India boundary including islands
  static List<List<LatLng>> getAllBoundaries(List<List<LatLng>> allPolygons) {
    return allPolygons;
  }
}
