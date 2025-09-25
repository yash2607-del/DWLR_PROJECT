import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/indiawris_models.dart';

class IndiaWRISService {
  static const String baseUrl = 'https://indiawris.gov.in';
  static const String datasetCode = 'GWATERLVL';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  /// Fetch list of states from IndiaWRIS API
  static Future<List<IndiaWRISState>> fetchStates() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/masterState/StateList'),
        headers: headers,
        body: jsonEncode({'datasetcode': datasetCode}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if response has the expected structure
        if (responseData['statusCode'] != 200) {
          throw Exception(
            'API returned error: ${responseData['message'] ?? 'Unknown error'}',
          );
        }

        // Extract states from the data array
        List<dynamic> statesJson = responseData['data'] ?? [];

        List<IndiaWRISState> states = statesJson
            .map((stateJson) => IndiaWRISState.fromJson(stateJson))
            .where(
              (state) =>
                  state.stateCode.isNotEmpty && state.stateName.isNotEmpty,
            )
            .toList();

        // Sort states alphabetically
        states.sort((a, b) => a.stateName.compareTo(b.stateName));

        print('Fetched ${states.length} states from IndiaWRIS API');
        return states;
      } else {
        throw Exception(
          'Failed to fetch states: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching states: $e');
      throw Exception('Failed to fetch states: $e');
    }
  }

  /// Fetch list of districts for a specific state
  static Future<List<IndiaWRISDistrict>> fetchDistricts(
    String stateCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/masterDistrict/getDistrictbyState'),
        headers: headers,
        body: jsonEncode({'statecode': stateCode, 'datasetcode': datasetCode}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if response has the expected structure
        if (responseData['statusCode'] != 200) {
          throw Exception(
            'API returned error: ${responseData['message'] ?? 'Unknown error'}',
          );
        }

        // Extract districts from the data array
        List<dynamic> districtsJson = responseData['data'] ?? [];

        List<IndiaWRISDistrict> districts = districtsJson
            .map((districtJson) => IndiaWRISDistrict.fromJson(districtJson))
            .where(
              (district) =>
                  district.districtId.isNotEmpty &&
                  district.districtName.isNotEmpty,
            )
            .toList();

        // Sort districts alphabetically
        districts.sort((a, b) => a.districtName.compareTo(b.districtName));

        print('Fetched ${districts.length} districts for state $stateCode');
        return districts;
      } else {
        throw Exception(
          'Failed to fetch districts: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching districts: $e');
      throw Exception('Failed to fetch districts for state $stateCode: $e');
    }
  }

  /// Fetch list of stations for a specific district
  static Future<List<IndiaWRISStation>> fetchStations(
    String districtId,
    String agencyId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/masterStationDS/stationDSList'),
        headers: headers,
        body: jsonEncode({
          'district_id': districtId,
          'agencyid': agencyId,
          'datasetcode': datasetCode,
          'telemetric': 'true',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if response has the expected structure
        if (responseData['statusCode'] != 200) {
          throw Exception(
            'API returned error: ${responseData['message'] ?? 'Unknown error'}',
          );
        }

        // Extract stations from the data array
        List<dynamic> stationsJson = responseData['data'] ?? [];

        List<IndiaWRISStation> stations = stationsJson
            .map((stationJson) => IndiaWRISStation.fromJson(stationJson))
            .where(
              (station) =>
                  station.stationCode.isNotEmpty &&
                  station.stationName.isNotEmpty,
            )
            .toList();

        // Sort stations alphabetically
        stations.sort((a, b) => a.stationName.compareTo(b.stationName));

        print('Fetched ${stations.length} stations for district $districtId');
        return stations;
      } else {
        throw Exception(
          'Failed to fetch stations: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching stations: $e');
      throw Exception('Failed to fetch stations for district $districtId: $e');
    }
  }

  /// Get all available agency IDs for a district (if needed)
  /// For now, we'll use a default agency ID of "113" as shown in the example
  static String getDefaultAgencyId() {
    return "113";
  }
}
