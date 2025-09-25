class IndiaWRISState {
  final String stateCode;
  final String stateName;

  IndiaWRISState({required this.stateCode, required this.stateName});

  factory IndiaWRISState.fromJson(Map<String, dynamic> json) {
    return IndiaWRISState(
      stateCode: json['statecode']?.toString() ?? '',
      stateName: json['state']?.toString() ?? '',
    );
  }

  @override
  String toString() => stateName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndiaWRISState &&
          runtimeType == other.runtimeType &&
          stateCode == other.stateCode;

  @override
  int get hashCode => stateCode.hashCode;
}

class IndiaWRISDistrict {
  final String districtId;
  final String districtName;
  final String stateCode;

  IndiaWRISDistrict({
    required this.districtId,
    required this.districtName,
    required this.stateCode,
  });

  factory IndiaWRISDistrict.fromJson(Map<String, dynamic> json) {
    return IndiaWRISDistrict(
      districtId: json['district_id']?.toString() ?? '',
      districtName: json['districtname']?.toString() ?? '',
      stateCode: json['statecode']?.toString() ?? '',
    );
  }

  @override
  String toString() => districtName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndiaWRISDistrict &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId;

  @override
  int get hashCode => districtId.hashCode;
}

class IndiaWRISStation {
  final String stationCode;
  final String stationName;
  final String datasetCode;
  final String agencyId;
  final String districtId;
  final bool telemetric;
  // Note: The API doesn't provide coordinates for stations
  // We'll use default values or fetch from another source if needed

  IndiaWRISStation({
    required this.stationCode,
    required this.stationName,
    required this.datasetCode,
    required this.agencyId,
    required this.districtId,
    required this.telemetric,
  });

  factory IndiaWRISStation.fromJson(Map<String, dynamic> json) {
    return IndiaWRISStation(
      stationCode: json['stationcode']?.toString() ?? '',
      stationName: json['stationname']?.toString() ?? '',
      datasetCode: json['datasetcode']?.toString() ?? '',
      agencyId: json['agencyid']?.toString() ?? '',
      districtId: json['district_id']?.toString() ?? '',
      telemetric: json['telemetric'] == true || json['telemetric'] == 'true',
    );
  }

  // For compatibility with existing code, provide default coordinates
  double get latitude => 0.0;
  double get longitude => 0.0;

  @override
  String toString() => stationName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndiaWRISStation &&
          runtimeType == other.runtimeType &&
          stationCode == other.stationCode;

  @override
  int get hashCode => stationCode.hashCode;
}
