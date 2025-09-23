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
    // Filter out null values and unwanted fields
    final filteredDetails = <String, dynamic>{};
    json.forEach((key, value) {
      // Skip unwanted fields
      if (_isUnwantedField(key)) {
        return;
      }

      // Only include non-null, non-empty values
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != 'null') {
        filteredDetails[key] = value;
      }
    });

    return WaterLevelData(
      stationCode:
          filteredDetails['station_code']?.toString() ??
          filteredDetails['stationcode']?.toString() ??
          '',
      stationName:
          filteredDetails['station_name']?.toString() ??
          filteredDetails['stationname']?.toString() ??
          '',
      details: filteredDetails,
    );
  }

  static bool _isUnwantedField(String key) {
    final unwantedFields = {
      'statuscode',
      'status_code',
      'message',
      'status',
      'error',
      'success',
    };
    return unwantedFields.contains(key.toLowerCase());
  }
}

class WaterLevelService {
  static const String _baseUrl =
      'https://indiawris.gov.in/stationMaster/getMasterStationsList';

  static Future<WaterLevelData?> fetchWaterLevelData(String stationCode) async {
    try {
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
          // Check if there's a nested 'data' field
          if (jsonData.containsKey('data') && jsonData['data'] != null) {
            final dataField = jsonData['data'];
            if (dataField is Map<String, dynamic>) {
              return WaterLevelData.fromJson(dataField);
            } else if (dataField is List && dataField.isNotEmpty) {
              return WaterLevelData.fromJson(dataField.first);
            }
          } else {
            // If no 'data' field, use the whole response but filter out statuscode and message
            final filteredResponse = Map<String, dynamic>.from(jsonData);
            filteredResponse.remove('statuscode');
            filteredResponse.remove('message');
            filteredResponse.remove('status');
            filteredResponse.remove('status_code');

            if (filteredResponse.isNotEmpty) {
              return WaterLevelData.fromJson(filteredResponse);
            }
          }
        } else if (jsonData is List && jsonData.isNotEmpty) {
          return WaterLevelData.fromJson(jsonData.first);
        }

        print('No valid data found in response: $jsonData');
        return null;
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
}
