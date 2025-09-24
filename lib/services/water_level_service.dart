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

class TimeSeriesDataPoint {
  final DateTime dateTime;
  final String dataValue;
  final String unitCode;
  final String? dataTypeDescription;

  TimeSeriesDataPoint({
    required this.dateTime,
    required this.dataValue,
    required this.unitCode,
    this.dataTypeDescription,
  });

  factory TimeSeriesDataPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesDataPoint(
      dateTime:
          DateTime.tryParse(json['dataTime']?.toString() ?? '') ??
          DateTime.now(),
      dataValue: json['dataValue']?.toString() ?? 'N/A',
      unitCode: json['unitCode']?.toString() ?? '',
      dataTypeDescription: json['datatypeDescription']?.toString(),
    );
  }
}

class WaterLevelService {
  static const String _baseUrl =
      'https://indiawris.gov.in/stationMaster/getMasterStationsList';
  static const String _timeSeriesUrl =
      'https://indiawris.gov.in/CommonDataSetMasterAPI/getCommonDataSetByStationCode';

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

  static Future<List<TimeSeriesDataPoint>> fetchTimeSeriesData(
    String stationCode, {
    int days = 8,
  }) async {
    try {
      // Calculate dates
      final endTime = DateTime.now().subtract(const Duration(days: 1));
      final startTime = endTime.subtract(Duration(days: days));

      // Format dates as required by the API (YYYY-MM-DD)
      final String startTimeStr = _formatDate(startTime);
      final String endTimeStr = _formatDate(endTime);

      final requestBody = {
        'station_code': stationCode,
        'starttime': startTimeStr,
        'endtime': endTimeStr,
        'dataset': 'GWATERLVL',
      };

      print('Fetching time series data for station: $stationCode');
      print('Date range: $startTimeStr to $endTimeStr ($days days)');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_timeSeriesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Time series response status: ${response.statusCode}');
      print('Time series response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> dataList = [];

        // Handle different response formats
        if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('data') && jsonData['data'] != null) {
            final dataField = jsonData['data'];
            if (dataField is List) {
              dataList = dataField;
            } else if (dataField is Map) {
              // If data is a single object, wrap it in a list
              dataList = [dataField];
            }
          } else if (jsonData.containsKey('dataset') &&
              jsonData['dataset'] is List) {
            dataList = jsonData['dataset'];
          }
        } else if (jsonData is List) {
          dataList = jsonData;
        }

        // Convert to TimeSeriesDataPoint objects
        final List<TimeSeriesDataPoint> timeSeriesData = [];
        for (final item in dataList) {
          if (item is Map<String, dynamic>) {
            try {
              final dataPoint = TimeSeriesDataPoint.fromJson(item);
              timeSeriesData.add(dataPoint);
            } catch (e) {
              print('Error parsing data point: $e');
            }
          }
        }

        // Sort by date (newest first)
        timeSeriesData.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        print('Parsed ${timeSeriesData.length} time series data points');
        return timeSeriesData;
      } else {
        print(
          'Failed to fetch time series data: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error fetching time series data: $e');
      return [];
    }
  }

  // Convenience methods for different time periods
  static Future<List<TimeSeriesDataPoint>> fetchWeeklyData(String stationCode) {
    return fetchTimeSeriesData(stationCode, days: 8);
  }

  static Future<List<TimeSeriesDataPoint>> fetchMonthlyData(String stationCode) async {
    // Try with 30 days but use the same method as weekly data
    try {
      final data = await fetchTimeSeriesData(stationCode, days: 30);
      if (data.isNotEmpty) {
        return data;
      }
      
      // If 30 days returns no data, try 15 days
      print('30 days returned no data, trying 15 days...');
      return await fetchTimeSeriesData(stationCode, days: 15);
    } catch (e) {
      print('Error fetching monthly data: $e');
      // Fallback to 10 days if longer periods fail
      print('Falling back to 10 days...');
      return await fetchTimeSeriesData(stationCode, days: 10);
    }
  }

  static Future<List<TimeSeriesDataPoint>> fetchSixMonthsData(String stationCode) async {
    // For 6 months, let's try with 90 days first to see if API supports it
    // If this doesn't work, we can fall back to multiple smaller calls
    try {
      final data = await fetchTimeSeriesData(stationCode, days: 90);
      if (data.isNotEmpty) {
        return data;
      }
      
      // If 90 days returns no data, try 60 days
      print('90 days returned no data, trying 60 days...');
      return await fetchTimeSeriesData(stationCode, days: 60);
    } catch (e) {
      print('Error fetching 6-month data: $e');
      // Fallback to 30 days if longer periods fail
      print('Falling back to 30 days...');
      return await fetchTimeSeriesData(stationCode, days: 30);
    }
  }

  static String _formatDate(DateTime date) {
    // Format as YYYY-MM-DD as required by the API
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
