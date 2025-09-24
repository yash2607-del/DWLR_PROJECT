class LocationData {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> details;

  LocationData({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
  });

  factory LocationData.fromJson(Map<String, dynamic> json, String type) {
    return LocationData(
      id: json['id']?.toString() ?? json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? json['location']?.toString() ?? '',
      type: type,
      details: json,
    );
  }
}

class WellData {
  final String id;
  final String name;
  final String district;
  final String state;
  final Map<String, dynamic> details;

  WellData({
    required this.id,
    required this.name,
    required this.district,
    required this.state,
    required this.details,
  });

  factory WellData.fromJson(Map<String, dynamic> json) {
    return WellData(
      id: json['station_code']?.toString() ?? json['id']?.toString() ?? '',
      name: json['station_name']?.toString() ?? json['name']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      details: json,
    );
  }
}

class LocationService {
  // Mock data for demonstration - in real app, this would come from your backend
  static const List<Map<String, dynamic>> _mockStates = [
    {'id': 'DL', 'name': 'Delhi'},
    {'id': 'UP', 'name': 'Uttar Pradesh'},
    {'id': 'HR', 'name': 'Haryana'},
    {'id': 'PB', 'name': 'Punjab'},
    {'id': 'RJ', 'name': 'Rajasthan'},
    {'id': 'MP', 'name': 'Madhya Pradesh'},
    {'id': 'GJ', 'name': 'Gujarat'},
    {'id': 'MH', 'name': 'Maharashtra'},
  ];

  static const Map<String, List<Map<String, dynamic>>> _mockDistricts = {
    'DL': [
      {'id': 'DL_ND', 'name': 'New Delhi'},
      {'id': 'DL_SD', 'name': 'South Delhi'},
      {'id': 'DL_ED', 'name': 'East Delhi'},
      {'id': 'DL_WD', 'name': 'West Delhi'},
      {'id': 'DL_NED', 'name': 'North East Delhi'},
    ],
    'UP': [
      {'id': 'UP_LKN', 'name': 'Lucknow'},
      {'id': 'UP_KNP', 'name': 'Kanpur'},
      {'id': 'UP_AGR', 'name': 'Agra'},
      {'id': 'UP_VRN', 'name': 'Varanasi'},
    ],
    'HR': [
      {'id': 'HR_GGN', 'name': 'Gurgaon'},
      {'id': 'HR_FBD', 'name': 'Faridabad'},
      {'id': 'HR_PNP', 'name': 'Panipat'},
      {'id': 'HR_AMB', 'name': 'Ambala'},
    ],
    'PB': [
      {'id': 'PB_CHD', 'name': 'Chandigarh'},
      {'id': 'PB_LDH', 'name': 'Ludhiana'},
      {'id': 'PB_AMR', 'name': 'Amritsar'},
      {'id': 'PB_JLD', 'name': 'Jalandhar'},
    ],
    'RJ': [
      {'id': 'RJ_JPR', 'name': 'Jaipur'},
      {'id': 'RJ_JDH', 'name': 'Jodhpur'},
      {'id': 'RJ_UDR', 'name': 'Udaipur'},
      {'id': 'RJ_KTA', 'name': 'Kota'},
    ],
  };

  static const Map<String, List<Map<String, dynamic>>> _mockWells = {
    'DL_ND': [
      {
        'station_code': 'GW000001',
        'station_name': 'Vasant Vihar Ground Water Station',
        'location': 'Vasant Vihar, New Delhi',
        'district': 'New Delhi',
        'state': 'Delhi',
        'depth': '45.2m',
        'type': 'Monitoring Well',
        'lat': 28.5672,
        'lng': 77.1574,
      },
      {
        'station_code': 'GW000002',
        'station_name': 'Connaught Place Monitoring Well',
        'location': 'Connaught Place, New Delhi',
        'district': 'New Delhi',
        'state': 'Delhi',
        'depth': '38.7m',
        'type': 'Monitoring Well',
        'lat': 28.6315,
        'lng': 77.2167,
      },
      {
        'station_code': 'GW000003',
        'station_name': 'Lodhi Garden Deep Well',
        'location': 'Lodhi Garden, New Delhi',
        'district': 'New Delhi',
        'state': 'Delhi',
        'depth': '52.1m',
        'type': 'Deep Monitoring Well',
        'lat': 28.5910,
        'lng': 77.2218,
      },
    ],
    'DL_SD': [
      {
        'station_code': 'GW000004',
        'station_name': 'Greater Kailash Ground Water Station',
        'location': 'Greater Kailash, South Delhi',
        'district': 'South Delhi',
        'state': 'Delhi',
        'depth': '41.3m',
        'type': 'Monitoring Well',
        'lat': 28.5494,
        'lng': 77.2426,
      },
      {
        'station_code': 'GW000005',
        'station_name': 'Defense Colony Monitoring Point',
        'location': 'Defense Colony, South Delhi',
        'district': 'South Delhi',
        'state': 'Delhi',
        'depth': '39.8m',
        'type': 'Monitoring Well',
        'lat': 28.5729,
        'lng': 77.2295,
      },
    ],
    'UP_LKN': [
      {
        'station_code': 'GW000006',
        'station_name': 'Hazratganj Water Monitoring Station',
        'location': 'Hazratganj, Lucknow',
        'district': 'Lucknow',
        'state': 'Uttar Pradesh',
        'depth': '48.5m',
        'type': 'Urban Monitoring Well',
        'lat': 26.8467,
        'lng': 80.9462,
      },
    ],
    'HR_GGN': [
      {
        'station_code': 'GW000007',
        'station_name': 'Cyber City Ground Water Point',
        'location': 'Cyber City, Gurgaon',
        'district': 'Gurgaon',
        'state': 'Haryana',
        'depth': '55.2m',
        'type': 'Industrial Monitoring Well',
        'lat': 28.4595,
        'lng': 77.0266,
      },
    ],
  };

  static Future<List<LocationData>> fetchStates() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return _mockStates
          .map((state) => LocationData.fromJson(state, 'state'))
          .toList();
    } catch (e) {
      print('Error fetching states: $e');
      return [];
    }
  }

  static Future<List<LocationData>> fetchDistricts(String stateId) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      final districts = _mockDistricts[stateId] ?? [];
      return districts
          .map((district) => LocationData.fromJson(district, 'district'))
          .toList();
    } catch (e) {
      print('Error fetching districts: $e');
      return [];
    }
  }

  static Future<List<WellData>> fetchWells(String districtId) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 400));
      
      final wells = _mockWells[districtId] ?? [];
      return wells.map((well) => WellData.fromJson(well)).toList();
    } catch (e) {
      print('Error fetching wells: $e');
      return [];
    }
  }

  static Future<List<WellData>> searchWells(String query) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      final allWells = <WellData>[];
      for (final wells in _mockWells.values) {
        allWells.addAll(wells.map((well) => WellData.fromJson(well)));
      }
      
      // Filter wells based on query
      final filteredWells = allWells.where((well) =>
          well.name.toLowerCase().contains(query.toLowerCase()) ||
          well.district.toLowerCase().contains(query.toLowerCase()) ||
          well.state.toLowerCase().contains(query.toLowerCase()) ||
          well.id.toLowerCase().contains(query.toLowerCase())).toList();
      
      return filteredWells;
    } catch (e) {
      print('Error searching wells: $e');
      return [];
    }
  }
}