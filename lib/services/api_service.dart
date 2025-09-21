import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ground_water.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<String>> fetchDatasets() async {
    final response = await http.get(Uri.parse('$baseUrl/datasets'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to load datasets');
    }
  }

  static Future<List<GroundWaterRecord>> fetchDatasetRecords(
      String datasetName, {
      int limit = 100,
      int offset = 0,
    }) async {
    final response =
        await http.get(Uri.parse('$baseUrl/data/$datasetName?limit=$limit&offset=$offset'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => GroundWaterRecord.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load dataset records');
    }
  }
}
