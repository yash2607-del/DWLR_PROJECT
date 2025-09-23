import 'dart:convert';
import 'package:http/http.dart' as http;

class WaterLevelData {
  final String stationCode;
  final String stationName;
  final Map<String, dynamic> details;

  WaterLevelData({
    required this.stationCode,
    required this.stationName,
    required this.details,
  });

  factory WaterLevelData.fromJson(Map<String, dynamic> json) {
    // Filter out null values
    final filteredDetails = <String, dynamic>{};
    json.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        filteredDetails[key] = value;
      }
    });

    return WaterLevelData(
      stationCode: filteredDetails['station_code']?.toString() ?? '',
      stationName: filteredDetails['station_name']?.toString() ?? '',
      details: filteredDetails,
    );
  }
}

class WaterLevelService {
  static const String _baseUrl =
      'https://indiawris.gov.in/stationMaster/getMasterStationsList';

  static Future<WaterLevelData?> fetchWaterLevelData(String stationCode) async {
    try {
      // Calculate dates
      final endTime = DateTime.now();
      final startTime = endTime.subtract(const Duration(days: 7));

      // Format dates as required by the API
      final String startTimeStr = _formatDate(startTime);
      final String endTimeStr = _formatDate(endTime);

      final requestBody = {
        'stationcode': stationCode,
        'datasetcode': 'GWATERLVL',
      };

      print('Fetching water level data for station: $stationCode');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Handle different response formats
        if (jsonData is Map<String, dynamic>) {
          return WaterLevelData.fromJson(jsonData);
        } else if (jsonData is List && jsonData.isNotEmpty) {
          return WaterLevelData.fromJson(jsonData.first);
        } else {
          print('Unexpected response format: $jsonData');
          return null;
        }
      } else {
        print(
          'Failed to fetch data: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching water level data: $e');
      return null;
    }
  }

  static String _formatDate(DateTime date) {
    // Format as YYYY-MM-DD or adjust based on API requirements
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
